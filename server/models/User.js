// models/User.js
const mongoose = require("mongoose");

const EmergencyContactSchema = new mongoose.Schema(
    {
        name: { type: String, required: true },
        phone: { type: String, required: true },
        relationship: { type: String, default: "" },
        app: { type: String, enum: ["whatsapp", "telegram", "sms", "all"], default: "all" },
        priority: { type: Number, default: 0 },
        telegramChatId: { type: String, default: "" },
    },
    { _id: true, timestamps: false }
);

const SocialLinksSchema = new mongoose.Schema(
    {
        instagram: { type: String, default: "" },
        facebook: { type: String, default: "" },
        twitter: { type: String, default: "" },
        tiktok: { type: String, default: "" },
        whatsapp: { type: String, default: "" },
        youtube: { type: String, default: "" },
    },
    { _id: false }
);

const AccessibilityPrefsSchema = new mongoose.Schema(
    {
        autoTts: { type: Boolean, default: false },
        highContrast: { type: Boolean, default: false },
        colorBlindMode: { type: String, enum: ["none", "deuter", "protan", "tritan"], default: "none" },
        dyslexiaFont: { type: Boolean, default: false },
        textScale: { type: Number, default: 1.0, min: 0.8, max: 2.2 },
        motorMode: { type: Boolean, default: false },
        reduceMotion: { type: Boolean, default: false },
        hapticsOnEveryAction: { type: Boolean, default: false },
        signLangPreferred: { type: Boolean, default: false },
        vibrationLevel: { type: Number, default: 3, min: 0, max: 5 },
        ttsVoice: { type: String, default: "default" },
        ttsRate: { type: Number, default: 0.5, min: 0.2, max: 1.0 },
    },
    { _id: false }
);

const UserSchema = new mongoose.Schema(
    {
        // authentication
        email: { type: String, required: true, unique: true },
        password: { type: String, required: true },
        role: { type: String, enum: ["user", "admin", "supplier"], default: "user" },
        isVerified: { type: Boolean, default: false },
        otp: { type: String, maxlength: 6 },
        otpExpiry: { type: Date },
        resetPasswordToken: { type: String },
        resetPasswordExpiry: { type: Date },

        // profile
        name: { type: String, required: true },
        profilePic: { type: String, default: "" },
        bio: { type: String, default: "" },
        phone: { type: String, default: "" },

        // Ishara-specific — "hearing" removed per UX spec.
        disabilityType: {
            type: String,
            enum: ["deaf", "non-verbal", "blind", "other"],
            required: true,
            default: "deaf",
        },

        emergencyContacts: { type: [EmergencyContactSchema], default: [] },

        socialLinks: { type: SocialLinksSchema, default: () => ({}) },

        accessibilityPrefs: { type: AccessibilityPrefsSchema, default: () => ({}) },

        // Loose settings bucket for future-proofing
        preferences: {
            type: Map,
            of: mongoose.Schema.Types.Mixed,
            default: () => new Map(),
        },

        // Shop
        cart: {
            type: [
                {
                    productId: { type: mongoose.Schema.Types.ObjectId, ref: "Product" },
                    qty: { type: Number, default: 1, min: 1 },
                },
            ],
            default: [],
        },
    },
    { timestamps: true }
);

UserSchema.index({ role: 1, createdAt: -1 });
UserSchema.index({ isVerified: 1, createdAt: -1 });

const User = mongoose.models.User || mongoose.model("User", UserSchema);

module.exports = User;
