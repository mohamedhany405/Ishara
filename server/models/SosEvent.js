const mongoose = require("mongoose");

const SosEventSchema = new mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
        triggeredBy: { type: String, enum: ["app_button", "hardware", "auto", "tripleTap"], default: "app_button" },
        location: {
            lat: Number,
            lng: Number,
            accuracy: Number,
            mapsUrl: String,
        },
        message: { type: String, default: "" },
        recipients: [
            {
                contactId: String,
                name: String,
                phone: String,
                channels: [String],
                whatsappStatus: { type: String, default: "pending" },
                telegramStatus: { type: String, default: "pending" },
                smsStatus: { type: String, default: "pending" },
                error: String,
            },
        ],
        cancelled: { type: Boolean, default: false },
    },
    { timestamps: true }
);

module.exports = mongoose.models.SosEvent || mongoose.model("SosEvent", SosEventSchema);
