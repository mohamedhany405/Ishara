# Ishara Cloud Deployment Guide (No Credit Card)

## Recommended architecture
1. Frontend: Vercel (your existing deployment URL can stay).
2. Backend: Vercel Serverless Functions from the `server` folder in this repo.
3. Database: MongoDB Atlas M0 free tier.
4. Media uploads: Cloudinary free tier (recommended for avatar durability).

Why this is recommended:
- No personal PC uptime required.
- No local Node server required.
- No local MongoDB required.
- No credit card needed for Vercel Hobby, Atlas M0, or Cloudinary free setup.

## What this repo now supports
- Serverless backend entrypoint: `server/api/[...path].js`
- Shared Express app bootstrap: `server/app.js`
- MongoDB serverless-safe connection caching: `server/config/dbConfig.js`
- Vercel function config: `server/vercel.json`
- Environment template for Atlas + Vercel: `server/.env.example`

## 1) Create MongoDB Atlas M0 (no card)
1. Go to atlas.mongodb.com and create a free account.
2. Click Build a Database.
3. Choose M0 Free.
4. Pick any cloud provider/region that is free and close to your users.
5. Create a cluster (cluster name can stay default).
6. Open Database Access.
7. Click Add New Database User.
8. Username example: `ishara_app`.
9. Password: generate a strong password and save it.
10. Role: Atlas Admin (or Read and write to any database).
11. Open Network Access.
12. Click Add IP Address.
13. For easiest first deployment, add `0.0.0.0/0`.
14. Open Database > Connect > Drivers.
15. Select Node.js.
16. Copy the connection string and replace `<password>` and database name with `ishara`.

Example:
`mongodb+srv://ishara_app:YOUR_DB_PASSWORD@cluster0.xxxxx.mongodb.net/ishara?retryWrites=true&w=majority&appName=Cluster0`

## 2) Create Cloudinary free account (recommended)
1. Go to cloudinary.com and sign up for free.
2. Open Dashboard.
3. Copy:
   - Cloud name
   - API key
   - API secret

Cloudinary is recommended because Vercel function filesystem is ephemeral.

## 3) Deploy backend to Vercel (from `server` folder)
1. Push your code to GitHub.
2. Go to vercel.com and click Add New > Project.
3. Import the GitHub repository.
4. In project settings before deploy:
   - Framework Preset: Other
   - Root Directory: `server`
5. Build settings:
   - Build Command: leave empty
   - Output Directory: leave empty
   - Install Command: `npm install`
6. Add environment variables from `server/.env.example`.
7. Click Deploy.
8. After deploy, open backend health endpoint:
   - `https://<your-backend-vercel-domain>/api/health`

## 4) Required backend environment variables
Set these in Vercel Project Settings > Environment Variables:

- `NODE_ENV=production`
- `MONGODB_URI=<your Atlas URI>`
- `CLIENT_ORIGIN=https://ishara-6ce5t0b1o-mohamedhany405s-projects.vercel.app`
- `FRONTEND_URL=https://ishara-6ce5t0b1o-mohamedhany405s-projects.vercel.app`
- `BACKEND_PUBLIC_URL=https://<your-backend-vercel-domain>`
- `JWT_SECRET=<long-random-secret>`
- `JWT_EXPIRES_IN=2d`
- `SKIP_EMAIL_VERIFY=false`
- `EMAIL_USER=<gmail-address>`
- `EMAIL_PASS=<gmail-app-password>`
- `CLOUDINARY_CLOUD_NAME=<cloud-name>`
- `CLOUDINARY_API_KEY=<api-key>`
- `CLOUDINARY_API_SECRET=<api-secret>`
- `CLOUDINARY_FOLDER=ishara/avatars`

Optional:
- `DEV_CLIENT_ORIGIN=http://localhost:3000`
- `ALLOWED_ORIGINS=<comma-separated-extra-origins>`

Notes:
- `PORT` and `HOST` are not required in Vercel serverless runtime.
- `MONGODB_URI` is preferred. `CONNECTION_STRING` remains supported as fallback.

## 5) Frontend API base URL setup
This app uses `API_BASE_URL`.

For local development:
- Run backend locally and use default emulator fallback (`http://10.0.2.2:5000`) for Android emulator.

For production builds:
- Set backend URL explicitly:

`flutter build web --release --dart-define=API_BASE_URL=https://<your-backend-vercel-domain>`

`flutter build apk --release --dart-define=API_BASE_URL=https://<your-backend-vercel-domain>`

`flutter build appbundle --release --dart-define=API_BASE_URL=https://<your-backend-vercel-domain>`

## 6) CORS checklist
1. Ensure backend `CLIENT_ORIGIN` exactly matches your Vercel frontend URL.
2. If you use preview deployments, add them in `ALLOWED_ORIGINS` separated by commas.
3. Redeploy backend after changing environment variables.

## 7) Update existing frontend deployment
1. In your frontend Vercel project, set `API_BASE_URL` (or frontend-specific API env var) to your backend Vercel domain.
2. Redeploy frontend.
3. Open browser DevTools Network tab and verify requests go to:
   - `https://<your-backend-vercel-domain>/api/...`

## 8) End-to-end test (PC can be OFF)
1. Open `https://<your-backend-vercel-domain>/api/health` and confirm status is `ok`.
2. Open your frontend URL and register a user.
3. Verify OTP flow and login.
4. Open profile and update avatar.
5. Submit contact form.
6. Confirm records exist in MongoDB Atlas collections.
7. Turn off your PC and test again from mobile data.

If these pass, your system is fully cloud-hosted and independent.

## 9) No-credit-card backup hosts (only if needed)
Use these only if your backend cannot run as serverless functions:

1. Glitch
   - Very easy setup, but projects can sleep and have resource limits.
2. Cyclic.sh
   - Node-friendly, simple GitHub deploy, but free-tier limits apply.
3. Back4app Containers/CaaS
   - More structured hosting, but configuration is more involved.
4. Serv00
   - Free shell hosting, but setup is manual and less beginner-friendly.

For this project, Vercel serverless remains the best first choice.
