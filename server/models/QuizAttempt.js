const mongoose = require("mongoose");

const QuizAttemptSchema = new mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
        mode: { type: String, enum: ["clipToWord", "wordToClip", "performSign", "matchPairs"], required: true },
        targetWord: String,
        chosenWord: String,
        correct: { type: Boolean, default: false },
        confidence: { type: Number, default: 0 },
        durationMs: { type: Number, default: 0 },
        xpAwarded: { type: Number, default: 0 },
    },
    { timestamps: true }
);

module.exports = mongoose.models.QuizAttempt || mongoose.model("QuizAttempt", QuizAttemptSchema);
