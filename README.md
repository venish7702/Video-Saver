# Video Saver

iOS app built with SwiftUI (iOS 16+). Four tabs: Home, Preview, Downloads, Settings.

## Build

1. Open `VideoSaver.xcodeproj` in Xcode.
2. Set your backend URL: **Edit Scheme** → **Run** → **Arguments** → **Environment Variables** → add `BACKEND_URL` = your backend base URL (e.g. `https://your-server.com` or `http://localhost:3000` for local).
3. Select a simulator or device and press **Run** (⌘R).

## Structure

- **Home** — Paste video URL, tap Find Media to analyze; on success you go to Preview.
- **Preview** — Thumbnail placeholder, file info, Save Video (starts download), Save to Camera Roll (when file is downloaded).
- **Downloads** — List with search, progress for active downloads, play/save to Photos, swipe to delete.
- **Settings** — Dark mode, Privacy & Terms, Share App, Rate App.

No RapidAPI, no Google Cloud dependency, no API keys. Backend is your own Node.js + yt-dlp server.

## Backend (Node.js + yt-dlp)

The app accepts **Instagram Reel URLs only** (`instagram.com/reel/`). Backend returns progressive MP4 (audio+video) formats only.

1. **Run the backend** (from project root):
   - `cd backend && npm install && npm start` — runs on port 3000.
   - On Mac with Homebrew yt-dlp: `YT_DLP_PATH=/opt/homebrew/bin/yt-dlp npm start` (or set in env).
   - Or with Docker: `docker build -t video-saver-backend ./backend && docker run -p 3000:3000 video-saver-backend`
2. **Point the app at it**: set `BACKEND_URL` in the Xcode scheme to your backend base URL (e.g. `http://192.168.x.x:3000` for a real device on same Wi‑Fi).
3. Backend must be HTTPS in production; for local dev, `http://...` is fine.

The backend exposes:
- `POST /analyze` — body `{ "url": "https://instagram.com/reel/..." }` → returns title, thumbnail, sourceDomain, formats (progressive MP4 only; each with quality, url, size).
- `GET /health` — returns `{ "status": "ok" }`.
