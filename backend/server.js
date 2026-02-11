import express from "express";
import cors from "cors";
import { execFile, spawn } from "child_process";
import { existsSync, writeFileSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";

// Pinterest (and others) block requests without browser-like headers
const BROWSER_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

// Optional: Instagram cookies file path (set at startup from INSTAGRAM_COOKIES_BASE64 or INSTAGRAM_COOKIES_FILE)
let INSTAGRAM_COOKIES_PATH = null;
function initInstagramCookies() {
  const filePath = process.env.INSTAGRAM_COOKIES_FILE;
  if (filePath && existsSync(filePath)) {
    INSTAGRAM_COOKIES_PATH = filePath;
    console.log("Instagram: using cookies file from INSTAGRAM_COOKIES_FILE");
    return;
  }
  const b64 = process.env.INSTAGRAM_COOKIES_BASE64;
  if (b64) {
    try {
      const path = join(tmpdir(), "instagram_cookies.txt");
      const content = Buffer.from(b64, "base64").toString("utf8");
      writeFileSync(path, content, "utf8");
      INSTAGRAM_COOKIES_PATH = path;
      console.log("Instagram: using cookies from INSTAGRAM_COOKIES_BASE64");
    } catch (e) {
      console.error("Instagram: failed to write cookies file:", e.message);
    }
  }
}
initInstagramCookies();

function isPinterestUrl(url) {
  return url && (url.includes("pinterest.com") || url.includes("pin.it"));
}

function isInstagramUrl(url) {
  return url && (url.includes("instagram.com") || url.includes("instagr.am"));
}

/** Returns extra args for yt-dlp (headers + optional cookies for Instagram/Pinterest). */
function getYtDlpExtraArgs(url) {
  const args = ["--add-header", `User-Agent:${BROWSER_UA}`];
  if (isPinterestUrl(url)) {
    args.push(
      "--add-header", "Referer: https://www.pinterest.com/",
      "--add-header", "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
      "--add-header", "Accept-Language: en-US,en;q=0.9",
      "--add-header", "Sec-Fetch-Dest: document",
      "--add-header", "Sec-Fetch-Mode: navigate",
      "--add-header", "Sec-Fetch-Site: none",
      "--add-header", "Sec-Fetch-User: ?1",
      "--add-header", "Upgrade-Insecure-Requests: 1"
    );
    const cookiesBrowser = process.env.PINTEREST_COOKIES_BROWSER;
    if (cookiesBrowser) args.push("--cookies-from-browser", cookiesBrowser);
  }
  if (isInstagramUrl(url) && INSTAGRAM_COOKIES_PATH) {
    args.push("--cookies", INSTAGRAM_COOKIES_PATH);
  }
  return args;
}

// Legacy name for call sites that still use ytDlpExtraHeaders
function ytDlpExtraHeaders(url) {
  return getYtDlpExtraArgs(url);
}

const PINTEREST_ERROR_MSG = "Pinterest is blocking automated downloads. Try Instagram or Facebook links, or run: brew upgrade yt-dlp";
const INSTAGRAM_BLOCK_MSG = "Instagram is limiting downloads right now. Try again in a few hours or use a Facebook or Pinterest link.";

/** Resolve pin.it and other short URLs. */
async function resolveShortUrl(url) {
  if (!url || !url.startsWith("http")) return url;
  try {
    const res = await fetch(url, {
      method: "GET",
      redirect: "follow",
      headers: { "User-Agent": BROWSER_UA },
      signal: AbortSignal.timeout(10000),
    });
    return res.url || url;
  } catch (_) {
    return url;
  }
}

const app = express();
app.use(cors());
app.use(express.json());

// Prefer env; then common install paths so "yt-dlp" works when PATH is limited
function getYtDlpPath() {
  if (process.env.YT_DLP_PATH) return process.env.YT_DLP_PATH;
  const candidates = ["/opt/homebrew/bin/yt-dlp", "/usr/local/bin/yt-dlp", "yt-dlp"];
  for (const p of candidates) {
    if (p === "yt-dlp") return p;
    if (existsSync(p)) return p;
  }
  return "yt-dlp";
}

const YT_DLP_PATH = getYtDlpPath();
const DOWNLOAD_TIMEOUT_MS = 5 * 60 * 1000; // 5 min

// Build base URL from request so device (BACKEND_URL=http://IP:3000) gets correct download link
function getDownloadBase(req) {
  const envBase = process.env.BASE_URL;
  if (envBase) return envBase.replace(/\/$/, "");
  const protocol = req.protocol || "http";
  const host = req.get("host") || "localhost:3000";
  return `${protocol}://${host}`;
}

app.get("/download", (req, res) => {
  const q = req.query.q;
  if (!q || typeof q !== "string") {
    return res.status(400).json({ error: "Missing q (base64 URL)" });
  }
  let decodedUrl;
  try {
    decodedUrl = Buffer.from(decodeURIComponent(q), "base64").toString("utf8");
  } catch (_) {
    return res.status(400).json({ error: "Invalid q" });
  }
  if (!decodedUrl || !decodedUrl.startsWith("http")) {
    return res.status(400).json({ error: "Invalid URL" });
  }

  console.log("Download requested for:", decodedUrl.slice(0, 60) + "...");

  // Don't set headers yet — we validate first 8 bytes (MP4 ftyp) before committing to video response

  // "best" = single best format. Browser UA + Referer help Pinterest not return 403/HTML.
  const extra = ytDlpExtraHeaders(decodedUrl);
  const child = spawn(
    YT_DLP_PATH,
    ["-f", "best", "--no-playlist", ...extra, "-o", "-", decodedUrl],
    { stdio: ["ignore", "pipe", "pipe"] }
  );

  const timeout = setTimeout(() => {
    if (res.headersSent) return;
    try { child.kill("SIGKILL"); } catch (_) {}
    res.status(504).json({ error: "Download timed out" });
  }, DOWNLOAD_TIMEOUT_MS);

  let validated = false;
  let head = null;

  function isMp4FirstBytes(buf) {
    if (!buf || buf.length < 8) return false;
    return buf[4] === 0x66 && buf[5] === 0x74 && buf[6] === 0x79 && buf[7] === 0x70; // ftyp
  }

  child.stdout.on("data", (chunk) => {
    if (validated) {
      res.write(chunk);
      return;
    }
    head = head ? Buffer.concat([head, chunk]) : (Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    if (head.length >= 8) {
      validated = true;
        if (!isMp4FirstBytes(head)) {
        console.error("Download stream is not MP4 (Pinterest/HTML?). First bytes:", head.slice(0, 64));
        try { child.kill("SIGKILL"); } catch (_) {}
        const errMsg = isPinterestUrl(decodedUrl) ? PINTEREST_ERROR_MSG : "Video unavailable. Try again or use a different link.";
        if (!res.headersSent) res.status(500).json({ error: errMsg });
        return;
      }
      res.setHeader("Content-Type", "video/mp4");
      res.setHeader("Content-Disposition", 'attachment; filename="video.mp4"');
      res.write(head);
      head = null;
    }
  });
  child.stdout.on("end", () => {
    if (validated) {
      if (head && head.length > 0) res.write(head);
      res.end();
    } else if (!res.headersSent) {
      res.status(500).json({ error: "No video data received" });
    }
  });
  child.stdout.on("error", (err) => {
    if (!res.headersSent) res.status(500).json({ error: err.message });
  });

  child.stderr.on("data", (d) => console.error("yt-dlp download stderr:", d?.slice(0, 400)));
  child.on("error", (err) => {
    clearTimeout(timeout);
    if (!res.headersSent) res.status(500).json({ error: err.message });
    else res.end();
  });
  child.on("close", (code, signal) => {
    clearTimeout(timeout);
    if (code !== 0 && !res.headersSent) {
      const errMsg = isPinterestUrl(decodedUrl) ? PINTEREST_ERROR_MSG : "Download failed (yt-dlp exited " + code + ")";
      res.status(500).json({ error: errMsg });
    }
  });
  res.on("close", () => {
    clearTimeout(timeout);
    try { child.kill("SIGKILL"); } catch (_) {}
  });
});

app.post("/analyze", async (req, res) => {
  const { url } = req.body;

  if (!url || typeof url !== "string") {
    return res.status(400).json({
      error: "URL is required"
    });
  }

  const trimmed = url.trim();
  if (!trimmed) {
    return res.status(400).json({
      error: "Please paste a valid video URL (Instagram, Facebook, Pinterest, or LinkedIn)."
    });
  }

  // Resolve pin.it and other short URLs so yt-dlp gets the full Pinterest URL
  const urlToUse = trimmed.includes("pin.it") ? await resolveShortUrl(trimmed) : trimmed;
  if (urlToUse !== trimmed) {
    console.log("Resolved short URL to:", urlToUse.slice(0, 80) + "...");
  }

  const extra = ytDlpExtraHeaders(urlToUse);

  // Slight delay to reduce Instagram rate limiting (fast repeated requests from same IP get blocked)
  await new Promise((resolve) => setTimeout(resolve, 1200));

  execFile(
    YT_DLP_PATH,
    ["-J", "--no-playlist", ...extra, urlToUse],
    { maxBuffer: 1024 * 1024 * 20, timeout: 60000 },
    (error, stdout, stderr) => {
      if (error) {
        console.error("yt-dlp error:", error.message, stderr?.slice(0, 400));
        return res.status(422).json({
          error: "Instagram blocked this request. Try again later."
        });
      }

      try {
        const info = JSON.parse(stdout);
        const rawFormats = info.formats || [];

        // Prefer single progressive MP4 (video+audio) — best for AVPlayer
        let format = rawFormats.find(f =>
          f.ext === "mp4" &&
          f.vcodec !== "none" &&
          f.acodec !== "none" &&
          f.url
        );
        const hasDirectMp4 = !!format;
        // Fallback: first format with a URL (some sites only have DASH/separate streams)
        if (!format) {
          format = rawFormats.find(f => f.url && (f.vcodec !== "none" || f.acodec !== "none"));
        }
        if (!format) {
          const msg = isPinterestUrl(urlToUse) ? PINTEREST_ERROR_MSG : "No playable format found";
          return res.status(422).json({ error: msg });
        }

        // When we have a direct MP4 URL, return it so the app downloads directly (works for Instagram + Pinterest).
        // Use proxy only when we don't have a single-file format (e.g. DASH-only for Facebook).
        const base = getDownloadBase(req);
        const proxyQ = encodeURIComponent(Buffer.from(urlToUse, "utf8").toString("base64"));
        const proxyUrl = `${base}/download?q=${proxyQ}`;
        const directUrl = hasDirectMp4 && format.url ? format.url : proxyUrl;

        const formats = [{
          quality: "HD",
          url: directUrl,
          size: format.filesize || 0
        }];

        let hostname = "";
        try {
          hostname = new URL(urlToUse).hostname || "";
        } catch (_) {}

        res.json({
          title: info.title || "Video",
          thumbnail: info.thumbnail || "",
          sourceDomain: hostname,
          formats
        });

      } catch (parseError) {
        console.error("Parse error:", parseError);
        return res.status(500).json({
          error: "Failed to process video data"
        });
      }
    }
  );
});

app.get("/health", (_, res) => {
  res.json({ status: "ok" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log("Backend running on port", PORT);
  console.log("yt-dlp path:", YT_DLP_PATH);
  if (process.env.PINTEREST_COOKIES_BROWSER) {
    console.log("Pinterest: using cookies from browser:", process.env.PINTEREST_COOKIES_BROWSER);
  }
});
