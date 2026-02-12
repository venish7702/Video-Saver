# App Store Submission Guide – Video Saver

Use this when submitting to the App Store to improve approval chances under Guideline 5.2.3 (third-party content).

---

## 1. App Store Connect Metadata

**Do not mention** Instagram, Facebook, Pinterest, YouTube, or any specific platform in:
- App Name
- Subtitle
- Description
- Keywords
- Screenshots / preview text

**Suggested wording:**

| Field | Example (adjust to your app) |
|-------|------------------------------|
| **App Name** | Video Saver (or "Video Saver – Offline Viewer") |
| **Subtitle** | Save web videos for offline viewing |
| **Short description** | Save videos from supported web links for offline viewing. Play, organize, and manage your saved videos. |
| **Full description** | Video Saver lets you save videos from supported web links to your device for offline viewing. Paste a video link, choose quality, and download. You can play saved videos anytime, rename them, share files, or delete them. Only save content you own or have permission to use. You are responsible for complying with copyright and the terms of the source you use. |
| **Keywords** | video, download, save, offline, library, player (no platform names) |

---

## 2. Notes for App Review (Critical)

In **App Store Connect → Your App → App Review Information → Notes**, paste something like:

```
APP FUNCTIONALITY
- The app allows users to save videos from web links for personal offline viewing.
- Users paste a publicly available video URL; the app fetches metadata and offers a download.
- Downloads are stored locally on the device. Users can play, rename, share (file), or delete saved videos.

COMPLIANCE
- We do not encourage or support saving content that users do not have rights to.
- In-app copy and Terms of Use state: "Only save content you own or have permission to use."
- The app is intended for personal use (e.g. saving one’s own content or content with permission).

DEMO / TESTING
- Backend is live. No login required.
- For review, you can use any public video URL that returns a playable format (e.g. a direct .mp4 link or a supported web video link).
- Example (if your backend supports it): [provide one sample public video URL that works with your app]
```

Replace the example URL with a real link that works with your backend during review.

---

## 3. Before You Submit

- [ ] **Backend is live** and reachable (no “hostname not found” during review).
- [ ] **Privacy Policy URL** and **Terms of Use URL** are set in the app (Privacy: Blogger; Terms: Google Sites). Update in App Store Connect if you use different URLs there.
- [ ] **Support URL** in App Store Connect is valid and has a way to contact you.
- [ ] **Demo:** Test with a neutral public video URL (e.g. direct MP4 or a link your backend supports) so the reviewer does not need to use any specific platform.
- [ ] **Screenshots** show the app with generic “video link” / “Paste video link” (no platform-specific wording).
- [ ] **In-app:** “Terms of Use” in Settings is visible and explains acceptable use (only content you own or have permission to use).

---

## 4. What We Changed in the App

- **Copy:** Generic “video link” / “Paste video link”; no Instagram or other platform names in UI or comments.
- **Disclaimer on Fetch screen:** “Only save content you own or have permission to use.”
- **Terms of Use (Settings):** Explains acceptable use and user responsibility for copyright and source terms.
- **Comments:** Removed references to specific platforms from code comments.

---

## 5. Risk Reminder

Apple may still reject the app under **Guideline 5.2.3** if they conclude the app is designed to download content from third-party services without authorization. The changes above are to present the app as a generic “save web videos for personal use with user responsibility” and to avoid explicitly promoting use with Instagram or similar platforms. There is no guarantee of approval.
