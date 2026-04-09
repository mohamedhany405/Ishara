const { app, ensureDbConnection } = require("../app");

module.exports = async (req, res) => {
  try {
    await ensureDbConnection();
    return app(req, res);
  } catch (error) {
    console.error("Serverless bootstrap error:", error.message);
    return res.status(500).json({ message: "Server bootstrap failed" });
  }
};
