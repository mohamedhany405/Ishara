const express = require("express");
const router = express.Router();
const User = require("../models/User");
const Product = require("../models/Product");
const { authMiddleware } = require("../middleware/authMiddleware");

router.use(authMiddleware);

async function expandCart(user) {
    const cart = user.cart || [];
    const ids = cart.map((c) => c.productId).filter(Boolean);
    const products = await Product.find({ _id: { $in: ids } });
    const map = new Map(products.map((p) => [p._id.toString(), p]));
    return cart
        .map((item) => {
            const p = map.get(item.productId.toString());
            if (!p) return null;
            return {
                productId: p._id,
                qty: item.qty,
                title: p.title,
                price: p.price,
                currency: p.currency,
                image: (p.images && p.images[0]) || "",
            };
        })
        .filter(Boolean);
}

router.get("/", async (req, res) => {
    const user = await User.findById(req.user.id);
    res.json({ items: await expandCart(user) });
});

router.post("/", async (req, res) => {
    const { productId, qty = 1 } = req.body;
    if (!productId) return res.status(400).json({ message: "productId required" });
    const user = await User.findById(req.user.id);
    const existing = user.cart.find((c) => c.productId.toString() === productId);
    if (existing) {
        existing.qty = Math.max(1, existing.qty + qty);
    } else {
        user.cart.push({ productId, qty });
    }
    await user.save();
    res.json({ items: await expandCart(user) });
});

router.put("/:productId", async (req, res) => {
    const { qty } = req.body;
    const user = await User.findById(req.user.id);
    const item = user.cart.find((c) => c.productId.toString() === req.params.productId);
    if (!item) return res.status(404).json({ message: "Not in cart" });
    if (qty <= 0) {
        user.cart = user.cart.filter((c) => c.productId.toString() !== req.params.productId);
    } else {
        item.qty = qty;
    }
    await user.save();
    res.json({ items: await expandCart(user) });
});

router.delete("/:productId", async (req, res) => {
    const user = await User.findById(req.user.id);
    user.cart = user.cart.filter((c) => c.productId.toString() !== req.params.productId);
    await user.save();
    res.json({ items: await expandCart(user) });
});

router.delete("/", async (req, res) => {
    const user = await User.findById(req.user.id);
    user.cart = [];
    await user.save();
    res.json({ items: [] });
});

module.exports = router;
