// Twilio (WhatsApp + SMS fallback) and Telegram bot dispatchers.
// Configure via env: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_WHATSAPP_FROM,
// TWILIO_SMS_FROM, TELEGRAM_BOT_TOKEN.
//
// All functions return { ok, error } and never throw, so SOS dispatch is best-effort.

async function sendWhatsAppViaTwilio({ to, message }) {
    try {
        const sid = process.env.TWILIO_ACCOUNT_SID;
        const token = process.env.TWILIO_AUTH_TOKEN;
        const from = process.env.TWILIO_WHATSAPP_FROM; // e.g. "whatsapp:+14155238886"
        if (!sid || !token || !from) return { ok: false, error: "twilio_not_configured" };
        const params = new URLSearchParams({
            To: `whatsapp:${normalizePhone(to)}`,
            From: from,
            Body: message,
        });
        const r = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`, {
            method: "POST",
            headers: {
                Authorization: "Basic " + Buffer.from(`${sid}:${token}`).toString("base64"),
                "Content-Type": "application/x-www-form-urlencoded",
            },
            body: params.toString(),
        });
        const data = await r.json();
        return { ok: r.ok, error: r.ok ? null : data.message || "twilio_error", sid: data.sid };
    } catch (e) {
        return { ok: false, error: e.message };
    }
}

async function sendSmsViaTwilio({ to, message }) {
    try {
        const sid = process.env.TWILIO_ACCOUNT_SID;
        const token = process.env.TWILIO_AUTH_TOKEN;
        const from = process.env.TWILIO_SMS_FROM;
        if (!sid || !token || !from) return { ok: false, error: "twilio_sms_not_configured" };
        const params = new URLSearchParams({ To: normalizePhone(to), From: from, Body: message });
        const r = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`, {
            method: "POST",
            headers: {
                Authorization: "Basic " + Buffer.from(`${sid}:${token}`).toString("base64"),
                "Content-Type": "application/x-www-form-urlencoded",
            },
            body: params.toString(),
        });
        const data = await r.json();
        return { ok: r.ok, error: r.ok ? null : data.message || "twilio_error", sid: data.sid };
    } catch (e) {
        return { ok: false, error: e.message };
    }
}

async function sendTelegramMessage({ chatId, message }) {
    try {
        const token = process.env.TELEGRAM_BOT_TOKEN;
        if (!token || !chatId) return { ok: false, error: "telegram_not_configured" };
        const r = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ chat_id: chatId, text: message }),
        });
        const data = await r.json();
        return { ok: r.ok && data.ok, error: data.ok ? null : data.description };
    } catch (e) {
        return { ok: false, error: e.message };
    }
}

function normalizePhone(p) {
    const digits = (p || "").replace(/[^\d+]/g, "");
    if (!digits) return "";
    if (digits.startsWith("+")) return digits;
    // Egyptian numbers: 01xxxxxxxxx → +201xxxxxxxxx
    if (digits.startsWith("0") && digits.length === 11) return "+20" + digits.slice(1);
    return "+" + digits;
}

module.exports = { sendWhatsAppViaTwilio, sendSmsViaTwilio, sendTelegramMessage, normalizePhone };
