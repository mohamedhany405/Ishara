const express = require("express");
const router = express.Router();
const User = require("../models/User");
const { authMiddleware } = require("../middleware/authMiddleware");

router.use(authMiddleware);

router.get("/", async (req, res) => {
    const u = await User.findById(req.user.id);
    res.json({ prefs: u.accessibilityPrefs || {} });
});

router.put("/", async (req, res) => {
    const set = {};
    const allowed = [
        "autoTts",
        "highContrast",
        "colorBlindMode",
        "dyslexiaFont",
        "textScale",
        "motorMode",
        "reduceMotion",
        "hapticsOnEveryAction",
        "signLangPreferred",
        "vibrationLevel",
        "ttsVoice",
        "ttsRate",
    ];
    for (const k of allowed) if (req.body[k] !== undefined) set[`accessibilityPrefs.${k}`] = req.body[k];
    const u = await User.findByIdAndUpdate(req.user.id, { $set: set }, { new: true });
    res.json({ prefs: u.accessibilityPrefs });
});

module.exports = router;
