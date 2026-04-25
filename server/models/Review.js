const mongoose = require("mongoose");

const ReviewSchema = new mongoose.Schema(
    {
        productId: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true, index: true },
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
        userName: { type: String, default: "" },
        rating: { type: Number, min: 1, max: 5, required: true },
        comment: { type: String, default: "" },
    },
    { timestamps: true }
);

ReviewSchema.index({ productId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.models.Review || mongoose.model("Review", ReviewSchema);
