const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const otpGenerator = require("otp-generator");

const User = require("../models/User");
const sendEmail = require("../utils/sendEmail");

// FIX: Import authMiddleware correctly
const { authMiddleware } = require("../middleware/authMiddleware");

const {
  registerSchema,
  verifySchema,
  loginSchema,
  resendOtpSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} = require("../validation/userValidator");

function sendJoiValidationError(res, error) {
  const fieldErrors =
    error?.details?.map((d) => ({
      field:
        Array.isArray(d.path) && d.path.length ? String(d.path[0]) : "unknown",
      message: d.message,
    })) ?? [];

  return res.status(400).json({
    message: "Please check the highlighted fields and try again.",
    errors: fieldErrors,
  });
}

// Reusable OTP generator
const generateOTP = () =>
  otpGenerator.generate(6, {
    digits: true,
    lowerCaseAlphabets: false,
    upperCaseAlphabets: false,
    specialChars: false,
  });

// Rate limit for resend-otp
const OTP_RESEND_LIMIT_MS = 60 * 1000;
const resendTimestamps = new Map();

// ─────────────────────────────────────────────
// REGISTER
// ─────────────────────────────────────────────
router.post("/register", async (req, res) => {
  try {
    const { error, value } = registerSchema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });
    if (error) {
      return sendJoiValidationError(res, error);
    }

    const { email, password, name, disabilityType } = value;

    if (await User.exists({ email })) {
      return res.status(409).json({ message: "Email already registered" });
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const otp = generateOTP();

    // Dynamic default avatar from user's name (teal bg, white text, bold initials)
    const profilePic = `https://ui-avatars.com/api/?name=${encodeURIComponent(name || "User")}&background=14B8A6&color=fff&size=128&bold=true`;

    const user = await User.create({
      ...value,
      password: hashedPassword,
      profilePic,
      otp,
      otpExpiry: Date.now() + 10 * 60 * 1000, // 10 minutes
    });

    // Try to send OTP email, but don't block registration if it fails
    try {
      await sendEmail(
        email,
        "Your OTP Code",
        `Hello,\n\nYour OTP code is: ${otp}\n\nValid for 10 minutes.\n\nThank you!`,
      );
    } catch (emailErr) {
      console.error("Failed to send OTP email (user still created):", emailErr.message);
    }

    return res.status(201).json({
      message: "Registration successful. Check your email for OTP.",
    });
  } catch (error) {
    console.error("Register error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

// ─────────────────────────────────────────────
// VERIFY OTP
// ─────────────────────────────────────────────
router.post("/verify-otp", async (req, res) => {
  try {
    const { error, value } = verifySchema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });
    if (error) {
      return sendJoiValidationError(res, error);
    }

    const { email, otp } = value;

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.isVerified) {
      return res.status(400).json({ message: "User already verified" });
    }

    if (user.otp !== otp || user.otpExpiry < Date.now()) {
      return res.status(400).json({ message: "Invalid or expired OTP" });
    }

    user.isVerified = true;
    user.otp = undefined;
    user.otpExpiry = undefined;
    await user.save();

    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN },
    );

    return res.json({
      message: "Email verified successfully",
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        profilePic: user.profilePic,
        role: user.role,
        isVerified: user.isVerified,
        disabilityType: user.disabilityType,
      },
    });
  } catch (error) {
    console.error("Verify OTP error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

// ─────────────────────────────────────────────
// LOGIN
// ─────────────────────────────────────────────
router.post("/login", async (req, res) => {
  try {
    const { error, value } = loginSchema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });
    if (error) {
      return sendJoiValidationError(res, error);
    }

    const { email, password } = value;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    if (!user.isVerified) {
      return res.status(403).json({
        message: "Please verify your email first",
        isVerified: false,
        email: user.email,
      });
    }

    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN },
    );

    return res.json({
      message: "Login successful",
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        profilePic: user.profilePic,
        role: user.role,
        isVerified: user.isVerified,
        disabilityType: user.disabilityType,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

// ─────────────────────────────────────────────
// RESEND OTP
// ─────────────────────────────────────────────
router.post("/resend-otp", async (req, res) => {
  try {
    const { error, value } = resendOtpSchema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });
    if (error) {
      return sendJoiValidationError(res, error);
    }

    const { email } = value;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.isVerified) {
      return res.status(400).json({ message: "User already verified" });
    }

    const lastResend = resendTimestamps.get(email) || 0;
    if (Date.now() - lastResend < OTP_RESEND_LIMIT_MS) {
      return res.status(429).json({ message: "Please wait before resending" });
    }

    const otp = generateOTP();
    user.otp = otp;
    user.otpExpiry = Date.now() + 10 * 60 * 1000;
    await user.save();

    await sendEmail(
      email,
      "Your New OTP Code",
      `Hello,\n\nYour new OTP code is: ${otp}\n\nValid for 10 minutes.\n\nThank you!`,
    );

    resendTimestamps.set(email, Date.now());

    return res.json({ message: "New OTP sent to your email" });
  } catch (error) {
    console.error("Resend OTP error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

// ─────────────────────────────────────────────
// FORGOT PASSWORD
// ─────────────────────────────────────────────
router.post("/forgot-password", async (req, res) => {
  try {
    const { error, value } = forgotPasswordSchema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });
    if (error) {
      return sendJoiValidationError(res, error);
    }

    const { email } = value;

    const user = await User.findOne({ email });
    if (!user) {
      return res.json({ message: "Password reset link has been sent" });
    }

    const resetToken = crypto.randomBytes(20).toString("hex");
    user.resetPasswordToken = resetToken;
    user.resetPasswordExpiry = Date.now() + 3600000;
    await user.save();

    const resetUrl = `http://localhost:3000/reset-password/${resetToken}`;

    await sendEmail(
      email,
      "Password Reset Request",
      `Hello,\n\nClick this link to reset your password: ${resetUrl}\n\nValid for 1 hour.\n\nIf you didn't request this, ignore this email.`,
      `<p>Hello,</p>
   <p>Click this link to reset your password: <a href="${resetUrl}">Reset Password</a></p>
   <p><strong>Valid for 1 hour.</strong></p>
   <p>If you didn't request this, ignore this email.</p>`,
    );

    return res.json({
      message: "Password reset link has been sent",
      token: resetToken,
    });
  } catch (error) {
    console.error("Forgot password error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

// ─────────────────────────────────────────────
// RESET PASSWORD
// ─────────────────────────────────────────────
router.post("/reset-password", async (req, res) => {
  try {
    const { error, value } = resetPasswordSchema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });
    if (error) {
      return sendJoiValidationError(res, error);
    }

    const { token, newPassword } = value;

    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpiry: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({ message: "Invalid or expired token" });
    }

    user.password = await bcrypt.hash(newPassword, 12);
    user.resetPasswordToken = undefined;
    user.resetPasswordExpiry = undefined;
    await user.save();

    return res.json({ message: "Password reset successfully" });
  } catch (error) {
    console.error("Reset password error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

// ─────────────────────────────────────────────
// GET CURRENT USER (/me)
// ─────────────────────────────────────────────
router.get("/me", authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select(
      "-password -resetPasswordToken -resetPasswordExpiry -otp -otpExpiry",
    );

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.json({
      success: true,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        role: user.role,
        isVerified: user.isVerified,
        profilePic: user.profilePic,
        bio: user.bio,
        disabilityType: user.disabilityType,
        emergencyContacts: user.emergencyContacts,
        preferences: user.preferences,
      },
    });
  } catch (error) {
    console.error("Get /me error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

// ─────────────────────────────────────────────
// DEV ONLY: Get OTP for testing (not available in production)
// GET /api/auth/dev/get-otp?email=user@example.com
// ─────────────────────────────────────────────
if (process.env.NODE_ENV !== "production") {
  router.get("/dev/get-otp", async (req, res) => {
    try {
      const { email } = req.query;
      if (!email) {
        return res.status(400).json({ message: "email query param required" });
      }

      const user = await User.findOne({ email }).select(
        "otp otpExpiry isVerified name",
      );
      if (!user) {
        return res.status(404).json({ message: "User not found" });
      }

      if (user.isVerified) {
        return res.status(400).json({ message: "User already verified" });
      }

      if (!user.otp || user.otpExpiry < Date.now()) {
        return res
          .status(400)
          .json({ message: "OTP expired or not found. Use resend-otp first." });
      }

      return res.json({
        message: "DEV MODE: OTP retrieved successfully",
        otp: user.otp,
        expiresAt: new Date(user.otpExpiry).toISOString(),
        name: user.name,
      });
    } catch (error) {
      console.error("Dev get-otp error:", error);
      return res.status(500).json({ message: "Internal server error" });
    }
  });
}

module.exports = router;
