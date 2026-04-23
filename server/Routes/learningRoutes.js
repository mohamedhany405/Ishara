const express = require("express");
const Joi = require("joi");

const Lesson = require("../models/Lesson");
const DictionaryEntry = require("../models/DictionaryEntry");
const LearningProgress = require("../models/LearningProgress");
const { authMiddleware } = require("../middleware/authMiddleware");
const { requireRole } = require("../middleware/roleMiddleware");

const router = express.Router();

function parseLimit(value, fallback = 100, max = 200) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return Math.min(parsed, max);
}

function mapLesson(item) {
  return {
    id: item._id,
    title: item.title,
    description: item.description,
    category: item.category,
    videoUrl: item.videoUrl,
    thumbnailUrl: item.thumbnailUrl,
    durationSeconds: item.durationSeconds,
    isPublished: item.isPublished,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
  };
}

function mapDictionaryEntry(item) {
  return {
    id: item._id,
    wordAr: item.wordAr,
    wordEn: item.wordEn,
    description: item.description,
    category: item.category,
    videoUrl: item.videoUrl,
    isPublished: item.isPublished,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
  };
}

function mapProgress(item) {
  return {
    id: item._id,
    lessonId: item.lessonId,
    status: item.status,
    completionPercent: item.completionPercent,
    lastPositionSeconds: item.lastPositionSeconds,
    notes: item.notes,
    lastStudiedAt: item.lastStudiedAt,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
  };
}

const lessonCreateSchema = Joi.object({
  title: Joi.string().trim().min(2).max(160).required(),
  description: Joi.string().trim().allow("").max(2000).default(""),
  category: Joi.string().trim().max(60).default("beginner"),
  videoUrl: Joi.string().trim().allow("").max(1500).default(""),
  thumbnailUrl: Joi.string().trim().allow("").max(1500).default(""),
  durationSeconds: Joi.number().integer().min(0),
  isPublished: Joi.boolean().default(true),
});

const lessonUpdateSchema = Joi.object({
  title: Joi.string().trim().min(2).max(160),
  description: Joi.string().trim().allow("").max(2000),
  category: Joi.string().trim().max(60),
  videoUrl: Joi.string().trim().allow("").max(1500),
  thumbnailUrl: Joi.string().trim().allow("").max(1500),
  durationSeconds: Joi.number().integer().min(0),
  isPublished: Joi.boolean(),
}).min(1);

const dictionaryCreateSchema = Joi.object({
  wordAr: Joi.string().trim().min(1).max(120).required(),
  wordEn: Joi.string().trim().min(1).max(120).required(),
  description: Joi.string().trim().allow("").max(2000).default(""),
  category: Joi.string().trim().max(60).default("daily"),
  videoUrl: Joi.string().trim().allow("").max(1500).default(""),
  isPublished: Joi.boolean().default(true),
});

const dictionaryUpdateSchema = Joi.object({
  wordAr: Joi.string().trim().min(1).max(120),
  wordEn: Joi.string().trim().min(1).max(120),
  description: Joi.string().trim().allow("").max(2000),
  category: Joi.string().trim().max(60),
  videoUrl: Joi.string().trim().allow("").max(1500),
  isPublished: Joi.boolean(),
}).min(1);

const progressUpsertSchema = Joi.object({
  completionPercent: Joi.number().min(0).max(100),
  status: Joi.string().valid("not_started", "in_progress", "completed"),
  lastPositionSeconds: Joi.number().min(0),
  notes: Joi.string().trim().allow("").max(500),
}).min(1);

router.get("/lessons", async (req, res) => {
  try {
    const query = { isPublished: true };

    const category = (req.query.category || "").toString().trim();
    if (category) {
      query.category = category.toLowerCase();
    }

    const q = (req.query.q || "").toString().trim();
    if (q) {
      const pattern = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      query.$or = [{ title: pattern }, { description: pattern }];
    }

    const lessons = await Lesson.find(query)
      .sort({ createdAt: -1 })
      .limit(parseLimit(req.query.limit, 100, 300))
      .lean();

    return res.json({ success: true, data: lessons.map(mapLesson) });
  } catch (error) {
    console.error("Get lessons error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

router.get("/dictionary", async (req, res) => {
  try {
    const query = { isPublished: true };

    const category = (req.query.category || "").toString().trim();
    if (category) {
      query.category = category.toLowerCase();
    }

    const q = (req.query.q || "").toString().trim();
    if (q) {
      const pattern = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      query.$or = [{ wordAr: pattern }, { wordEn: pattern }, { description: pattern }];
    }

    const entries = await DictionaryEntry.find(query)
      .sort({ updatedAt: -1 })
      .limit(parseLimit(req.query.limit, 150, 500))
      .lean();

    return res.json({ success: true, data: entries.map(mapDictionaryEntry) });
  } catch (error) {
    console.error("Get dictionary error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

router.post("/lessons", authMiddleware, requireRole("admin"), async (req, res) => {
  try {
    const { error, value } = lessonCreateSchema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      return res.status(400).json({
        message: "Invalid lesson payload",
        errors: error.details.map((d) => d.message),
      });
    }

    const created = await Lesson.create({
      ...value,
      createdBy: req.user.id,
      updatedBy: req.user.id,
    });

    return res.status(201).json({
      success: true,
      message: "Lesson created",
      data: mapLesson(created.toObject()),
    });
  } catch (error) {
    console.error("Create lesson error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

router.put(
  "/lessons/:lessonId",
  authMiddleware,
  requireRole("admin"),
  async (req, res) => {
    try {
      const { error, value } = lessonUpdateSchema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        return res.status(400).json({
          message: "Invalid lesson payload",
          errors: error.details.map((d) => d.message),
        });
      }

      const updated = await Lesson.findByIdAndUpdate(
        req.params.lessonId,
        {
          $set: {
            ...value,
            updatedBy: req.user.id,
          },
        },
        { returnDocument: "after", runValidators: true }
      );

      if (!updated) {
        return res.status(404).json({ message: "Lesson not found" });
      }

      return res.json({
        success: true,
        message: "Lesson updated",
        data: mapLesson(updated.toObject()),
      });
    } catch (error) {
      console.error("Update lesson error:", error);
      return res.status(500).json({ message: "Internal server error" });
    }
  }
);

router.delete(
  "/lessons/:lessonId",
  authMiddleware,
  requireRole("admin"),
  async (req, res) => {
    try {
      const lesson = await Lesson.findByIdAndDelete(req.params.lessonId);
      if (!lesson) {
        return res.status(404).json({ message: "Lesson not found" });
      }

      await LearningProgress.deleteMany({ lessonId: req.params.lessonId });

      return res.json({ success: true, message: "Lesson deleted" });
    } catch (error) {
      console.error("Delete lesson error:", error);
      return res.status(500).json({ message: "Internal server error" });
    }
  }
);

router.post(
  "/dictionary",
  authMiddleware,
  requireRole("admin"),
  async (req, res) => {
    try {
      const { error, value } = dictionaryCreateSchema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        return res.status(400).json({
          message: "Invalid dictionary payload",
          errors: error.details.map((d) => d.message),
        });
      }

      const created = await DictionaryEntry.create({
        ...value,
        createdBy: req.user.id,
        updatedBy: req.user.id,
      });

      return res.status(201).json({
        success: true,
        message: "Dictionary entry created",
        data: mapDictionaryEntry(created.toObject()),
      });
    } catch (error) {
      console.error("Create dictionary entry error:", error);
      return res.status(500).json({ message: "Internal server error" });
    }
  }
);

router.put(
  "/dictionary/:entryId",
  authMiddleware,
  requireRole("admin"),
  async (req, res) => {
    try {
      const { error, value } = dictionaryUpdateSchema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        return res.status(400).json({
          message: "Invalid dictionary payload",
          errors: error.details.map((d) => d.message),
        });
      }

      const updated = await DictionaryEntry.findByIdAndUpdate(
        req.params.entryId,
        {
          $set: {
            ...value,
            updatedBy: req.user.id,
          },
        },
        { returnDocument: "after", runValidators: true }
      );

      if (!updated) {
        return res.status(404).json({ message: "Dictionary entry not found" });
      }

      return res.json({
        success: true,
        message: "Dictionary entry updated",
        data: mapDictionaryEntry(updated.toObject()),
      });
    } catch (error) {
      console.error("Update dictionary entry error:", error);
      return res.status(500).json({ message: "Internal server error" });
    }
  }
);

router.delete(
  "/dictionary/:entryId",
  authMiddleware,
  requireRole("admin"),
  async (req, res) => {
    try {
      const entry = await DictionaryEntry.findByIdAndDelete(req.params.entryId);
      if (!entry) {
        return res.status(404).json({ message: "Dictionary entry not found" });
      }

      return res.json({ success: true, message: "Dictionary entry deleted" });
    } catch (error) {
      console.error("Delete dictionary entry error:", error);
      return res.status(500).json({ message: "Internal server error" });
    }
  }
);

router.get("/progress", authMiddleware, async (req, res) => {
  try {
    const query = { userId: req.user.id };
    const status = (req.query.status || "").toString().trim();
    if (status) {
      query.status = status;
    }

    const progress = await LearningProgress.find(query)
      .sort({ updatedAt: -1 })
      .limit(parseLimit(req.query.limit, 150, 500))
      .lean();

    return res.json({ success: true, data: progress.map(mapProgress) });
  } catch (error) {
    console.error("Get learning progress error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

router.get("/progress/:lessonId", authMiddleware, async (req, res) => {
  try {
    const progress = await LearningProgress.findOne({
      userId: req.user.id,
      lessonId: req.params.lessonId,
    }).lean();

    if (!progress) {
      return res.status(404).json({ message: "Progress not found" });
    }

    return res.json({ success: true, data: mapProgress(progress) });
  } catch (error) {
    console.error("Get lesson progress error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

router.put("/progress/:lessonId", authMiddleware, async (req, res) => {
  try {
    const { error, value } = progressUpsertSchema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      return res.status(400).json({
        message: "Invalid learning progress payload",
        errors: error.details.map((d) => d.message),
      });
    }

    const payload = { ...value, lastStudiedAt: new Date() };

    if (payload.status === "completed" && payload.completionPercent == null) {
      payload.completionPercent = 100;
    }

    if (payload.completionPercent != null && payload.completionPercent >= 100) {
      payload.status = "completed";
    }

    const updated = await LearningProgress.findOneAndUpdate(
      {
        userId: req.user.id,
        lessonId: req.params.lessonId,
      },
      {
        $set: payload,
        $setOnInsert: {
          lessonId: req.params.lessonId,
          userId: req.user.id,
        },
      },
      {
        upsert: true,
        returnDocument: "after",
        runValidators: true,
      }
    );

    return res.json({
      success: true,
      message: "Progress saved",
      data: mapProgress(updated.toObject()),
    });
  } catch (error) {
    console.error("Upsert learning progress error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

router.delete("/progress/:lessonId", authMiddleware, async (req, res) => {
  try {
    const removed = await LearningProgress.findOneAndDelete({
      userId: req.user.id,
      lessonId: req.params.lessonId,
    });

    if (!removed) {
      return res.status(404).json({ message: "Progress not found" });
    }

    return res.json({ success: true, message: "Progress deleted" });
  } catch (error) {
    console.error("Delete learning progress error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
});

module.exports = router;
