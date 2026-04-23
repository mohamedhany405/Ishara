const mongoose = require("mongoose");

const HistoryEntrySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: ["translator", "vision"],
      required: true,
      index: true,
    },
    inputText: { type: String, required: true, trim: true, maxlength: 5000 },
    outputText: { type: String, required: true, trim: true, maxlength: 5000 },
    confidence: { type: Number, min: 0, max: 1, default: 0 },
    details: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

HistoryEntrySchema.index({ userId: 1, type: 1, createdAt: -1 });

const HistoryEntry =
  mongoose.models.HistoryEntry || mongoose.model("HistoryEntry", HistoryEntrySchema);

module.exports = HistoryEntry;
