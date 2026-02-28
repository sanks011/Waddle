const User = require('../models/User');

// Get leaderboard
exports.getLeaderboard = async (req, res) => {
  try {
    const { type = 'territory' } = req.query;
    let sortField = 'territorySize';

    switch (type) {
      case 'distance':
        sortField = 'totalDistance';
        break;
      case 'streak':
        sortField = 'activityStreak';
        break;
      default:
        sortField = 'territorySize';
    }

    const users = await User.find()
      .sort({ [sortField]: -1 })
      .limit(100)
      .select('-password');

    res.json(users);
  } catch (error) {
    console.error('Get leaderboard error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
