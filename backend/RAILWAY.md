# Deploy Video Saver backend to Railway

Follow these steps from the beginning.

---

## 1. Create a Railway account

1. Go to **[railway.app](https://railway.app)**.
2. Click **Login** (top right).
3. Sign in with **GitHub** (recommended) or **Google**.
4. Approve Railway’s access if asked.

---

## 2. Install Railway CLI (optional but useful)

- **Option A – Use the website only:** You can do everything in the browser; skip to step 3.
- **Option B – Use the CLI:**  
  - Mac (Homebrew): `brew install railway`  
  - Or: `npm i -g @railway/cli`  
  - Then run `railway login` in a terminal and follow the link.

---

## 3. Create a new project on Railway

1. Go to **[railway.app/dashboard](https://railway.app/dashboard)**.
2. Click **New Project**.
3. Choose **Deploy from GitHub repo**.
   - If this is your first time, click **Configure GitHub App** and allow Railway to see your repos.
   - Select the repo that contains your **Video Saver** project (the one with the `backend` folder).
4. Railway will ask **“Which directory?”** or **“Root directory”**.
   - Set the **root directory** to **`backend`** (so Railway builds and runs only the backend, not the whole repo).
5. Click **Deploy** (or **Add service** then deploy).

If you don’t use GitHub:

- Choose **Empty project**, then we’ll connect the `backend` folder via CLI or upload (see step 5 below).

---

## 4. Configure the service to use the Dockerfile

1. In your project, click your **service** (the backend).
2. Open **Settings** (or the **⋮** menu).
3. Find **Build** or **Deploy**:
   - **Builder:** set to **Dockerfile** (not Nixpacks).
   - **Dockerfile path:** leave as **Dockerfile** (it’s in `backend/`).
4. **Root directory** (if shown) should be **`backend`** so Railway runs `docker build` inside `backend/`.

---

## 5. Deploy

**If you connected a GitHub repo:**

- Push your code (with the `backend/Dockerfile` and `backend/RAILWAY.md`). Railway will build and deploy automatically.
- If it didn’t deploy: open the service → **Deployments** → **Redeploy** or **Trigger deploy**.

**If you started an empty project:**

- In your project folder (where `backend` is), run:
  - `railway link` (choose the project and service).
  - `cd backend && railway up`
- Or: **Settings** → **Connect repo** and point it at the repo + `backend` directory, then deploy.

---

## 6. Get your backend URL

1. Open your **service** on Railway.
2. Go to **Settings** → **Networking** (or **Variables** / **Public networking**).
3. Click **Generate domain** (or **Add domain**). Railway will give you a URL like:
   - `https://your-service-name.up.railway.app`
4. Copy this URL; this is your **backend URL**.

---

## 7. Test the backend

1. In a browser or with curl:
   - **Health:** `https://YOUR-RAILWAY-URL/health`  
     You should see: `{"status":"ok"}`.
2. From your iOS app:
   - Set **BACKEND_URL** (in Xcode scheme or in code) to:  
     `https://YOUR-RAILWAY-URL`  
     (no trailing slash, e.g. `https://video-saver-backend.up.railway.app`).
3. Run the app and try **Fetch** with an Instagram Reel URL; it should hit Railway and return metadata.

---

## 8. Use the URL in your iOS app

- **Development (Xcode):**  
  Edit Scheme → Run → Arguments → Environment Variables → add:
  - Name: `BACKEND_URL`  
  - Value: `https://YOUR-RAILWAY-URL`

- **Production (when you ship the app):**  
  Set the production backend URL in your app (e.g. in `LinkParserService` or a config) so the released app uses `https://YOUR-RAILWAY-URL` instead of localhost.

---

## Summary

| Step | What to do |
|------|------------|
| 1 | Sign up at [railway.app](https://railway.app) (e.g. with GitHub). |
| 2 | (Optional) Install Railway CLI. |
| 3 | New Project → Deploy from GitHub repo → choose repo → **Root directory: `backend`**. |
| 4 | Set builder to **Dockerfile**, root directory **`backend`**. |
| 5 | Deploy (push to GitHub or `railway up` from `backend`). |
| 6 | Generate domain → copy **backend URL**. |
| 7 | Test `/health` and set **BACKEND_URL** in the app to that URL. |

If a step fails, check **Deployments** and **Logs** for your service on Railway for the exact error.
