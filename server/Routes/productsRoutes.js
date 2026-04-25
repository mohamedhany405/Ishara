const express = require("express");
const router = express.Router();
const Product = require("../models/Product");
const { authMiddleware } = require("../middleware/authMiddleware");

router.get("/", async (req, res) => {
    try {
        const { category, q, limit = 50 } = req.query;
        const filter = { active: true };
        if (category) filter.category = category;
        if (q) {
            filter.$or = [
                { "title.en": new RegExp(q, "i") },
                { "title.ar": new RegExp(q, "i") },
                { tags: new RegExp(q, "i") },
            ];
        }
        const products = await Product.find(filter).limit(parseInt(limit)).sort({ createdAt: -1 });
        res.json({ products });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});

router.get("/:id", async (req, res) => {
    try {
        const product = await Product.findById(req.params.id);
        if (!product) return res.status(404).json({ message: "Not found" });
        res.json({ product });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});

// Admin-only create / update / delete
router.post("/", authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== "admin") return res.status(403).json({ message: "Forbidden" });
        const product = await Product.create(req.body);
        res.status(201).json({ product });
    } catch (e) {
        res.status(400).json({ message: e.message });
    }
});

router.put("/:id", authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== "admin") return res.status(403).json({ message: "Forbidden" });
        const product = await Product.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.json({ product });
    } catch (e) {
        res.status(400).json({ message: e.message });
    }
});

router.delete("/:id", authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== "admin") return res.status(403).json({ message: "Forbidden" });
        await Product.findByIdAndDelete(req.params.id);
        res.json({ ok: true });
    } catch (e) {
        res.status(400).json({ message: e.message });
    }
});

module.exports = router;
