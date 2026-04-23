// models/User.js
const mongoose = require("mongoose");

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

        // profile - FIX: Changed 'profilepic' to 'profilePic' (camelCase consistency)
        name: { type: String, required: true },
        profilePic: { type: String, default: "" }, // Set dynamically in register handler via ui-avatars.com
        bio: { type: String, default: "" },

        // Ishara-specific fields
        disabilityType: {
            type: String,
            enum: ["deaf", "non-verbal", "blind", "hearing"],
            required: true,
            default: "hearing",
        },
        emergencyContacts: [
            {
                name: String,
                phone: String,
                relationship: String,
            },
        ],
        preferences: {
            type: Map,
            of: mongoose.Schema.Types.Mixed,
            default: () =>
                new Map([
                    ["vibrationLevel", 3],
                    ["fontSize", "medium"],
                    ["highContrast", false],
                    ["ttsVoice", "default"],
                ]),
        },
    },
    { timestamps: true }
);

UserSchema.index({ role: 1, createdAt: -1 });
UserSchema.index({ isVerified: 1, createdAt: -1 });

// Prevent model overwrite error
const User = mongoose.models.User || mongoose.model("User", UserSchema);

module.exports = User;
