# RunUp - Fitness Tracking App

A comprehensive Flutter fitness tracking application with smart notification management.

## Features

### Core Features
- 🏃‍♂️ Activity tracking (Running, Cycling, Walking)
- 📊 Progress monitoring and statistics
- 🎯 Goal setting and achievement tracking
- 📱 Modern dark theme UI with glassmorphism design
- 🗺️ GPS tracking with Google Maps integration
- 📸 Activity sharing and social features

### Smart Notifications
- ⏰ Customizable daily workout reminders
- 📈 Weekly progress notifications
- 🏆 Achievement and milestone alerts
- 💪 Motivational messages
- 🔧 Granular notification control

## Server Integration

The app includes a Node.js Express server for advanced notification management:

### Server Features
- Firebase Admin SDK integration
- FCM (Firebase Cloud Messaging) support
- Scheduled notifications with cron jobs
- Notification history tracking
- RESTful API with authentication
- Rate limiting and security middleware

### API Endpoints
- `GET /api/notifications/settings/:userId` - Get notification preferences
- `PUT /api/notifications/settings/:userId` - Update notification settings
- `POST /api/notifications/test/:userId` - Send test notifications
- `GET /api/notifications/history/:userId` - View notification history
- `PUT /api/users/:userId/fcm-token` - Update FCM token

## Quick Start

### Prerequisites
- Flutter SDK (>=3.8.1)
- Firebase project with Firestore and FCM enabled
- Node.js (>=16.0.0) for server
- Android Studio / Xcode for mobile development

### Flutter App Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd runup
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `firebase_options.dart` with your Firebase configuration

4. Run the app:
```bash
flutter run
```

### Server Setup

1. Navigate to server directory:
```bash
cd ../server
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment:
```bash
cp .env.example .env
# Edit .env with your Firebase credentials
```

4. Start development server:
```bash
npm run dev
```

## Architecture

### Flutter App Structure
```
lib/
├── features/           # Feature-based modules
│   ├── auth/          # Authentication
│   ├── home/          # Home dashboard
│   ├── profile/       # User profile
│   ├── settings/      # App settings
│   └── tracking/      # Activity tracking
├── models/            # Data models
├── services/          # Business logic services
├── widgets/           # Reusable UI components
├── utils/             # Utilities and helpers
└── router/            # Navigation routing
```

### Server Structure
```
server/
├── config/            # Configuration files
├── routes/            # API route handlers
├── services/          # Business logic services
├── middleware/        # Custom middleware
└── index.js           # Server entry point
```

## Key Technologies

### Frontend (Flutter)
- **State Management**: Provider
- **Navigation**: GoRouter
- **UI**: Material Design 3 with custom glassmorphism
- **Maps**: Google Maps Flutter
- **Storage**: Secure Storage, SharedPreferences
- **Firebase**: Auth, Firestore, Messaging

### Backend (Node.js)
- **Framework**: Express.js
- **Database**: Firestore
- **Authentication**: Firebase Admin SDK
- **Scheduling**: node-cron
- **Security**: Helmet, CORS, Rate limiting
- **Validation**: Joi

## Notification System

### Client-Side (Flutter)
- Local notifications with flutter_local_notifications
- FCM integration for push notifications
- Timezone-aware scheduling
- Custom notification sounds and vibrations

### Server-Side (Node.js)
- Automated daily and weekly notifications
- Personalized messaging based on user activity
- Notification history and analytics
- Admin panel for notification management

## Development Features

### UI/UX
- Dark theme with gradient accents
- Glassmorphism design elements
- Smooth animations and transitions
- Responsive layout for different screen sizes
- Consistent color scheme throughout the app

### Performance
- Optimized database queries
- Efficient state management
- Background task handling
- Memory-conscious image loading
- Network request caching

## Configuration

### Environment Variables (Server)
```env
NODE_ENV=development
PORT=3000
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="your-private-key"
FIREBASE_CLIENT_EMAIL=your-client-email
```

### Flutter Configuration
Update the server URL in `NotificationApiService`:
```dart
static const String baseUrl = 'http://your-server-url:3000/api';
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in this repository
- Check the documentation in `/server/README.md`
- Review Firebase setup guide in `/server/FIREBASE_SETUP.md`
