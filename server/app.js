const path = require("path");
const fs = require("fs");
require("dotenv").config({ path: path.join(__dirname, ".env") });

const express = require("express");
const cors = require("cors");
const rateLimit = require("express-rate-limit");
const multer = require("multer");
const mongoose = require("mongoose");

const profileRoutes = require("./Routes/usersRoutes");
const authRoutes = require("./Routes/authRoutes");
const contactRoutes = require("./Routes/contactRoutes");
const learningRoutes = require("./Routes/learningRoutes");
const historyRoutes = require("./Routes/historyRoutes");
const connectDB = require("./config/dbConfig");

const app = express();

// Required behind reverse proxies (Vercel/Render/etc.) for accurate client IP handling.
app.set("trust proxy", 1);

const uploadsDir = process.env.VERCEL
  ? path.join("/tmp", "ishara-uploads")
  : path.join(__dirname, "uploads");

if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const uploadStorage = multer.diskStorage({
  destination(req, file, cb) {
    cb(null, uploadsDir);
  },
  filename(req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: uploadStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
});

app.use(express.json());

const allowedOrigins = new Set(
  [
    process.env.CLIENT_ORIGIN,
    process.env.DEV_CLIENT_ORIGIN,
    ...(process.env.ALLOWED_ORIGINS || "")
      .split(",")
      .map((origin) => origin.trim())
      .filter(Boolean),
  ].filter(Boolean)
);

app.use(
  cors({
    origin(origin, callback) {
      // Mobile apps and non-browser clients usually send no Origin header.
      if (!origin) return callback(null, true);

      // If no origins are configured, allow all to avoid accidental lockout.
      if (allowedOrigins.size === 0 || allowedOrigins.has(origin)) {
        return callback(null, true);
      }

      return callback(new Error(`CORS blocked for origin: ${origin}`));
    },
  })
);

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/contact", contactRoutes);
app.use("/api/users", profileRoutes);
app.use("/api/learning", learningRoutes);
app.use("/api/history", historyRoutes);

// Simple file upload route (kept for compatibility). In cloud mode, prefer Cloudinary.
app.post("/api/upload", upload.single("file"), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }

    res.json({
      message: "File uploaded successfully",
      filename: req.file.filename,
      originalname: req.file.originalname,
      size: req.file.size,
      mimetype: req.file.mimetype,
      path: `/uploads/${req.file.filename}`,
    });
  } catch (error) {
    console.error("Upload error:", error);
    res
      .status(500)
      .json({ message: "File upload failed", error: error.message });
  }
});

// Serve static files
app.use("/public", express.static(path.join(__dirname, "public")));
app.use("/uploads", express.static(uploadsDir));

function getMongoStateLabel(state) {
  switch (state) {
    case 1:
      return "connected";
    case 2:
      return "connecting";
    case 3:
      return "disconnecting";
    default:
      return "disconnected";
  }
}

app.get("/api/health", async (req, res) => {
  if (mongoose.connection.readyState !== 1) {
    try {
      await ensureDbConnection();
    } catch (_) {
      // Keep health endpoint responsive even if DB is temporarily unavailable.
    }
  }

  const readyState = mongoose.connection.readyState;

  res.json({
    status: readyState === 1 ? "ok" : "degraded",
    timestamp: new Date().toISOString(),
    runtime: process.env.VERCEL ? "vercel-serverless" : "node-server",
    database: {
      state: getMongoStateLabel(readyState),
      readyState,
    },
  });
});

app.get("/", (req, res) => {
  res.json({ message: "API Server is running" });
});

app.use((err, req, res, next) => {
  if (typeof err?.message === "string" && err.message.startsWith("CORS blocked")) {
    return res.status(403).json({ message: err.message });
  }
  next(err);
});

app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && "body" in err) {
    return res.status(400).json({ message: "Invalid JSON" });
  }
  next(err);
});

app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === "LIMIT_FILE_SIZE") {
      return res
        .status(400)
        .json({ message: "File too large. Max size is 5MB" });
    }
    return res.status(400).json({ message: err.message });
  }
  next(err);
});

let dbReadyPromise = null;

async function ensureDbConnection() {
  if (!dbReadyPromise) {
    dbReadyPromise = connectDB().catch((error) => {
      dbReadyPromise = null;
      throw error;
    });
  }

  return dbReadyPromise;
}

module.exports = {
  app,
  ensureDbConnection,
};
