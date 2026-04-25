const express = require("express");
const router = express.Router();
const User = require("../models/User");
const Product = require("../models/Product");
const Order = require("../models/Order");
const { authMiddleware } = require("../middleware/authMiddleware");

router.use(authMiddleware);

router.post("/checkout", async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user.cart || user.cart.length === 0) return res.status(400).json({ message: "Cart empty" });
        const ids = user.cart.map((c) => c.productId);
        const products = await Product.find({ _id: { $in: ids } });
        const map = new Map(products.map((p) => [p._id.toString(), p]));
        const items = user.cart.map((c) => {
            const p = map.get(c.productId.toString());
            return { productId: c.productId, title: p.title.en || p.title.ar || "", price: p.price, qty: c.qty };
        });
        const subtotal = items.reduce((s, i) => s + i.price * i.qty, 0);
        const order = await Order.create({
            userId: user._id,
            items,
            subtotal,
            total: subtotal,
            currency: products[0]?.currency || "EGP",
            shippingAddress: req.body.shippingAddress || "",
        });
        // WhatsApp deep-link the vendor (for demo checkout)
        const vendor = products[0]?.vendorWhatsapp || process.env.VENDOR_WHATSAPP || "";
        const summary = items
            .map((i) => `• ${i.title} x${i.qty} = ${i.price * i.qty} EGP`)
            .join("\n");
        const text = encodeURIComponent(
            `طلب جديد من ${user.name}\n\n${summary}\n\nالإجمالي: ${subtotal} EGP\n${
                req.body.shippingAddress ? `العنوان: ${req.body.shippingAddress}` : ""
            }`
        );
        const whatsappUrl = vendor ? `https://wa.me/${vendor.replace(/[^\d]/g, "")}?text=${text}` : "";
        order.whatsappRef = whatsappUrl;
        await order.save();
        user.cart = [];
        await user.save();
        res.status(201).json({ order, whatsappUrl });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});

router.get("/", async (req, res) => {
    const orders = await Order.find({ userId: req.user.id }).sort({ createdAt: -1 });
    res.json({ orders });
});

router.get("/:id", async (req, res) => {
    const order = await Order.findOne({ _id: req.params.id, userId: req.user.id });
    if (!order) return res.status(404).json({ message: "Not found" });
    res.json({ order });
});

router.post("/:id/cancel", async (req, res) => {
    const order = await Order.findOne({ _id: req.params.id, userId: req.user.id });
    if (!order) return res.status(404).json({ message: "Not found" });
    order.status = "cancelled";
    await order.save();
    res.json({ order });
});

module.exports = router;
