const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load .env from server directory so it works regardless of process cwd
dotenv.config({ path: path.join(__dirname, '..', '.env') });

function resolveMongoUri() {
  const rawUri = process.env.CONNECTION_STRING;
  if (!rawUri) {
    throw new Error('CONNECTION_STRING is not set in .env');
  }

  // Optional pattern: keep <db_password> in URI and inject real secret via DB_PASSWORD.
  if (rawUri.includes('<db_password>')) {
    const dbPassword = process.env.DB_PASSWORD;
    if (!dbPassword) {
      throw new Error(
        'CONNECTION_STRING contains <db_password> but DB_PASSWORD is missing in .env'
      );
    }
    return rawUri.replace('<db_password>', encodeURIComponent(dbPassword));
  }

  return rawUri;
}

async function connectDB() {
  let uri;
  try {
    uri = resolveMongoUri();
  } catch (error) {
    const err = new Error(error.message);
    console.error('MongoDB config error:', err.message);
    throw err;
  }

  try {
    await mongoose.connect(uri);
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
    throw error;
  }
}

module.exports = connectDB;