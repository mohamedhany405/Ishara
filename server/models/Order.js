const mongoose = require("mongoose");

const OrderSchema = new mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
        items: [
            {
                productId: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true },
                title: String,
                price: Number,
                qty: Number,
            },
        ],
        subtotal: { type: Number, default: 0 },
        total: { type: Number, default: 0 },
        currency: { type: String, default: "EGP" },
        status: { type: String, enum: ["pending", "confirmed", "shipped", "delivered", "cancelled"], default: "pending" },
        whatsappRef: { type: String, default: "" },
        shippingAddress: { type: String, default: "" },
    },
    { timestamps: true }
);

module.exports = mongoose.models.Order || mongoose.model("Order", OrderSchema);
