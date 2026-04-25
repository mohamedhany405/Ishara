const mongoose = require("mongoose");

const ProductSchema = new mongoose.Schema(
    {
        sku: { type: String, required: true, unique: true },
        title: { ar: { type: String, default: "" }, en: { type: String, default: "" } },
        description: { ar: { type: String, default: "" }, en: { type: String, default: "" } },
        price: { type: Number, required: true, min: 0 },
        currency: { type: String, default: "EGP" },
        images: { type: [String], default: [] },
        category: { type: String, default: "general" },
        tags: { type: [String], default: [] },
        stock: { type: Number, default: 999 },
        ratingAvg: { type: Number, default: 0 },
        ratingCount: { type: Number, default: 0 },
        vendorWhatsapp: { type: String, default: "" },
        active: { type: Boolean, default: true },
    },
    { timestamps: true }
);

ProductSchema.index({ category: 1, active: 1 });
ProductSchema.index({ tags: 1 });

module.exports = mongoose.models.Product || mongoose.model("Product", ProductSchema);
