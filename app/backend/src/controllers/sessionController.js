const ActivitySession = require('../models/ActivitySession');
const User = require('../models/User');
const { calculateDistance, isClosedLoop } = require('../utils/geometry');

// Create new session
exports.createSession = async (req, res) => {
  try {
    const { id, path, startTime } = req.body;

    const session = new ActivitySession({
      _id: id,
      userId: req.user._id,
      path: path || [],
      distance: 0,
      startTime: startTime || new Date(),
    });

    await session.save();
    res.status(201).json(session);
  } catch (error) {
    console.error('Create session error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Complete session
exports.completeSession = async (req, res) => {
  try {
    const { path, distance } = req.body;
    const session = await ActivitySession.findById(req.params.sessionId);

    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    if (session.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    console.log(`Completing session ${req.params.sessionId} for user ${req.user.username}`);
    console.log(`Path points: ${path ? path.length : 0}, Distance: ${distance}m`);

    // Calculate values
    const calculatedDistance = distance || calculateDistance(path);
    const formsLoop = isClosedLoop(path);

    session.path = path;
    session.distance = calculatedDistance;
    session.endTime = new Date();
    session.isCompleted = true;
    session.formsClosedLoop = formsLoop;

    await session.save();
    console.log(`✅ Session saved: ${calculatedDistance.toFixed(2)}m, Loop: ${formsLoop}`);

    // Update user stats
    const user = await User.findById(req.user._id);
    const previousDistance = user.totalDistance;
    const previousStreak = user.activityStreak;
    
    user.totalDistance += calculatedDistance;
    user.lastActivity = new Date();
    
    // Update activity streak
    const daysSinceLastActivity = Math.floor(
      (new Date() - new Date(user.lastActivity)) / (1000 * 60 * 60 * 24)
    );
    
    if (daysSinceLastActivity <= 1) {
      user.activityStreak += 1;
    } else if (daysSinceLastActivity > 3) {
      user.activityStreak = 1;
    }

    await user.save();
    console.log(`✅ Updated user ${req.user.username}:`);
    console.log(`   Distance: ${previousDistance.toFixed(2)}m → ${user.totalDistance.toFixed(2)}m (+${calculatedDistance.toFixed(2)}m)`);
    console.log(`   Streak: ${previousStreak} → ${user.activityStreak} days`);

    res.json(session);
  } catch (error) {
    console.error('Complete session error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get user sessions
exports.getUserSessions = async (req, res) => {
  try {
    const sessions = await ActivitySession.find({ 
      userId: req.user._id 
    }).sort({ startTime: -1 });
    
    res.json(sessions);
  } catch (error) {
    console.error('Get user sessions error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
