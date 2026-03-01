# Kingdom Runner

A gamified fitness Flutter app where users walk/run to claim territories on a map.

## Features

- 🗺️ Real-time map tracking with OpenStreetMap
- 📍 GPS-based location tracking
- 🏃 Activity sessions with step tracking
- 🏆 Leaderboard system
- 🎯 Territory claiming mechanics
- 📊 Daily nutrition tracking (Protein & Carbs)
- 🤖 AI-powered diet analysis using Google Gemini

## Diet Analysis Feature

The app includes an AI-powered nutrition analysis feature that:
- Stores your daily protein and carb intake
- Shows your last 5 days of nutrition history
- Provides personalized insights using Google Gemini AI
- Helps you understand your dietary patterns

### Gemini API Key

The app uses Google Gemini API for diet analysis. The API key is stored in a `.env` file and cached in Flutter Secure Storage.

**Configuration:**
1. Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
3. Edit `.env` and add your API key:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```
4. The key is automatically loaded on app startup and cached securely

**Note:** The `.env` file is gitignored for security. Each developer should create their own `.env` file from `.env.example`.

## Getting Started

### Prerequisites
- Flutter SDK (^3.10.7)
- Android Studio / Xcode
- Backend server running (see backend README)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/          # Data models (User, Territory, DietEntry, etc.)
├── providers/       # State management (Provider pattern)
├── screens/         # UI screens
├── services/        # API services (Backend, Location, Gemini)
├── utils/           # Utility functions
└── widgets/         # Reusable widgets
```

## Backend

The app connects to a Node.js/Express backend:
- Production: `https://bhago-pro-jyh0.onrender.com`
- See backend folder for setup instructions

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Google Gemini API](https://ai.google.dev/)
- [OpenStreetMap](https://www.openstreetmap.org/)

