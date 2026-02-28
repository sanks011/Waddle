const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const eventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 80,
  },
  description: {
    type: String,
    trim: true,
    maxlength: 300,
    default: '',
  },
  creatorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  creatorUsername: {
    type: String,
    required: true,
  },
  creatorAvatarPath: {
    type: String,
    default: null,
  },
  location: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  isPublic: {
    type: Boolean,
    default: true,
  },
  // bcrypt‑hashed password for private rooms
  passwordHash: {
    type: String,
    default: null,
  },
  participants: [
    {
      userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      username: String,
      avatarPath: { type: String, default: null },
      joinedAt: { type: Date, default: Date.now },
    },
  ],
  createdAt: {
    type: Date,
    default: Date.now,
  },
  // Events auto‑expire after 24 h by default
  expiresAt: {
    type: Date,
    default: () => new Date(Date.now() + 24 * 60 * 60 * 1000),
  },
});

// TTL index — MongoDB removes expired documents automatically
eventSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// 2dsphere index for geo queries
eventSchema.index({ 'location.lat': 1, 'location.lng': 1 });

// Hash password before saving
eventSchema.methods.setPassword = async function (plainPassword) {
  this.passwordHash = await bcrypt.hash(plainPassword, 10);
};

eventSchema.methods.checkPassword = async function (plainPassword) {
  if (!this.passwordHash) return false;
  return bcrypt.compare(plainPassword, this.passwordHash);
};

// Strip passwordHash from JSON responses and stringify all ObjectIds
eventSchema.methods.toSafeObject = function () {
  const obj = this.toObject();
  delete obj.passwordHash;
  obj.id = obj._id.toString();
  delete obj._id;
  delete obj.__v;
  if (obj.creatorId) obj.creatorId = obj.creatorId.toString();
  if (Array.isArray(obj.participants)) {
    obj.participants = obj.participants.map(p => ({
      ...p,
      userId: p.userId ? p.userId.toString() : '',
      _id: undefined,
    }));
  }
  return obj;
};

module.exports = mongoose.model('Event', eventSchema);
