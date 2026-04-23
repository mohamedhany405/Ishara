function requireRole(...roles) {
  const allowed = new Set(roles);
  return function roleMiddleware(req, res, next) {
    const role = req.user?.role;
    if (!role || !allowed.has(role)) {
      return res.status(403).json({ message: "Access denied." });
    }
    next();
  };
}

module.exports = { requireRole };
