const express = require("express");
const router = express.Router();
const QuizAttempt = require("../models/QuizAttempt");
const { authMiddleware } = require("../middleware/authMiddleware");

router.use(authMiddleware);

router.post("/", async (req, res) => {
    try {
        const { mode, targetWord, chosenWord, correct, confidence = 0, durationMs = 0 } = req.body;
        const xpAwarded = correct ? (mode === "performSign" ? 20 : 10) : 2;
        const attempt = await QuizAttempt.create({
            userId: req.user.id,
            mode,
            targetWord,
            chosenWord,
            correct: !!correct,
            confidence,
            durationMs,
            xpAwarded,
        });
        res.status(201).json({ attempt });
    } catch (e) {
        res.status(400).json({ message: e.message });
    }
});

router.get("/me", async (req, res) => {
    const attempts = await QuizAttempt.find({ userId: req.user.id }).sort({ createdAt: -1 }).limit(200);
    const xp = attempts.reduce((s, a) => s + (a.xpAwarded || 0), 0);
    const correct = attempts.filter((a) => a.correct).length;
    // Streak: consecutive distinct days with at least one correct attempt
    const days = new Set(attempts.filter((a) => a.correct).map((a) => a.createdAt.toISOString().slice(0, 10)));
    let streak = 0;
    const today = new Date();
    for (let i = 0; i < 60; i++) {
        const d = new Date(today);
        d.setDate(today.getDate() - i);
        if (days.has(d.toISOString().slice(0, 10))) streak++;
        else if (i > 0) break;
    }
    res.json({ xp, total: attempts.length, correct, streak, attempts });
});

module.exports = router;
