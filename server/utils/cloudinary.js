const { v2: cloudinary } = require("cloudinary");

const isCloudinaryConfigured = Boolean(
  process.env.CLOUDINARY_CLOUD_NAME &&
    process.env.CLOUDINARY_API_KEY &&
    process.env.CLOUDINARY_API_SECRET
);

if (isCloudinaryConfigured) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true,
  });
}

async function uploadAvatarToCloudinary(localFilePath, userId) {
  if (!isCloudinaryConfigured) {
    throw new Error("Cloudinary is not configured");
  }

  return cloudinary.uploader.upload(localFilePath, {
    folder: process.env.CLOUDINARY_FOLDER || "ishara/avatars",
    public_id: `avatar_${userId}_${Date.now()}`,
    resource_type: "image",
    overwrite: true,
    transformation: [{ width: 512, height: 512, crop: "limit" }],
  });
}

module.exports = {
  isCloudinaryConfigured,
  uploadAvatarToCloudinary,
};
