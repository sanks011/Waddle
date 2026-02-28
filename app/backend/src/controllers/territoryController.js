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

    console.log(`Creating territory for user ${req.user.username}`);
    console.log(`Path length: ${path ? path.length : 0}, Forms loop: ${formsClosedLoop}`);

    if (!path || path.length < 3) {
      return res.status(400).json({ error: 'Path needs at least 3 points', path: path });
    }

    // Calculate area
    const area = calculatePolygonArea(path);
    console.log(`Calculated area: ${area.toFixed(2)} m²`);

    if (area < 1) {
      return res.status(400).json({ error: 'Territory area too small (minimum 1 m²)', area });
    }

    // Create territory even if not a perfect closed loop
    const territory = new Territory({
      userId: req.user._id,
      username: req.user.username,
      polygon: path,
      area,
    });

    await territory.save();
    console.log(`✅ Territory created: ${territory._id}`);

    // Update user's total territory size
    const userTerritories = await Territory.find({ 
      userId: req.user._id, 
      isActive: true 
    });
    const totalArea = userTerritories.reduce((sum, t) => sum + t.area, 0);
    
    const user = await User.findByIdAndUpdate(req.user._id, {
      territorySize: totalArea,
      lastActivity: new Date(),
    }, { new: true });
    
    console.log(`✅ Updated user ${req.user.username} territory size to ${totalArea.toFixed(2)} m²`);

    res.status(201).json(territory);
  } catch (error) {
    console.error('Create territory error:', error);
    res.status(500).json({ error: 'Server error creating territory', details: error.message });
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
