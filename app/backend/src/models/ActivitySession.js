const mongoose = require('mongoose');

const activitySessionSchema = new mongoose.Schema({
  _id: {
    type: String,
    required: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  path: [{
    lat: {
      type: Number,
      required: true,
    },
    lng: {
      type: Number,
      required: true,
    },
  }],
  distance: {
    type: Number,
    required: true,
    default: 0,
  },
  startTime: {
    type: Date,
    required: true,
  },
  endTime: {
    type: Date,
  },
  isCompleted: {
    type: Boolean,
    default: false,
  },
  formsClosedLoop: {
    type: Boolean,
    default: false,
  },
  territoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Territory',
  },
});

module.exports = mongoose.model('ActivitySession', activitySessionSchema);
