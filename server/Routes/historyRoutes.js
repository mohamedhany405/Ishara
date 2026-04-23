const express = require("express");
const Joi = require("joi");
const mongoose = require("mongoose");

const HistoryEntry = require("../models/HistoryEntry");
const { authMiddleware } = require("../middleware/authMiddleware");

const router = express.Router();

const createHistorySchema = Joi.object({
  inputText: Joi.string().trim().max(5000).required(),
  outputText: Joi.string().trim().max(5000).required(),
  confidence: Joi.number().min(0).max(1).default(0),
  details: Joi.object().unknown(true).default({}),
});

const updateHistorySchema = Joi.object({
  inputText: Joi.string().trim().max(5000),
  outputText: Joi.string().trim().max(5000),
  confidence: Joi.number().min(0).max(1),
  details: Joi.object().unknown(true),
}).min(1);

function parseLimit(value, fallback = 100, max = 300) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return Math.min(parsed, max);
}

function mapHistory(item) {
  return {
    id: item._id,
    type: item.type,
    inputText: item.inputText,
    outputText: item.outputText,
    confidence: item.confidence,
    details: item.details,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
  };
}

function ensureObjectId(id) {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return false;
  }
  return true;
}

function registerHistoryRoutes(type) {
  router.get(`/${type}`, authMiddleware, async (req, res) => {
    try {
      const entries = await HistoryEntry.find({
        userId: req.user.id,
        type,
      })
        .sort({ createdAt: -1 })
        .limit(parseLimit(req.query.limit, 100, 300))
        .lean();

      return res.json({ success: true, data: entries.map(mapHistory) });
    } catch (error) {
      console.error(`Get ${type} history error:`, error);
      return res.status(500).json({ message: "Internal server error" });
    }
  });

  router.post(`/${type}`, authMiddleware, async (req, res) => {
    try {
      const { error, value } = createHistorySchema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        return res.status(400).json({
          message: "Invalid history payload",
          errors: error.details.map((d) => d.message),
        });
      }

      const created = await HistoryEntry.create({
        ...value,
        type,
        userId: req.user.id,
      });

      return res.status(201).json({
        success: true,
        message: "History entry created",
        data: mapHistory(created.toObject()),
      });
    } catch (error) {
      console.error(`Create ${type} history error:`, error);
      return res.status(500).json({ message: "Internal server error" });
    }
  });

  router.put(`/${type}/:id`, authMiddleware, async (req, res) => {
    try {
      if (!ensureObjectId(req.params.id)) {
        return res.status(400).json({ message: "Invalid history entry id" });
      }

      const { error, value } = updateHistorySchema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        return res.status(400).json({
          message: "Invalid history payload",
          errors: error.details.map((d) => d.message),
        });
      }

      const updated = await HistoryEntry.findOneAndUpdate(
        {
          _id: req.params.id,
          userId: req.user.id,
          type,
        },
        {
          $set: value,
        },
        {
          returnDocument: "after",
          runValidators: true,
        }
      );

      if (!updated) {
        return res.status(404).json({ message: "History entry not found" });
      }

      return res.json({
        success: true,
        message: "History entry updated",
        data: mapHistory(updated.toObject()),
      });
    } catch (error) {
      console.error(`Update ${type} history error:`, error);
      return res.status(500).json({ message: "Internal server error" });
    }
  });

  router.delete(`/${type}/:id`, authMiddleware, async (req, res) => {
    try {
      if (!ensureObjectId(req.params.id)) {
        return res.status(400).json({ message: "Invalid history entry id" });
      }

      const deleted = await HistoryEntry.findOneAndDelete({
        _id: req.params.id,
        userId: req.user.id,
        type,
      });

      if (!deleted) {
        return res.status(404).json({ message: "History entry not found" });
      }

      return res.json({
        success: true,
        message: "History entry deleted",
      });
    } catch (error) {
      console.error(`Delete ${type} history error:`, error);
      return res.status(500).json({ message: "Internal server error" });
    }
  });
}

registerHistoryRoutes("translator");
registerHistoryRoutes("vision");

module.exports = router;
