# Kingdom Runner - Gamified Fitness App

A Flutter mobile application with Express.js backend that gamifies walking and running using real-world location tracking.

## 🎯 Core Concept

- Users walk/run to create closed loops on a map
- Completed loops become claimed territory (your "kingdom")
- Larger loops = bigger kingdom
- Users can invade other territories
- Must stay active (1 run every 3 days) or lose territory

## 🏗️ Project Structure

```
bhago_pro/
├── kingdom_runner/          # Flutter mobile app
│   ├── lib/
│   │   ├── models/         # Data models
│   │   ├── services/       # API & Location services
│   │   ├── providers/      # State management
│   │   ├── screens/        # UI screens
│   │   ├── widgets/        # Reusable widgets
│   │   └── utils/          # Utility functions
│   └── pubspec.yaml
│
└── backend/                # Express.js API server
    ├── src/
    │   ├── models/         # MongoDB schemas
    │   ├── controllers/    # Business logic
    │   ├── routes/         # API routes
    │   ├── middleware/     # Auth & validation
    │   └── utils/          # Helper functions
    └── package.json
```

## 🚀 Getting Started

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment variables (already set in `.env`):
- MongoDB connection string is configured
- JWT secret for authentication
- Activity threshold settings

4. Start the server:
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

The server will run on `http://localhost:3000`

### Flutter App Setup

1. Navigate to Flutter app directory:
```bash
cd kingdom_runner
```

2. Get Flutter dependencies:
```bash
flutter pub get
```

3. Configure API endpoint:
- Open `lib/services/api_config.dart`
- Update `baseUrl` based on your target:
  - Android Emulator: `http://10.0.2.2:3000`
  - iOS Simulator: `http://localhost:3000`
  - Physical Device: `http://YOUR_LOCAL_IP:3000`
  - Production: Your deployed backend URL

4. Add Google Maps API Key:

**For Android:**
- Open `android/app/src/main/AndroidManifest.xml`
- Add your Google Maps API key:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY_HERE"/>
```

**For iOS:**
- Open `ios/Runner/AppDelegate.swift`
- Add your Google Maps API key:
```swift
GMSServices.provideAPIKey("YOUR_IOS_API_KEY_HERE")
```

5. Enable location permissions:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location for tracking your runs.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location for tracking your runs.</string>
```

6. Run the app:
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Or just run on connected device
flutter run
```

## 📱 Features

### ✅ Implemented

1. **Authentication**
   - User registration and login
   - JWT-based authentication
   - Secure password hashing

2. **GPS Tracking**
   - Real-time location tracking
   - Distance calculation
   - Path recording

3. **Territory Management**
   - Create territories from closed loops
   - View all territories on map
   - Calculate territory area
   - Color-coded territories (green = yours, red = others)

4. **Activity Sessions**
   - Start/stop tracking
   - Session completion
   - Distance and path recording

5. **Leaderboards**
   - Territory size ranking
   - Total distance ranking
   - Activity streak ranking

6. **Profile**
   - User statistics
   - Total distance covered
   - Kingdom size
   - Activity streak

7. **Activity Rules**
   - Automatic territory loss after 3 days of inactivity
   - Activity streak tracking
   - Hourly background checks for inactive users

## 🔌 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login user

### Users
- `GET /api/v1/users/me` - Get current user profile

### Territories
- `GET /api/v1/territories` - Get all active territories
- `POST /api/v1/territories` - Create new territory
- `GET /api/v1/territories/user/:userId` - Get user's territories

### Activity Sessions
- `POST /api/v1/sessions` - Create new session
- `PUT /api/v1/sessions/:sessionId/complete` - Complete session
- `GET /api/v1/sessions/my` - Get user's sessions

### Leaderboard
- `GET /api/v1/leaderboard?type=territory|distance|streak` - Get leaderboard

## 🛠️ Technologies Used

### Frontend (Flutter)
- **google_maps_flutter** - Map integration
- **geolocator** - GPS location services
- **provider** - State management
- **http/dio** - API communication
- **flutter_secure_storage** - Secure token storage

### Backend (Node.js)
- **Express.js** - Web framework
- **MongoDB/Mongoose** - Database
- **JWT** - Authentication
- **bcryptjs** - Password hashing
- **cors** - Cross-origin resource sharing

## 📊 Database Schema

### Users
- email, username, password
- totalDistance, territorySize
- activityStreak, lastActivity

### Territories
- userId, username
- polygon (array of coordinates)
- area, isActive
- createdAt, lastUpdated

### ActivitySessions
- userId, path
- distance, startTime, endTime
- isCompleted, formsClosedLoop

## 🎮 Game Rules

1. **Territory Claiming**
   - Walk/run to create a closed loop
   - Path must return to starting point (within 50m)
   - Minimum 3 points required

2. **Activity Requirements**
   - Complete at least 1 session every 3 days
   - Failure results in automatic territory loss
   - Activity streak increases with consecutive days

3. **Competitive Features**
   - View all territories on map
   - Leaderboards for multiple categories
   - Territory invasion (future feature)

## 🔒 Security

- Passwords hashed with bcrypt
- JWT tokens for authentication
- Secure storage on mobile device
- API authentication middleware

## 📝 Environment Variables

Backend `.env` file:
```
PORT=3000
MONGODB_URI=mongodb+srv://sahnik:vD5ZtaAKrBPRx29N@adifast.9p87bqm.mongodb.net/?appName=adiFast
JWT_SECRET=kingdom-runner-secret-key-change-in-production
ACTIVITY_THRESHOLD_DAYS=3
CLOSED_LOOP_THRESHOLD_METERS=50
```

## 🚧 Future Enhancements

- Territory invasion mechanics
- Real-time territory battles
- Push notifications for territory threats
- Social features and challenges
- Achievement system
- Power-ups and special abilities
- Territory defense mechanisms
- Team/clan system

## 🐛 Troubleshooting

### Backend Issues
- Ensure MongoDB connection string is correct
- Check if port 3000 is available
- Verify all dependencies are installed

### Flutter Issues
- Run `flutter clean` then `flutter pub get`
- Verify Google Maps API key is set
- Check location permissions are granted
- Ensure device has GPS enabled

### Location Not Working
- Grant location permissions in device settings
- Check if location services are enabled
- For iOS: Ensure Info.plist has location usage descriptions
- For Android: Ensure AndroidManifest.xml has location permissions

## 📄 License

This project is open source and available under the MIT License.

## 👥 Contributing

Contributions are welcome! Please feel free to submit pull requests.

---

**Built with ❤️ for fitness enthusiasts and gamers**
