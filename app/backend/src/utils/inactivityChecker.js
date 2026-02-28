const User = require('../models/User');
const Territory = require('../models/Territory');

// Check and deactivate territories for inactive users
const checkInactiveUsers = async () => {
  try {
    const thresholdDays = process.env.ACTIVITY_THRESHOLD_DAYS || 3;
    const thresholdDate = new Date();
    thresholdDate.setDate(thresholdDate.getDate() - thresholdDays);

    // Find users who haven't been active in the threshold period
    const inactiveUsers = await User.find({
      lastActivity: { $lt: thresholdDate }
    });

    for (const user of inactiveUsers) {
      // Deactivate all territories for this user
      await Territory.updateMany(
        { userId: user._id, isActive: true },
        { isActive: false }
      );

      // Reset user's territory size and streak
      user.territorySize = 0;
      user.activityStreak = 0;
      await user.save();

      console.log(`Deactivated territories for inactive user: ${user.username}`);
    }

    if (inactiveUsers.length > 0) {
      console.log(`✅ Deactivated territories for ${inactiveUsers.length} inactive users`);
    }
  } catch (error) {
    console.error('Error checking inactive users:', error);
  }
};

// Run every hour
const startInactivityChecker = () => {
  // Run immediately on start
  checkInactiveUsers();
  
  // Then run every hour
  setInterval(checkInactiveUsers, 60 * 60 * 1000);
  console.log('⏰ Inactivity checker started - running every hour');
};

module.exports = { startInactivityChecker, checkInactiveUsers };
