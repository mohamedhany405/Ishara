function trimTrailingSlash(value) {
  return (value || "").replace(/\/+$/, "");
}

function getFrontendBaseUrl() {
  return trimTrailingSlash(
    process.env.FRONTEND_URL || process.env.CLIENT_ORIGIN || "http://localhost:3000"
  );
}

function getBackendBaseUrl(req) {
  const configured = trimTrailingSlash(process.env.BACKEND_PUBLIC_URL || "");

  if (configured) {
    return /^https?:\/\//i.test(configured) ? configured : `https://${configured}`;
  }

  const vercelUrl = trimTrailingSlash(process.env.VERCEL_URL || "");
  if (vercelUrl) {
    return `https://${vercelUrl}`;
  }

  return `${req.protocol}://${req.get("host")}`;
}

function resolvePublicUrl(req, value) {
  if (!value) return "";
  if (/^https?:\/\//i.test(value)) return value;

  const normalizedPath = value.startsWith("/") ? value : `/${value}`;
  return `${getBackendBaseUrl(req)}${normalizedPath}`;
}

module.exports = {
  getFrontendBaseUrl,
  getBackendBaseUrl,
  resolvePublicUrl,
};
