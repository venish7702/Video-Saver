# Running Video Saver Long-Term for Many Users

A practical guide to keep the app working reliably and scale for many users.

---

## 1. What Works Reliably (Focus Here)

| Source | From Railway/hosted backend | Notes |
|--------|----------------------------|--------|
| **Pinterest** | ✅ Usually works | Pin.it and pinterest.com. Optional: set `PINTEREST_COOKIES_BROWSER` when running locally. |
| **Direct video links** | ✅ Works | .mp4 and other direct URLs. |
| **Other yt-dlp sites** | ✅ Often works | Many sites work without login. |
| **Instagram** | ⚠️ Unreliable from server | Needs fresh cookies; server IPs often blocked. Best as “best effort,” not guaranteed. |
| **Facebook** | ⚠️ Unreliable | Extractor breaks often; cookies may help when running locally. |

**Strategy:** Position the app as “save videos from the web” and support multiple link types. Don’t promise “Instagram downloader.” When one platform fails, others still work so the app stays useful.

---

## 2. Backend: Keep It Healthy

### Update yt-dlp regularly
- **Railway:** Redeploy the backend every few weeks so the Docker image gets the latest yt-dlp (your Dockerfile installs from GitHub releases).
- **Local:** Run `yt-dlp -U` or `brew upgrade yt-dlp` periodically.

### Don’t rely only on Instagram
- Don’t put Instagram cookies on a high-traffic server. Use them only if you accept that they’ll often fail from datacenter IPs.
- If you do use cookies: use a **secondary** Instagram account, refresh every few days, and keep request volume low.

### Monitor the backend
- Check **Railway logs** for “yt-dlp error” or 422s. A sudden spike can mean a platform changed or rate limiting.
- Use **/health**: e.g. a simple uptime monitor that hits `https://your-backend/health` every 5–10 minutes.
- Set a **budget/alert** in Railway so you’re notified before running out of credit.

---

## 3. Handling Many Users (Scale)

### Rate limiting (included)
- The backend **already rate-limits** `/analyze`: **18 requests per minute per IP** (configurable).
- To change: set env **RATE_LIMIT_PER_MINUTE** (e.g. `15` or `25`). Default 18.
- When exceeded, the API returns 429 and the app shows “Too many requests. Please try again in a minute.”
- This keeps one user or bot from overloading the server and getting your IP blocked by Instagram/Pinterest.

### Optional: queue for heavy load
- If you grow to hundreds of concurrent users, consider a small queue (e.g. Redis + worker) so analyze requests are processed in order and you don’t run 50 yt-dlp processes at once. Start simple; add only when needed.

### Cost (Railway)
- Railway charges by usage. More users = more CPU/time. Monitor usage and set a monthly limit so you don’t get surprised.
- If traffic grows, consider a fixed plan or another host with predictable pricing.

---

## 4. What to Tell Users (In-App & Store)

### In the app
- Keep the **generic error** message: “This link could not be loaded. Try again later.” (no platform names).
- You can add a short **“Tips”** or **“Supported links”** line in Settings: e.g. “Works best with direct video links and many popular video sites. Some links may not load depending on the source.”
- Don’t promise “Instagram always works” or “all sites supported.”

### On the App Store
- **Description:** “Save videos from supported web links” / “Paste a video link to save for offline viewing.” Mention “supported links” and “many popular sites,” not a list of platforms.
- **Keywords:** video, download, save, offline (avoid platform names to reduce rejections and set correct expectations).

### When a link fails
- User sees the generic error. They can try another link or try again later. No need to explain Instagram/Facebook; keep it simple.

---

## 5. Checklist: Long-Term and Many Users

- [ ] **Redeploy backend** every few weeks (or when yt-dlp releases a fix) so you’re on a recent yt-dlp.
- [ ] **Monitor** Railway usage and logs; set a budget/alert.
- [ ] **Add rate limiting** on `/analyze` (per IP or per user) to protect the backend and reduce platform blocks.
- [ ] **Don’t depend on Instagram** for “the app works.” Treat it as best-effort; emphasize Pinterest, direct links, and other sites.
- [ ] **Cookies (optional):** If you use Instagram cookies, use a secondary account and refresh every few days; prefer local backend + `INSTAGRAM_COOKIES_BROWSER` for testing.
- [ ] **App Store:** Keep descriptions and errors generic; no platform promises.
- [ ] **Health check:** Use an external uptime checker for `https://your-backend/health`.
- [ ] **Terms & Privacy:** Keep your Terms of Use and Privacy Policy URLs valid and updated.

---

## 6. Quick Wins (Do First)

1. **Rate limit** `/analyze` (e.g. 15 req/min per IP) so one user can’t overload the server.
2. **Redeploy** the backend once a month so yt-dlp stays up to date.
3. **Set a Railway budget** (e.g. $5–10/month alert) so you notice usage spikes.
4. **Add a short “Tips” line** in the app (e.g. in Settings): “Works best with direct video links and many video sites. Some links may not load.”

Doing these will help the app run for a long time and for many users without over-promising on platforms that often block servers (like Instagram).
