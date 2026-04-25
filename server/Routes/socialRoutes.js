const express = require("express");
const router = express.Router();
const User = require("../models/User");
const { authMiddleware } = require("../middleware/authMiddleware");

router.use(authMiddleware);

router.get("/", async (req, res) => {
    const u = await User.findById(req.user.id);
    res.json({ socialLinks: u.socialLinks || {} });
});

router.put("/", async (req, res) => {
    const allowed = ["instagram", "facebook", "twitter", "tiktok", "whatsapp", "youtube"];
    const update = {};
    for (const k of allowed) if (req.body[k] !== undefined) update[`socialLinks.${k}`] = (req.body[k] || "").toString();
    const u = await User.findByIdAndUpdate(req.user.id, { $set: update }, { new: true });
    res.json({ socialLinks: u.socialLinks });
});

module.exports = router;
