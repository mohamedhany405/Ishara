# Ishara Cloud Deployment Guide

## Recommended architecture
- Frontend: Vercel (existing project URL can stay the same)
- Backend API: Render Web Service (Node.js)
- Database: MongoDB Atlas (Belgium region)
- Media uploads: Cloudinary (durable avatar storage)
- Mobile/Web app client: use API_BASE_URL build variable

This setup works without keeping your PC on or connected by USB.

## 1) Create MongoDB Atlas connection string
1. Open MongoDB Atlas project.
2. In Database Access, create a DB user (or reuse your existing user).
3. In Network Access, allow Render IPs. For initial setup, 0.0.0.0/0 is simplest.
4. Copy the Node.js connection string.
5. Set database name to ishara.

Example:
mongodb+srv://<user>:<password>@<cluster>.mongodb.net/ishara?retryWrites=true&w=majority&appName=Cluster0

## 2) Create Cloudinary assets bucket
1. Open Cloudinary Console.
2. Copy the 3 values from Dashboard:
   - Cloud name
   - API Key
   - API Secret
3. Keep them for Render environment variables.

## 3) Deploy backend on Render
1. Push this repository to GitHub.
2. In Render, click New > Web Service.
3. Connect repo: mohamedhany405/Ishara
4. Configure:
   - Name: ishara-api
   - Runtime: Node
   - Branch: main
   - Root Directory: server
   - Build Command: npm install
   - Start Command: npm start
5. Add Environment Variables from server/.env.example.
6. Deploy.
7. Verify health endpoint:
   - https://<your-render-domain>/api/health

## 4) Required Render environment variables
Use server/.env.example as the source of truth.

Minimum required:
- NODE_ENV=production
- PORT=5000
- HOST=0.0.0.0
- CONNECTION_STRING=<atlas-uri>
- CLIENT_ORIGIN=https://ishara-6ce5t0b1o-mohamedhany405s-projects.vercel.app
- FRONTEND_URL=https://ishara-6ce5t0b1o-mohamedhany405s-projects.vercel.app
- BACKEND_PUBLIC_URL=https://<your-render-domain>
- JWT_SECRET=<long-random-secret>
- JWT_EXPIRES_IN=2d
- EMAIL_USER=<gmail-address>
- EMAIL_PASS=<gmail-app-password>
- SKIP_EMAIL_VERIFY=false
- CLOUDINARY_CLOUD_NAME=<cloud-name>
- CLOUDINARY_API_KEY=<api-key>
- CLOUDINARY_API_SECRET=<api-secret>
- CLOUDINARY_FOLDER=ishara/avatars

Optional:
- DEV_CLIENT_ORIGIN=http://localhost:3000
- ALLOWED_ORIGINS=<comma-separated-extra-origins>

## 5) Configure Vercel frontend
Keep your current Vercel frontend URL and ensure frontend API calls point to the deployed backend.

If your frontend has environment variables, set:
- VITE_API_BASE_URL=https://<your-render-domain>

Also ensure backend CLIENT_ORIGIN and FRONTEND_URL match your Vercel domain.

## 6) Build mobile/web app with cloud backend URL
For Flutter builds, pass API_BASE_URL at build time:

Android APK:
flutter build apk --release --dart-define=API_BASE_URL=https://<your-render-domain>

Android App Bundle:
flutter build appbundle --release --dart-define=API_BASE_URL=https://<your-render-domain>

Flutter web:
flutter build web --release --dart-define=API_BASE_URL=https://<your-render-domain>

## 7) End-to-end verification checklist
1. Open backend health URL and confirm status ok.
2. Register new account from app.
3. Receive OTP in Gmail and verify.
4. Login and open profile.
5. Upload avatar and confirm Cloudinary URL is saved.
6. Submit Contact form and confirm entry exists in MongoDB.
7. Turn off your PC and test app from another device/network.

If all steps pass, the system is fully cloud-hosted and independent.
