const Event = require('../models/Event');
const Message = require('../models/Message');

// ── Helpers ────────────────────────────────────────────────────────────────

// Haversine distance in metres between two lat/lng points
function haversine(lat1, lng1, lat2, lng2) {
  const R = 6371000;
  const toRad = (v) => (v * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ── Controllers ────────────────────────────────────────────────────────────

// GET /events?lat=&lng=&radius=5000&search=
exports.getEvents = async (req, res) => {
  try {
    const { lat, lng, radius = 10000, search = '' } = req.query;

    let query = { expiresAt: { $gt: new Date() } };

    if (search.trim()) {
      query.$or = [
        { title: { $regex: search.trim(), $options: 'i' } },
        { description: { $regex: search.trim(), $options: 'i' } },
        { creatorUsername: { $regex: search.trim(), $options: 'i' } },
      ];
    }

    const events = await Event.find(query).sort({ createdAt: -1 }).limit(100);

    // If lat/lng provided, filter by radius and sort by distance
    const userLat = parseFloat(lat);
    const userLng = parseFloat(lng);
    const maxRadius = parseFloat(radius);

    let results = events;
    if (!isNaN(userLat) && !isNaN(userLng)) {
      results = events
        .map((e) => {
          const dist = haversine(
            userLat,
            userLng,
            e.location.lat,
            e.location.lng
          );
          return { event: e, distance: dist };
        })
        .filter((x) => x.distance <= maxRadius)
        .sort((a, b) => a.distance - b.distance)
        .map(({ event, distance }) => {
          const obj = event.toSafeObject();
          obj.distanceMetres = Math.round(distance);
          return obj;
        });
    } else {
      results = events.map((e) => e.toSafeObject());
    }

    res.json({ events: results });
  } catch (err) {
    console.error('getEvents error:', err);
    res.status(500).json({ error: 'Failed to fetch events' });
  }
};

// GET /events/:id
exports.getEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ error: 'Event not found' });
    res.json({ event: event.toSafeObject() });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch event' });
  }
};

// POST /events
exports.createEvent = async (req, res) => {
  try {
    const { title, description, lat, lng, isPublic, password } = req.body;

    if (!title || lat == null || lng == null) {
      return res
        .status(400)
        .json({ error: 'title, lat and lng are required' });
    }

    const event = new Event({
      title,
      description: description || '',
      creatorId: req.user._id,
      creatorUsername: req.user.username,
      creatorAvatarPath: req.user.avatarPath || null,
      location: { lat: parseFloat(lat), lng: parseFloat(lng) },
      isPublic: isPublic !== false && isPublic !== 'false',
      participants: [
        {
          userId: req.user._id,
          username: req.user.username,
          avatarPath: req.user.avatarPath || null,
          joinedAt: new Date(),
        },
      ],
    });

    if (!event.isPublic && password) {
      await event.setPassword(password);
    }

    await event.save();
    res.status(201).json({ event: event.toSafeObject() });
  } catch (err) {
    console.error('createEvent error:', err);
    res.status(500).json({ error: 'Failed to create event' });
  }
};

// POST /events/:id/join
exports.joinEvent = async (req, res) => {
  try {
    const { password } = req.body;
    const event = await Event.findById(req.params.id);

    if (!event) return res.status(404).json({ error: 'Event not found' });

    // Already joined
    const alreadyIn = event.participants.some(
      (p) => p.userId.toString() === req.user._id.toString()
    );
    if (alreadyIn) {
      return res.json({ event: event.toSafeObject(), alreadyJoined: true });
    }

    if (!event.isPublic) {
      if (!password)
        return res.status(401).json({ error: 'Password required' });
      const ok = await event.checkPassword(password);
      if (!ok) return res.status(401).json({ error: 'Wrong password' });
    }

    event.participants.push({
      userId: req.user._id,
      username: req.user.username,
      avatarPath: req.user.avatarPath || null,
    });

    await event.save();
    res.json({ event: event.toSafeObject() });
  } catch (err) {
    console.error('joinEvent error:', err);
    res.status(500).json({ error: 'Failed to join event' });
  }
};

// DELETE /events/:id  (creator only)
exports.deleteEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ error: 'Event not found' });

    if (event.creatorId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Not the creator' });
    }

    await Event.findByIdAndDelete(req.params.id);
    await Message.deleteMany({ eventId: req.params.id });
    res.json({ message: 'Event deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete event' });
  }
};

// ── Messages ───────────────────────────────────────────────────────────────

// GET /events/:id/messages?before=<iso>&limit=50
exports.getMessages = async (req, res) => {
  try {
    const { before, limit = 50 } = req.query;
    const q = { eventId: req.params.id };
    if (before) q.createdAt = { $lt: new Date(before) };

    const messages = await Message.find(q)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));

    res.json({ messages: messages.reverse().map((m) => m.toSafeObject()) });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
};

// POST /events/:id/messages
exports.sendMessage = async (req, res) => {
  try {
    const { content } = req.body;
    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'content is required' });
    }

    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ error: 'Event not found' });

    // Must be a participant
    const isMember = event.participants.some(
      (p) => p.userId.toString() === req.user._id.toString()
    );
    if (!isMember) {
      return res.status(403).json({ error: 'Join the event first' });
    }

    const message = await Message.create({
      eventId: event._id,
      userId: req.user._id,
      username: req.user.username,
      avatarPath: req.user.avatarPath || null,
      content: content.trim(),
    });

    res.status(201).json({ message: message.toSafeObject() });
  } catch (err) {
    console.error('sendMessage error:', err);
    res.status(500).json({ error: 'Failed to send message' });
  }
};
