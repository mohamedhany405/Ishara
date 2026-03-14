const mongoose = require("mongoose");

const ContactMessageSchema = new mongoose.Schema(
    {
        name: { type: String, required: true },
        email: { type: String, required: true },
        subject: { type: String, required: true },
        message: { type: String, required: true },
        read: { type: Boolean, default: false },
    },
    { timestamps: true }
);

const ContactMessage =
    mongoose.models.ContactMessage ||
    mongoose.model("ContactMessage", ContactMessageSchema);

module.exports = ContactMessage;
