const path = require("path");
require("dotenv").config({ path: path.join(__dirname, ".env") });
const express = require("express");
const cors = require("cors");
const rateLimit = require("express-rate-limit");
const multer = require("multer");
const fs = require("fs");
const profileRoutes = require("./Routes/usersRoutes");
const connectDB = require("./config/dbConfig");
const authRoutes = require("./Routes/authRoutes");
const contactRoutes = require("./Routes/contactRoutes");

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || "0.0.0.0";

// Required behind Render/other reverse proxies for accurate client IP handling.
app.set("trust proxy", 1);

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// REMOVED: Duplicate multer config - using the one from upload.js instead
// Only keep this if you need a simple upload for the /api/upload route
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
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

// Debug middleware loading
console.log("=== DEBUG: Checking authMiddleware ===");
try {
  const auth = require("./middleware/authMiddleware");
  console.log("✅ authMiddleware loaded successfully");
  console.log("Exports:", Object.keys(auth));
} catch (err) {
  console.error("❌ Error loading authMiddleware:", err.message);
}

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/contact", contactRoutes);

// Simple file upload route (using the simple multer config)
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
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// User profile routes
app.use("/api/users", profileRoutes);

// Health route for uptime checks
app.get("/api/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// Root route
app.get("/", (req, res) => {
  res.json({ message: "API Server is running 🟢" });
});

// CORS error handler
app.use((err, req, res, next) => {
  if (typeof err?.message === "string" && err.message.startsWith("CORS blocked")) {
    return res.status(403).json({ message: err.message });
  }
  next(err);
});

// JSON parse error handler
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && "body" in err) {
    return res.status(400).json({ message: "Invalid JSON" });
  }
  next(err);
});

// Error handler for multer
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

// Start server only after DB is connected (fixes internal server errors on first requests)
connectDB()
  .then(() => {
    app.listen(PORT, HOST, () => {
      console.log(`Server is running on ${HOST}:${PORT}`);
    });
  })
  .catch((err) => {
    console.error("DB connection error:", err.message);
    process.exit(1);
  });