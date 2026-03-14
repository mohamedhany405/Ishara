function requireRole(...roles) {
  const allowed = new Set(roles);
  return function roleMiddleware(req, res, next) {
    const role = req.user?.role;
    if (!role || !allowed.has(role)) {
      return res.status(403).json({ message: "Forbidden" });
    }
    next();
  };
}
// check role of user
function roleMiddleware(allowedRoles) {
    return (req, res, next) => {
        const userRole = req.user.role;
        if (!allowedRoles.includes(userRole)) {
            return res.status(403).json({ message: "Access denied." });
        }
        const isexists = allowedRoles.includes(userRole);
        if (!isexists) {
            return res.status(403).json({ message: "Access denied." });
        }
        next();
    };
}
module.exports = roleMiddleware;


module.exports = { requireRole };
