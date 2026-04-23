const mongoose = require("mongoose");

const DictionaryEntrySchema = new mongoose.Schema(
  {
    wordAr: { type: String, required: true, trim: true, maxlength: 120 },
    wordEn: { type: String, required: true, trim: true, maxlength: 120 },
    description: { type: String, default: "", trim: true, maxlength: 2000 },
    category: {
      type: String,
      default: "daily",
      trim: true,
      lowercase: true,
      index: true,
    },
    videoUrl: { type: String, default: "", trim: true },
    isPublished: { type: Boolean, default: true, index: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  },
  { timestamps: true }
);

DictionaryEntrySchema.index({ category: 1, isPublished: 1, updatedAt: -1 });

const DictionaryEntry =
  mongoose.models.DictionaryEntry ||
  mongoose.model("DictionaryEntry", DictionaryEntrySchema);

module.exports = DictionaryEntry;
