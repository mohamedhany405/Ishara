const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load .env from server directory so it works regardless of process cwd
dotenv.config({ path: path.join(__dirname, '..', '.env') });

if (!global.__isharaMongoose) {
  global.__isharaMongoose = {
    conn: null,
    promise: null,
  };
}

const cached = global.__isharaMongoose;

if (!global.__isharaMongooseListenersBound) {
  global.__isharaMongooseListenersBound = true;

  mongoose.connection.on('connected', () => {
    console.log('MongoDB connection state: connected');
  });

  mongoose.connection.on('disconnected', () => {
    console.warn('MongoDB connection state: disconnected');
  });

  mongoose.connection.on('error', (error) => {
    console.error('MongoDB runtime error:', error.message);
  });
}

function toInt(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function resolveMongoUri() {
  const rawUri = process.env.MONGODB_URI || process.env.CONNECTION_STRING;
  if (!rawUri) {
    throw new Error('MONGODB_URI (or CONNECTION_STRING) is not set');
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
  if (cached.conn) {
    return cached.conn;
  }

  let uri;
  try {
    uri = resolveMongoUri();
  } catch (error) {
    const err = new Error(error.message);
    console.error('MongoDB config error:', err.message);
    throw err;
  }

  if (!cached.promise) {
    const connectionOptions = {
      maxPoolSize: toInt(process.env.MONGODB_MAX_POOL_SIZE, 10),
      serverSelectionTimeoutMS: toInt(
        process.env.MONGODB_SERVER_SELECTION_TIMEOUT_MS,
        10000
      ),
      socketTimeoutMS: toInt(process.env.MONGODB_SOCKET_TIMEOUT_MS, 45000),
      family: 4,
    };

    cached.promise = mongoose
      .connect(uri, connectionOptions)
      .then((instance) => {
        console.log('MongoDB connected successfully');
        return instance;
      })
      .catch((error) => {
        cached.promise = null;
        console.error('MongoDB connection failed:', error.message);
        throw error;
      });
  }

  cached.conn = await cached.promise;
  return cached.conn;
}

module.exports = connectDB;