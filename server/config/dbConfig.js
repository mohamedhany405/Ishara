const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load .env from server directory so it works regardless of process cwd
dotenv.config({ path: path.join(__dirname, '..', '.env') });

async function connectDB() {
  const uri = process.env.CONNECTION_STRING;
  if (!uri) {
    const err = new Error('CONNECTION_STRING is not set in .env');
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