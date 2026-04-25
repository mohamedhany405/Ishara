const express = require("express");
const router = express.Router();
const { authMiddleware } = require("../middleware/authMiddleware");

const SYSTEM_PROMPT = `You are the Ishara Assistant — a helpful, concise guide for the Ishara accessibility app.
Ishara helps deaf, blind, and non-verbal users in Egypt with:
- Sign language translation (camera → Arabic text + speech), and Arabic text → sign clips
- Vision: Egyptian currency totaling, fine-grained object naming with TTS, OCR (English + Arabic)
- Multi-contact emergency SOS with silent SMS + WhatsApp + Telegram and live location
- Learning Hub with Arabic Sign Language clips and a Duolingo-style quiz
- Hardware glasses (ESP32) pairing for obstacle detection and SOS button
- Shop for accessibility products
- Accessibility settings: auto-TTS, high contrast, color-blind palettes, dyslexia font, large text, motor mode
You answer in the user's language (Arabic or English) and keep replies short.
For navigation hints, append a tag like [open:translator] [open:vision] [open:safety] [open:learning] [open:shop] [open:profile/accessibility] [open:profile/contacts] [open:assistant].`;

router.post("/ask", authMiddleware, async (req, res) => {
    try {
        const { messages = [] } = req.body;
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
            // Local fallback rule-based assistant
            const last = (messages[messages.length - 1]?.content || "").toLowerCase();
            const reply = ruleBased(last);
            return res.json({ reply, source: "local" });
        }
        const contents = messages.map((m) => ({
            role: m.role === "assistant" ? "model" : "user",
            parts: [{ text: m.content }],
        }));
        const body = {
            systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
            contents,
            generationConfig: { temperature: 0.4, maxOutputTokens: 512 },
        };
        const r = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
            { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) }
        );
        const data = await r.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || "";
        if (!text) {
            const last = (messages[messages.length - 1]?.content || "").toLowerCase();
            return res.json({ reply: ruleBased(last), source: "local-fallback" });
        }
        res.json({ reply: text, source: "gemini" });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});

function ruleBased(q) {
    if (!q) return "Hello! Ask me how to use any feature of Ishara.";
    if (q.includes("contact") || q.includes("جهة"))
        return "Open Profile → Emergency Contacts to add or remove people. [open:profile/contacts]";
    if (q.includes("sos") || q.includes("emergency") || q.includes("ساعد"))
        return "Tap the big red SOS on the Safety tab. A 5-second countdown starts; cancel by shaking. [open:safety]";
    if (q.includes("tts") || q.includes("speech") || q.includes("صوت"))
        return "Open Profile → Accessibility and turn on Auto-TTS. [open:profile/accessibility]";
    if (q.includes("translate") || q.includes("ترجم"))
        return "Open Translator and start the camera to translate signs. [open:translator]";
    if (q.includes("currency") || q.includes("جنيه") || q.includes("money"))
        return "Open Vision → Currency to count Egyptian Pounds and piasters in real time. [open:vision]";
    if (q.includes("learn") || q.includes("تعلم"))
        return "Open Learning Hub. Tap a word to play its sign clip; finish quizzes to earn XP. [open:learning]";
    if (q.includes("shop") || q.includes("متجر"))
        return "Open Shop to browse accessibility products. [open:shop]";
    return "I can help with the translator, vision, safety SOS, learning, shop, and accessibility settings. Tell me which one.";
}

module.exports = router;
