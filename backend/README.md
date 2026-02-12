# Video Saver Backend

Node.js server that analyzes video URLs (Instagram, Facebook, Pinterest, LinkedIn) and streams downloads via **yt-dlp**. The iOS app talks to this backend to fetch metadata and download videos.

---

## What you need

| Requirement | Notes |
|-------------|--------|
| **Node.js** | v18+ (for `fetch`, ES modules). Check: `node -v` |
| **yt-dlp** | Required for video extraction. Install: `brew install yt-dlp` |
| **npm** | Comes with Node. Install deps: `npm install` |

---

## Run locally (Mac)

1. **Install yt-dlp** (if not already):
   ```bash
   brew install yt-dlp
   ```
   Keep it updated: `brew upgrade yt-dlp`

2. **Install dependencies** (first time only):
   ```bash
   cd backend
   npm install
   ```

3. **Start the server**:
   ```bash
   node server.js
   ```
   You should see:
   ```
   Backend running on port 3000
   yt-dlp path: /opt/homebrew/bin/yt-dlp
   ```

4. **Test**  
   - In browser: [http://localhost:3000/health](http://localhost:3000/health) → `{"status":"ok"}`  
   - In the app (Simulator): set **BACKEND_URL** = `http://localhost:3000` in Xcode scheme so the app uses this server.

---

## Environment variables (optional)

| Variable | Default | Use |
|----------|---------|-----|
| **PORT** | `3000` | Port the server listens on. |
| **YT_DLP_PATH** | auto (Homebrew paths) | Full path to `yt-dlp` if it’s not on PATH. |
| **BASE_URL** | from request | Override base URL for download links (e.g. `http://YOUR_IP:3000` on device). Usually not needed; the server uses the request host. |
| **PINTEREST_COOKIES_BROWSER** | — | If set (e.g. `safari` or `chrome`), yt-dlp uses that browser’s cookies for Pinterest. Only use on your own machine. |
| **INSTAGRAM_COOKIES_BASE64** | — | Base64-encoded Netscape cookies file. When set, Instagram requests use these cookies so downloads don’t fail with “login required”. See below. |
| **INSTAGRAM_COOKIES_FILE** | — | Path to a cookies file (Netscape format) for Instagram. Use this instead of INSTAGRAM_COOKIES_BASE64 if you have a file on disk. |
| **INSTAGRAM_COOKIES_BROWSER** | — | When set (e.g. `chrome`), yt-dlp uses that browser’s cookies for Instagram. Use for local dev when you’re logged into Instagram in that browser. Overrides file/base64 when set. |
| **FACEBOOK_COOKIES_FILE** | — | Path to a Netscape-format cookies file for Facebook. Can help when Facebook returns “login” or “Cannot parse data”. |
| **FACEBOOK_COOKIES_BROWSER** | — | Browser name (e.g. `chrome`) so yt-dlp uses that browser’s cookies for Facebook. Use only on your own machine. |
| **RATE_LIMIT_PER_MINUTE** | `18` | Max analyze requests per IP per minute. Helps protect the server and avoid platform rate blocks when you have many users. |

**Instagram cookies (to avoid “login required”):**  
If Instagram links fail with “login required” or “rate-limit”, you can pass cookies from a logged-in session:

1. Log into Instagram in a browser (Chrome/Safari).
2. Export cookies in **Netscape** format (browser extension: “Get cookies.txt” or “cookies.txt”).
3. Base64-encode the file:  
   `base64 -i cookies.txt | tr -d '\n' > cookies_b64.txt`  
   (or use an online base64 encoder and paste the result.)
4. Set **INSTAGRAM_COOKIES_BASE64** to that string (e.g. in Railway: Variables → add INSTAGRAM_COOKIES_BASE64, paste the long string).  
   Cookies expire; refresh every few days or when Instagram starts failing again.

Examples:

```bash
# Custom port
PORT=4000 node server.js

# Force yt-dlp path
YT_DLP_PATH=/usr/local/bin/yt-dlp node server.js

# Use Safari cookies for Pinterest (Mac only)
PINTEREST_COOKIES_BROWSER=safari node server.js
```

---

## Use the app on a real device

The app must reach your Mac’s IP (Simulator can use `localhost`; a device cannot).

1. **Find your Mac’s IP**  
   System Settings → Network → Wi‑Fi → Details → IP (e.g. `192.168.1.5`).

2. **Start the backend** on your Mac:
   ```bash
   cd backend
   node server.js
   ```

3. **In Xcode** (Edit Scheme → Run → Arguments → Environment Variables) set:
   - **Name:** `BACKEND_URL`  
   - **Value:** `http://YOUR_MAC_IP:3000` (e.g. `http://192.168.1.5:3000`)

4. **Run the app on the device**; it will use that URL for analyze and download.

5. **Firewall**  
   If the device can’t connect, allow incoming connections for Node (or disable firewall temporarily for testing).

---

## Deploy to production (e.g. Railway)

For a public backend (so the app works away from home):

- See **[RAILWAY.md](./RAILWAY.md)** for step-by-step deploy to Railway.
- Your `Dockerfile` already installs **yt-dlp** in the image.
- After deploy, you get a URL like `https://your-app.up.railway.app` — use it in the app (see **App Store** below).

**Note:** Pinterest may still block on some hosts; Instagram and Facebook usually work.

---

## App Store launch (backend steps)

For App Store, the app must talk to a **hosted** backend (users don’t run the server).

1. **Deploy the backend**  
   Follow [RAILWAY.md](./RAILWAY.md). Deploy from the `backend` folder, use the Dockerfile, generate a public domain.

2. **Get your backend URL**  
   Example: `https://video-saver-backend.up.railway.app` (no trailing slash).

3. **Set the URL in the iOS app**  
   In Xcode, open **VideoSaver/Config/AppConfig.swift** and set:
   ```swift
   static let productionBackendURL = "https://YOUR-ACTUAL-RAILWAY-URL"
   ```
   Replace `YOUR-ACTUAL-RAILWAY-URL` with your Railway URL (e.g. `video-saver-backend.up.railway.app`).  
   App Store builds do **not** use the BACKEND_URL env var; they use this constant.

4. **Verify**  
   - Open `https://YOUR-URL/health` in a browser → `{"status":"ok"}`.  
   - Run the app (without setting BACKEND_URL in the scheme) and try Fetch with an Instagram URL; it should hit your Railway backend.

5. **Then**  
   Archive and submit to App Store Connect. Backend stays running on Railway (or your host); monitor usage and costs.

---

## Troubleshooting (yt-dlp errors)

**“Cannot parse data” / “Unsupported URL” / “login required”** — These come from yt-dlp when a site blocks or changes. The app still shows a generic “This link could not be loaded.”

| Issue | What to do |
|-------|------------|
| **Instagram:** “login required” or “rate-limit” | Refresh cookies: export new Netscape cookies from a logged-in browser, base64 them, and set **INSTAGRAM_COOKIES_BASE64** again (or use **INSTAGRAM_COOKIES_BROWSER** when running locally). Cookies expire every few days. |
| **Facebook:** “Cannot parse data” or redirect to login | Facebook’s extractor breaks often. Try: (1) Update yt-dlp: `yt-dlp -U` or `brew upgrade yt-dlp`. (2) Optional: set **FACEBOOK_COOKIES_FILE** (path to Netscape cookies) or **FACEBOOK_COOKIES_BROWSER** (e.g. `chrome`) when running on your own machine. |
| **Any site:** “Confirm you are on the latest version” | Update yt-dlp: `yt-dlp -U` (or `brew upgrade yt-dlp` on Mac). On Railway, redeploy so the Docker image pulls the latest yt-dlp. |

**Keeping the app running long-term**

- **Instagram** often blocks server/datacenter IPs (e.g. Railway). Even with valid cookies, requests from hosted backends can fail. For best Instagram support: (1) Refresh **INSTAGRAM_COOKIES_BASE64** every few days from a logged-in browser (Netscape format, then base64). (2) Or run the backend **locally** and set **INSTAGRAM_COOKIES_BROWSER** (e.g. `chrome`) so yt-dlp uses your browser’s live session.
- **Pinterest** and **direct/video links** usually work from Railway. The app shows a generic error when a link fails so users can keep using it for other sites.
- **Redeploy** periodically so the Docker image gets the latest yt-dlp (`yt-dlp -U` is applied on each new deploy from the Dockerfile).

---

## Quick checklist

- [ ] Node 18+ and yt-dlp installed (`brew install yt-dlp`)
- [ ] `npm install` and `node server.js` in `backend/`
- [ ] [http://localhost:3000/health](http://localhost:3000/health) returns `{"status":"ok"}`
- [ ] Dev: set BACKEND_URL = `http://localhost:3000` (Simulator) or `http://YOUR_MAC_IP:3000` (device)
- [ ] App Store: deploy backend (Railway), set `AppConfig.productionBackendURL` in the app, then submit
