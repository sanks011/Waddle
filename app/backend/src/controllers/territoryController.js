const Territory = require('../models/Territory');
const User = require('../models/User');
const { calculatePolygonArea } = require('../utils/geometry');

// Get all territories
exports.getTerritories = async (req, res) => {
  try {
    const territories = await Territory.find({ isActive: true }).sort({ createdAt: -1 });
    res.json(territories);
  } catch (error) {
    console.error('Get territories error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Create new territory
exports.createTerritory = async (req, res) => {
  try {
    const { path, formsClosedLoop } = req.body;

    if (!formsClosedLoop) {
      return res.status(400).json({ error: 'Path must form a closed loop' });
    }

    if (!path || path.length < 3) {
      return res.status(400).json({ error: 'Invalid path' });
    }

    // Calculate area
    const area = calculatePolygonArea(path);

    // Create territory
    const territory = new Territory({
      userId: req.user._id,
      username: req.user.username,
      polygon: path,
      area,
    });

    await territory.save();

    // Update user's total territory size
    const userTerritories = await Territory.find({ 
      userId: req.user._id, 
      isActive: true 
    });
    const totalArea = userTerritories.reduce((sum, t) => sum + t.area, 0);
    
    await User.findByIdAndUpdate(req.user._id, {
      territorySize: totalArea,
      lastActivity: new Date(),
    });

    res.status(201).json(territory);
  } catch (error) {
    console.error('Create territory error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get user territories
exports.getUserTerritories = async (req, res) => {
  try {
    const territories = await Territory.find({ 
      userId: req.params.userId,
      isActive: true 
    });
    res.json(territories);
  } catch (error) {
    console.error('Get user territories error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
