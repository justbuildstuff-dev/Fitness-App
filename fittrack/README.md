# FitTrack - Flutter Fitness Tracking App

A comprehensive fitness tracking application built with Flutter and Firebase, designed to help users create structured workout programs and track their progress.

## 🏋️ Features

### Core Functionality
- **Hierarchical Program Structure**: Programs → Weeks → Workouts → Exercises → Sets
- **Firebase Authentication**: Secure email/password authentication with profile management  
- **Offline Support**: Full offline functionality with automatic sync when online
- **Week Duplication**: Production-ready Cloud Function for deep copying weeks with all nested data
- **Exercise Types**: Support for strength, cardio, bodyweight, and custom exercises
- **Real-time Sync**: Live updates across devices using Firestore

### User Interface
- **Material Design 3**: Modern, accessible UI following Material Design guidelines
- **Dark Mode Support**: Automatic theme switching based on system preferences
- **Responsive Design**: Works seamlessly on phones and tablets
- **Intuitive Navigation**: Bottom navigation with clear hierarchical flow

### Security & Data
- **Per-user Data Scoping**: All data secured under individual user accounts
- **Firestore Security Rules**: Comprehensive server-side validation and authorization
- **Admin Support**: Optional admin role for support operations
- **Data Validation**: Client and server-side validation for data integrity

## 🛠️ Technical Architecture

### Frontend
- **Flutter 3.10+** - Cross-platform mobile development
- **Provider** - State management
- **Material 3** - Modern UI components

### Backend
- **Firebase Auth** - User authentication and management
- **Cloud Firestore** - NoSQL database with offline support
- **Cloud Functions** - Server-side logic for complex operations
- **Firebase Storage** - File storage (future implementation)

### Data Structure
```
users/{userId}/
├── programs/{programId}/
│   ├── weeks/{weekId}/
│   │   ├── workouts/{workoutId}/
│   │   │   ├── exercises/{exerciseId}/
│   │   │   │   └── sets/{setId}
│   │   │   └── ...
│   │   └── ...
│   └── ...
├── duplicationLogs/{logId}
└── duplicationRequests/{requestId}
```

## 🚀 Getting Started

### Prerequisites
- Flutter 3.10 or higher
- Firebase CLI
- Node.js 18+ (for Cloud Functions)
- A Firebase project

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd fittrack
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Enable Cloud Functions
   - Update `lib/firebase_options.dart` with your project configuration

4. **Deploy Firestore Rules and Indexes**
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only firestore:indexes
   ```

5. **Deploy Cloud Functions**
   ```bash
   cd functions
   npm install
   npm run build
   firebase deploy --only functions
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

### Development Setup

#### Firebase Emulator (Recommended for Development)
```bash
firebase emulators:start
```

This starts local emulators for:
- Authentication (port 9099)
- Firestore (port 8080) 
- Functions (port 5001)
- Emulator UI (port 4000)

#### Hot Reload
```bash
flutter run --hot
```

## 📱 Usage

### Creating Your First Program
1. Sign up or sign in to the app
2. Tap the "+" button on the Programs screen
3. Enter program name and optional description
4. Start adding weeks to structure your training

### Week Management
- Create weeks with custom names and notes
- Duplicate successful weeks using the menu action
- Reorder weeks by dragging (coming soon)

### Exercise Types & Set Fields
- **Strength**: Requires reps, optional weight and rest time
- **Cardio/Time-based**: Requires duration, optional distance
- **Bodyweight**: Requires reps, optional rest time  
- **Custom**: Flexible field configuration

## 🔧 Development

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
├── providers/               # State management
├── screens/                 # UI screens
├── services/                # Business logic services
└── widgets/                 # Reusable UI components

functions/                   # Cloud Functions
├── src/
│   └── index.ts            # duplicateWeek function
├── package.json
└── tsconfig.json

firestore.rules             # Security rules
firestore.indexes.json      # Database indexes
firebase.json              # Firebase configuration
```

### Key Components

#### Authentication Flow
- `AuthProvider` - Manages user authentication state
- `AuthWrapper` - Routes users based on auth status
- Email/password with validation and error handling

#### Data Management
- `FirestoreService` - Centralized Firestore operations
- `ProgramProvider` - State management for program data
- Real-time listeners for live updates

#### Week Duplication
- Server-side Cloud Function for reliability
- Batched writes to handle large datasets
- Exercise type-specific field copying
- Audit logging for debugging

### Adding New Features

1. **Data Models**: Add new model classes in `lib/models/`
2. **Service Methods**: Extend `FirestoreService` with CRUD operations
3. **State Management**: Update providers with new state and methods
4. **UI Screens**: Create new screens following existing patterns
5. **Security Rules**: Update Firestore rules for new data structures

### Testing

#### Unit Tests
```bash
flutter test
```

#### Integration Tests  
```bash
flutter test integration_test/
```

#### Firebase Emulator Tests
```bash
cd functions
npm test
```

## 📋 Roadmap

### Phase 1: Core Features ✅
- [x] User authentication
- [x] Program/Week management  
- [x] Basic UI and navigation
- [x] Week duplication
- [x] Firebase security setup

### Phase 2: Workout Management 🔄
- [ ] Workout CRUD operations
- [ ] Exercise management with types
- [ ] Set tracking with validation
- [ ] Progress visualization

### Phase 3: Enhanced Features
- [ ] Local notifications and reminders
- [ ] Data export (CSV/JSON)
- [ ] Analytics and progress tracking
- [ ] Social sharing
- [ ] Offline photo uploads

### Phase 4: Advanced Features
- [ ] Exercise library with instructions
- [ ] Workout templates and sharing
- [ ] Performance analytics
- [ ] Integration with fitness devices

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex business logic
- Write tests for new features

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For questions or issues:
1. Check the [Issues](../../issues) page
2. Review the technical specification in `Docs/`
3. See `CLAUDE.md` for development guidance

## 🙏 Acknowledgments

- Built following the comprehensive specification in `Docs/Workout_Tracker_Final_Spec.md`
- Designed with Firebase best practices for security and scalability
- UI/UX inspired by Material Design 3 principles

---

**FitTrack** - Your comprehensive fitness companion 💪