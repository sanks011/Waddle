const Territory = require('../models/Territory');
const User = require('../models/User');
const { calculatePolygonArea } = require('../utils/geometry');

// Get all territories
exports.getTerritories = async (req, res) => {
  try {
    const territories = await Territory.find({ isActive: true }).sort({ createdAt: -1 });
    console.log(`🗺️ Fetching all territories: ${territories.length} found`);
    territories.forEach(t => {
      console.log(`  - Territory ${t._id}: ${t.username}, ${t.area.toFixed(2)} m², ${t.polygon.length} points`);
    });
    res.json(territories);
  } catch (error) {
    console.error('Get territories error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Create new territory
exports.createTerritory = async (req, res) => {
  try {
    console.log('🌍 CREATE TERRITORY REQUEST RECEIVED');
    console.log('📦 Full request body:', JSON.stringify(req.body, null, 2));
    
    const { path, formsClosedLoop } = req.body;

    console.log(`Creating territory for user ${req.user.username}`);
    console.log(`Path length: ${path ? path.length : 0}, Forms loop: ${formsClosedLoop}`);
    console.log(`Path sample (first 3 points):`, path ? path.slice(0, 3) : 'No path');

    if (!path || path.length < 1) {
      console.log('❌ REJECTED: No points provided');
      return res.status(400).json({ error: 'Path needs at least 1 point', path: path });
    }

    // For single or double points, create a tiny polygon around them
    let polygonPath = path;
    if (path.length === 1) {
      // Create a tiny square around the single point (approx 1 meter)
      const offset = 0.000009; // ~1 meter in degrees
      const p = path[0];
      polygonPath = [
        { lat: p.lat + offset, lng: p.lng - offset },
        { lat: p.lat + offset, lng: p.lng + offset },
        { lat: p.lat - offset, lng: p.lng + offset },
        { lat: p.lat - offset, lng: p.lng - offset },
      ];
      console.log('📍 Single point converted to tiny polygon');
    } else if (path.length === 2) {
      // Create a tiny rectangle around the two points
      const offset = 0.000009; // ~1 meter in degrees
      const p1 = path[0];
      const p2 = path[1];
      polygonPath = [
        { lat: p1.lat + offset, lng: p1.lng - offset },
        { lat: p2.lat + offset, lng: p2.lng + offset },
        { lat: p2.lat - offset, lng: p2.lng + offset },
        { lat: p1.lat - offset, lng: p1.lng - offset },
      ];
      console.log('📍 Two points converted to tiny polygon');
    }

    // Calculate area
    const area = calculatePolygonArea(polygonPath);
    console.log(`Calculated area: ${area.toFixed(6)} m²`);

    // No minimum area requirement - accept any size, even 0
    console.log(`✅ Area accepted: ${area.toFixed(6)} m²`);

    // Create territory even if not a perfect closed loop
    const territory = new Territory({
      userId: req.user._id,
      username: req.user.username,
      polygon: polygonPath,
      area,
    });

    await territory.save();
    console.log(`✅ Territory created: ${territory._id}`);
    console.log(`📦 Returning territory: ${JSON.stringify({ id: territory._id, area: territory.area, polygon: territory.polygon.length + ' points' })}`);

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

// Merge nearby territories
exports.mergeTerritories = async (req, res) => {
  try {
    console.log('🤝 MERGE TERRITORIES REQUEST RECEIVED');
    const { territoryIds, mergedPath, mergedArea } = req.body;

    console.log(`Merging territories: ${territoryIds.join(', ')}`);
    console.log(`Merged path points: ${mergedPath.length}, Area: ${mergedArea} m²`);

    // Verify both territories belong to the user
    const territories = await Territory.find({
      _id: { $in: territoryIds },
      userId: req.user._id,
      isActive: true
    });

    if (territories.length !== territoryIds.length) {
      return res.status(400).json({ error: 'Invalid territories or not owned by user' });
    }

    // Deactivate old territories
    await Territory.updateMany(
      { _id: { $in: territoryIds } },
      { isActive: false }
    );

    // Create merged territory
    const mergedTerritory = new Territory({
      userId: req.user._id,
      username: req.user.username,
      polygon: mergedPath,
      area: mergedArea,
    });

    await mergedTerritory.save();
    console.log(`✅ Merged territory created: ${mergedTerritory._id}`);

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
    
    console.log(`✅ User territory updated after merge: ${totalArea.toFixed(2)} m²`);

    res.status(201).json(mergedTerritory);
  } catch (error) {
    console.error('Merge territories error:', error);
    res.status(500).json({ error: 'Server error merging territories', details: error.message });
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
