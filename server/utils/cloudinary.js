let cloudinary;

try {
  ({ v2: cloudinary } = require("cloudinary"));
} catch (error) {
  cloudinary = null;
  console.warn("cloudinary package not found; avatar uploads will use local fallback");
}

const isCloudinaryConfigured = Boolean(
  cloudinary &&
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

async function uploadAvatarBufferToCloudinary(fileBuffer, userId) {
  if (!isCloudinaryConfigured) {
    throw new Error("Cloudinary is not configured");
  }

  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: process.env.CLOUDINARY_FOLDER || "ishara/avatars",
        public_id: `avatar_${userId}_${Date.now()}`,
        resource_type: "image",
        overwrite: true,
        transformation: [{ width: 512, height: 512, crop: "limit" }],
      },
      (error, result) => {
        if (error) {
          return reject(error);
        }
        return resolve(result);
      }
    );

    uploadStream.end(fileBuffer);
  });
}

module.exports = {
  isCloudinaryConfigured,
  uploadAvatarToCloudinary,
  uploadAvatarBufferToCloudinary,
};
