const mongoose = require("mongoose");

const LessonSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 160 },
    description: { type: String, default: "", trim: true, maxlength: 2000 },
    category: {
      type: String,
      default: "beginner",
      trim: true,
      lowercase: true,
      index: true,
    },
    videoUrl: { type: String, default: "", trim: true },
    thumbnailUrl: { type: String, default: "", trim: true },
    durationSeconds: { type: Number, min: 0 },
    isPublished: { type: Boolean, default: true, index: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  },
  { timestamps: true }
);

LessonSchema.index({ category: 1, isPublished: 1, createdAt: -1 });

const Lesson = mongoose.models.Lesson || mongoose.model("Lesson", LessonSchema);

module.exports = Lesson;
