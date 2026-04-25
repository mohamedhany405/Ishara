const express = require("express");
const router = express.Router();
const Joi = require("joi");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const User = require("../models/User");
const {
    isCloudinaryConfigured,
    uploadAvatarToCloudinary,
    uploadAvatarBufferToCloudinary,
} = require("../utils/cloudinary");
const { resolvePublicUrl } = require("../utils/urlUtils");

// FIX: Import authMiddleware correctly - it exports { authMiddleware }
const { authMiddleware } = require("../middleware/authMiddleware");

function buildUserResponse(req, user) {
    return {
        id: user._id,
        email: user.email,
        name: user.name,
        phone: user.phone || "",
        role: user.role,
        isVerified: user.isVerified,
        profilePic: resolvePublicUrl(req, user.profilePic),
        bio: user.bio,
        disabilityType: user.disabilityType,
        emergencyContacts: user.emergencyContacts,
        preferences: user.preferences,
        socialLinks: user.socialLinks || {},
        accessibilityPrefs: user.accessibilityPrefs || {},
    };
}

function buildEmergencyContactResponse(contact) {
    return {
        id: contact._id,
        name: contact.name,
        phone: contact.phone,
        relationship: contact.relationship,
        app: contact.app || "all",
        priority: contact.priority || 0,
        telegramChatId: contact.telegramChatId || "",
    };
}

const emergencyContactSchema = Joi.object({
    name: Joi.string().trim().min(2).max(100).required(),
    phone: Joi.string().trim().min(5).max(30).required(),
    relationship: Joi.string().trim().max(80).allow("").default(""),
    app: Joi.string().valid("whatsapp", "telegram", "sms", "all").default("all"),
    priority: Joi.number().integer().min(0).max(100).default(0),
    telegramChatId: Joi.string().trim().max(80).allow("").default(""),
});

const emergencyContactUpdateSchema = Joi.object({
    name: Joi.string().trim().min(2).max(100),
    phone: Joi.string().trim().min(5).max(30),
    relationship: Joi.string().trim().max(80).allow(""),
    app: Joi.string().valid("whatsapp", "telegram", "sms", "all"),
    priority: Joi.number().integer().min(0).max(100),
    telegramChatId: Joi.string().trim().max(80).allow(""),
}).min(1);

const uploadsDir = process.env.VERCEL
    ? path.join("/tmp", "ishara-uploads")
    : path.join(__dirname, "..", "uploads");

if (!isCloudinaryConfigured && !fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

const localDiskStorage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadsDir);
    },
    filename: function (req, file, cb) {
        const userId = req.user.id;
        const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
        const ext = path.extname(file.originalname);
        cb(null, `profile-${userId}-${uniqueSuffix}${ext}`);
    },
});

const fileFilter = (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(
        path.extname(file.originalname).toLowerCase()
    );
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
        return cb(null, true);
    } else {
        cb(new Error("Only image files (jpeg, jpg, png, gif) are allowed"));
    }
};

const upload = multer({
    storage: isCloudinaryConfigured ? multer.memoryStorage() : localDiskStorage,
    limits: { fileSize: 2 * 1024 * 1024 },
    fileFilter: fileFilter,
});

// PUT /api/users/update-avatar
router.put(
    "/update-avatar",
    authMiddleware, // Now this is a function, not an object
    upload.single("avatar"),
    async (req, res) => {
        try {
            const user = await User.findById(req.user.id);

            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: "User not found",
                });
            }

            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    message: "No avatar file uploaded",
                });
            }

            let avatarPath;

            if (isCloudinaryConfigured) {
                if (req.file.buffer) {
                    const uploaded = await uploadAvatarBufferToCloudinary(req.file.buffer, req.user.id);
                    avatarPath = uploaded.secure_url;
                } else {
                    const uploaded = await uploadAvatarToCloudinary(req.file.path, req.user.id);
                    avatarPath = uploaded.secure_url;
                    fs.unlink(req.file.path, () => {});
                }
            } else {
                if (process.env.VERCEL) {
                    return res.status(503).json({
                        success: false,
                        message: "Avatar upload requires Cloudinary in Vercel deployment",
                    });
                }
                avatarPath = resolvePublicUrl(req, `/uploads/${req.file.filename}`);
            }

            user.profilePic = avatarPath;
            await user.save();

            return res.json({
                success: true,
                message: "Profile picture updated successfully",
                avatar: avatarPath,
                user: buildUserResponse(req, user),
            });
        } catch (error) {
            console.error("Avatar update error:", error);

            if (error.code === "LIMIT_FILE_SIZE") {
                return res.status(400).json({
                    success: false,
                    message: "File too large. Maximum size is 2MB",
                });
            }

            if (error.message.includes("Only image files")) {
                return res.status(400).json({
                    success: false,
                    message: "Only image files (jpeg, jpg, png, gif) are allowed",
                });
            }

            return res.status(500).json({
                success: false,
                message: "Server error while updating profile picture",
                error: error.message,
            });
        }
    }
);

// PUT /api/users/update-profile
router.put("/update-profile", authMiddleware, async (req, res) => {
    try {
        const { name, bio, disabilityType, emergencyContacts, preferences } = req.body;

        if (!name && !bio && !disabilityType && !emergencyContacts && !preferences) {
            return res.status(400).json({
                success: false,
                message: "At least one field (name, bio, disabilityType, emergencyContacts, or preferences) must be provided",
            });
        }

        const user = await User.findById(req.user.id);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        if (name !== undefined) user.name = name;
        if (bio !== undefined) user.bio = bio;
        if (disabilityType !== undefined) user.disabilityType = disabilityType;
        if (emergencyContacts !== undefined) user.emergencyContacts = emergencyContacts; // replace whole array
        if (preferences !== undefined) {
            // Replace preferences map entries
            for (const [key, val] of Object.entries(preferences)) {
                user.preferences.set(key, val);
            }
        }

        await user.save();

        return res.json({
            success: true,
            message: "Profile updated successfully",
            user: buildUserResponse(req, user),
        });
    } catch (error) {
        console.error("Profile update error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while updating profile",
            error: error.message,
        });
    }
});

// GET /api/users/profile
router.get("/profile", authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select(
            "-password -otp -otpExpiry -resetPasswordToken -resetPasswordExpiry"
        );

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        return res.json({
            success: true,
            user: buildUserResponse(req, user),
        });
    } catch (error) {
        console.error("Get profile error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while fetching profile",
            error: error.message,
        });
    }
});

// GET /api/users/profile/:userId - Public profile view
router.get("/profile/:userId", async (req, res) => {
    try {
        const user = await User.findById(req.params.userId).select(
            "name bio profilePic disabilityType"
        );

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        return res.json({
            success: true,
            user: {
                id: user._id,
                name: user.name,
                bio: user.bio,
                profilePic: resolvePublicUrl(req, user.profilePic),
                disabilityType: user.disabilityType,
            },
        });
    } catch (error) {
        console.error("Get public profile error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while fetching profile",
            error: error.message,
        });
    }
});

// GET /api/users/emergency-contacts
router.get("/emergency-contacts", authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select("emergencyContacts");

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        const contacts = (user.emergencyContacts || []).map(
            buildEmergencyContactResponse
        );

        return res.json({
            success: true,
            data: contacts,
        });
    } catch (error) {
        console.error("Get emergency contacts error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while fetching emergency contacts",
        });
    }
});

// POST /api/users/emergency-contacts
router.post("/emergency-contacts", authMiddleware, async (req, res) => {
    try {
        const { error, value } = emergencyContactSchema.validate(req.body, {
            abortEarly: false,
            stripUnknown: true,
        });

        if (error) {
            return res.status(400).json({
                success: false,
                message: "Invalid emergency contact data",
                errors: error.details.map((d) => d.message),
            });
        }

        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        user.emergencyContacts.push(value);
        await user.save();

        const createdContact = user.emergencyContacts[user.emergencyContacts.length - 1];

        return res.status(201).json({
            success: true,
            message: "Emergency contact created",
            data: buildEmergencyContactResponse(createdContact),
        });
    } catch (error) {
        console.error("Create emergency contact error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while creating emergency contact",
        });
    }
});

// PUT /api/users/emergency-contacts/:contactId
router.put("/emergency-contacts/:contactId", authMiddleware, async (req, res) => {
    try {
        const { error, value } = emergencyContactUpdateSchema.validate(req.body, {
            abortEarly: false,
            stripUnknown: true,
        });

        if (error) {
            return res.status(400).json({
                success: false,
                message: "Invalid emergency contact update data",
                errors: error.details.map((d) => d.message),
            });
        }

        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        const contact = user.emergencyContacts.id(req.params.contactId);
        if (!contact) {
            return res.status(404).json({
                success: false,
                message: "Emergency contact not found",
            });
        }

        if (value.name !== undefined) contact.name = value.name;
        if (value.phone !== undefined) contact.phone = value.phone;
        if (value.relationship !== undefined) {
            contact.relationship = value.relationship;
        }

        await user.save();

        return res.json({
            success: true,
            message: "Emergency contact updated",
            data: buildEmergencyContactResponse(contact),
        });
    } catch (error) {
        console.error("Update emergency contact error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while updating emergency contact",
        });
    }
});

// DELETE /api/users/emergency-contacts/:contactId
router.delete("/emergency-contacts/:contactId", authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        const contact = user.emergencyContacts.id(req.params.contactId);
        if (!contact) {
            return res.status(404).json({
                success: false,
                message: "Emergency contact not found",
            });
        }

        contact.deleteOne();
        await user.save();

        return res.json({
            success: true,
            message: "Emergency contact deleted",
        });
    } catch (error) {
        console.error("Delete emergency contact error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while deleting emergency contact",
        });
    }
});

module.exports = router;
