const express = require("express");
const router = express.Router();
const Review = require("../models/Review");
const Product = require("../models/Product");
const { authMiddleware } = require("../middleware/authMiddleware");

async function recomputeProductRating(productId) {
    const reviews = await Review.find({ productId });
    if (reviews.length === 0) {
        await Product.findByIdAndUpdate(productId, { ratingAvg: 0, ratingCount: 0 });
        return;
    }
    const avg = reviews.reduce((s, r) => s + r.rating, 0) / reviews.length;
    await Product.findByIdAndUpdate(productId, {
        ratingAvg: Math.round(avg * 10) / 10,
        ratingCount: reviews.length,
    });
}

router.get("/product/:productId", async (req, res) => {
    try {
        const reviews = await Review.find({ productId: req.params.productId }).sort({ createdAt: -1 });
        res.json({ reviews });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});

router.post("/product/:productId", authMiddleware, async (req, res) => {
    try {
        const { rating, comment } = req.body;
        if (!rating || rating < 1 || rating > 5) return res.status(400).json({ message: "Rating 1-5 required" });
        const review = await Review.findOneAndUpdate(
            { productId: req.params.productId, userId: req.user.id },
            { rating, comment, userName: req.user.name || "User" },
            { upsert: true, new: true }
        );
        await recomputeProductRating(req.params.productId);
        res.status(201).json({ review });
    } catch (e) {
        res.status(400).json({ message: e.message });
    }
});

router.delete("/:id", authMiddleware, async (req, res) => {
    try {
        const review = await Review.findById(req.params.id);
        if (!review) return res.status(404).json({ message: "Not found" });
        if (review.userId.toString() !== req.user.id && req.user.role !== "admin")
            return res.status(403).json({ message: "Forbidden" });
        const productId = review.productId;
        await review.deleteOne();
        await recomputeProductRating(productId);
        res.json({ ok: true });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});

module.exports = router;
