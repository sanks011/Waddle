const express = require('express');
const router = express.Router();
const territoryController = require('../controllers/territoryController');
const auth = require('../middleware/auth');

// Get all territories
router.get('/', auth, territoryController.getTerritories);

// Create new territory
router.post('/', auth, territoryController.createTerritory);

// Get user territories
router.get('/user/:userId', auth, territoryController.getUserTerritories);

module.exports = router;
