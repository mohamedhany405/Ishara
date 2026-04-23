const mongoose = require("mongoose");

const LearningProgressSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    lessonId: { type: String, required: true, trim: true },
    completionPercent: { type: Number, min: 0, max: 100, default: 0 },
    status: {
      type: String,
      enum: ["not_started", "in_progress", "completed"],
      default: "not_started",
    },
    lastPositionSeconds: { type: Number, min: 0, default: 0 },
    notes: { type: String, default: "", maxlength: 500 },
    lastStudiedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

LearningProgressSchema.index({ userId: 1, lessonId: 1 }, { unique: true });
LearningProgressSchema.index({ userId: 1, updatedAt: -1 });

const LearningProgress =
  mongoose.models.LearningProgress ||
  mongoose.model("LearningProgress", LearningProgressSchema);

module.exports = LearningProgress;
