const express = require("express");
const router = express.Router();
const User = require("../models/User");
const SosEvent = require("../models/SosEvent");
const { authMiddleware } = require("../middleware/authMiddleware");
const { sendWhatsAppViaTwilio, sendSmsViaTwilio, sendTelegramMessage } = require("../services/messaging");

router.use(authMiddleware);

router.post("/", async (req, res) => {
    try {
        const { triggeredBy = "app_button", location, customMessage } = req.body || {};
        const user = await User.findById(req.user.id);
        const contacts = user.emergencyContacts || [];
        if (contacts.length === 0) return res.status(400).json({ message: "No emergency contacts" });

        const mapsUrl = location?.lat && location?.lng
            ? `https://maps.google.com/?q=${location.lat},${location.lng}`
            : "";
        const baseMsg = customMessage ||
            `🚨 SOS — ${user.name}\n${user.disabilityType ? "Disability: " + user.disabilityType + "\n" : ""}I need help.${
                mapsUrl ? "\nLocation: " + mapsUrl : ""
            }\n\n🚨 طلب مساعدة طارئ من ${user.name}. أحتاج المساعدة فوراً.${mapsUrl ? "\nالموقع: " + mapsUrl : ""}`;

        const recipients = [];
        for (const c of contacts) {
            const channels = c.app === "all" ? ["whatsapp", "telegram", "sms"] : [c.app];
            const r = {
                contactId: c._id?.toString(),
                name: c.name,
                phone: c.phone,
                channels,
                whatsappStatus: "skipped",
                telegramStatus: "skipped",
                smsStatus: "skipped",
            };
            if (channels.includes("whatsapp")) {
                const wa = await sendWhatsAppViaTwilio({ to: c.phone, message: baseMsg });
                r.whatsappStatus = wa.ok ? "sent" : "failed";
                if (!wa.ok) r.error = wa.error;
            }
            if (channels.includes("telegram") && c.telegramChatId) {
                const tg = await sendTelegramMessage({ chatId: c.telegramChatId, message: baseMsg });
                r.telegramStatus = tg.ok ? "sent" : "failed";
            }
            if (channels.includes("sms")) {
                const sms = await sendSmsViaTwilio({ to: c.phone, message: baseMsg });
                r.smsStatus = sms.ok ? "sent" : "failed";
            }
            recipients.push(r);
        }

        const evt = await SosEvent.create({
            userId: user._id,
            triggeredBy,
            location: { ...location, mapsUrl },
            message: baseMsg,
            recipients,
        });
        res.status(201).json({ event: evt });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});

router.get("/", async (req, res) => {
    const events = await SosEvent.find({ userId: req.user.id }).sort({ createdAt: -1 }).limit(50);
    res.json({ events });
});

module.exports = router;
