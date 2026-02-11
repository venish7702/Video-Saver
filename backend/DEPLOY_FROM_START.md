# Deploy Video Saver Backend From Start

This guide takes you from zero to a live backend URL you can use in your app (and for App Store). We use **Railway** (free tier available).

---

## Before you start

- You have the **Video Saver** project on your Mac (with the `backend` folder).
- Your project is on **GitHub** (so Railway can deploy from it).  
  If not: create a repo on GitHub, then in Terminal:
  ```bash
  cd "/Users/rakholiyavenish/Desktop/Video Saver"
  git init
  git add .
  git commit -m "Initial commit"
  git branch -M main
  git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
  git push -u origin main
  ```
  Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your GitHub username and repo name.

---

## Step 1: Create a Railway account

1. Open a browser and go to **https://railway.app**
2. Click **Login** (top right).
3. Click **Login with GitHub** (or Google).
4. Authorize Railway when GitHub asks. You’ll land on the Railway dashboard.

---

## Step 2: Create a new project

1. On the dashboard, click **New Project**.
2. You’ll see options like “Deploy from GitHub repo”, “Empty project”, etc.
3. Click **Deploy from GitHub repo**.
   - If you see **Configure GitHub App**, click it and allow Railway to access your GitHub (and select the repo or “All repos”).
   - Then again click **New Project** → **Deploy from GitHub repo**.
4. In the list, select the **repository** that contains your Video Saver project (the one that has a `backend` folder).
5. Railway may ask **“Root directory”** or **“Which directory to deploy?”**:
   - Choose or type **`backend`** (only the backend folder will be built and run).
6. Click **Deploy** or **Add service**. Railway will start building.

---

## Step 3: Use the Dockerfile (important)

Railway might auto-detect Node and use “Nixpacks”. We need **Dockerfile** so that **yt-dlp** is installed.

1. In your project, click the **service** (the box that represents your backend).
2. Go to **Settings** (tab or gear icon).
3. Find **Build** section:
   - **Builder:** select **Dockerfile** (not Nixpacks).
   - **Dockerfile path:** leave as **Dockerfile** (or set to `Dockerfile` if empty).
4. **Root directory** (if shown): must be **`backend`**.
5. Save / leave the page. If the build was already running, trigger a **Redeploy** (see Step 4).

---

## Step 4: Deploy and wait for “Success”

1. If you just changed settings, open the **Deployments** tab and click **Redeploy** (or **Deploy**).
2. Watch the **Build** and **Deploy** logs. Wait until status is **Success** (green).
3. If it fails:
   - Check that your GitHub repo has the `backend` folder with `Dockerfile`, `server.js`, `package.json`.
   - In Railway **Settings**, confirm Root directory = `backend` and Builder = **Dockerfile**.
   - Read the error in the log; it often says which file or step failed.

---

## Step 5: Get your public URL

1. In your project, select your **service** (the backend).
2. Go to **Settings** → **Networking** (or **Variables** and look for “Public networking” / “Generate domain”).
3. Click **Generate domain** (or **Add domain**). Railway will create a URL like:
   - `https://video-saver-backend-production-xxxx.up.railway.app`
4. **Copy this URL** (no trailing slash). This is your **backend URL**. You’ll use it in the app.

---

## Step 6: Test the backend

1. In the browser, open: **`https://YOUR-RAILWAY-URL/health`**  
   (paste the URL you copied and add `/health` at the end.)
2. You should see: **`{"status":"ok"}`**
3. If you see that, the backend is running correctly.

---

## Step 7: Use the URL in your iOS app

1. Open your project in **Xcode**.
2. In the left sidebar, open **VideoSaver** → **Config** → **AppConfig.swift**.
3. Find the line:
   ```swift
   static let productionBackendURL = "https://your-backend.up.railway.app"
   ```
4. Replace the value with **your real Railway URL** (the one you copied), for example:
   ```swift
   static let productionBackendURL = "https://video-saver-backend-production-xxxx.up.railway.app"
   ```
5. Save the file.
6. **To test:** In Xcode, Edit Scheme → Run → Arguments → Environment Variables: **remove** or leave **BACKEND_URL** unset so the app uses `productionBackendURL`. Run the app and try **Fetch** with an Instagram link; it should work with your Railway backend.

---

## Summary checklist

| Step | What you did |
|------|------------------|
| 1 | Signed up at railway.app with GitHub |
| 2 | New Project → Deploy from GitHub repo → chose your repo → Root directory: **backend** |
| 3 | Settings → Builder: **Dockerfile**, Root: **backend** |
| 4 | Deploy / Redeploy until status is Success |
| 5 | Settings → Networking → Generate domain → copy URL |
| 6 | Opened `YOUR-URL/health` in browser → saw `{"status":"ok"}` |
| 7 | In AppConfig.swift set `productionBackendURL` to that URL |

---

## If you don’t use GitHub (deploy from your Mac with CLI)

1. Create an **Empty project** on Railway (New Project → Empty project).
2. On your Mac, install Railway CLI: `brew install railway`
3. Log in: `railway login` (follow the link in the terminal).
4. In Terminal:
   ```bash
   cd "/Users/rakholiyavenish/Desktop/Video Saver/backend"
   railway link
   ```
   Select the empty project and create a new service when asked.
5. Deploy:
   ```bash
   railway up
   ```
6. In Railway dashboard: open the service → Settings → Networking → **Generate domain**, then copy the URL and use it in **AppConfig.swift** as in Step 7 above.

---

## Troubleshooting

- **Build fails:** Check Railway **Deployments** → click the failed run → read the log. Often it’s “root directory” (must be `backend`) or “Dockerfile not found” (Dockerfile must be inside `backend`).
- **/health not loading:** Wait 1–2 minutes after first deploy. Check that the domain was generated (Settings → Networking).
- **App can’t connect:** Make sure you put the URL in **AppConfig.swift** (no trailing slash), and that you’re not overriding it with **BACKEND_URL** pointing to localhost when testing the “production” flow.

Once Steps 1–7 are done, your backend is deployed and your app can use it for Fetch and downloads, including for App Store builds.
