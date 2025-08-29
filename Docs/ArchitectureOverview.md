# Architecture Overview

## Introduction

FitTrack is a mobile-first workout tracking application built with Flutter and Firebase. The architecture follows clean architecture principles with a clear separation between UI, business logic, and data layers. The system is designed for offline-first operation, real-time data synchronization, and scalable user-centric data management.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────────┤
│  Flutter UI Components                                      │
│  ├─ Screens (Auth, Programs, Weeks, Workouts, Exercises)   │
│  ├─ Widgets (Reusable UI Components)                       │
│  └─ Navigation (Route Management)                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Provider Pattern
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT                         │
├─────────────────────────────────────────────────────────────┤
│  Providers (ChangeNotifier)                                │
│  ├─ AuthProvider (User Authentication & Profile)           │
│  ├─ ProgramProvider (Workout Data Hierarchy)               │
│  └─ [Future: SettingsProvider, NotificationProvider]       │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Service Layer
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC                          │
├─────────────────────────────────────────────────────────────┤
│  Services                                                   │
│  ├─ FirestoreService (Data Access Layer)                   │
│  ├─ NotificationService (Local Notifications)              │
│  └─ [Future: AnalyticsService, ExportService]             │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Firebase SDKs
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATA LAYER                               │
├─────────────────────────────────────────────────────────────┤
│  Firebase Services                                          │
│  ├─ Firebase Auth (User Authentication)                    │
│  ├─ Cloud Firestore (Document Database)                    │
│  ├─ Firebase Storage (File Storage) [Future]               │
│  └─ Firebase Messaging (Push Notifications) [Future]       │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Network/Local Storage
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    INFRASTRUCTURE                           │
├─────────────────────────────────────────────────────────────┤
│  ├─ Firebase Project (Cloud Infrastructure)                │
│  ├─ Firestore Offline Persistence (Local Cache)           │
│  ├─ Security Rules (Server-side Validation)                │
│  └─ Local Notifications (Platform Services)                │
└─────────────────────────────────────────────────────────────┘
```

## Architecture Principles

### 1. Clean Architecture
- **Separation of Concerns**: Each layer has distinct responsibilities
- **Dependency Inversion**: High-level modules don't depend on low-level modules
- **Testability**: Each layer can be tested independently
- **Maintainability**: Changes in one layer don't affect others

### 2. Offline-First Design
- **Local Persistence**: Firestore offline persistence enabled
- **Optimistic Updates**: UI updates immediately, syncs in background
- **Conflict Resolution**: Last-write-wins with timestamp-based resolution
- **Queue Management**: Operations queued when offline, processed when online

### 3. User-Centric Data Model
- **Hierarchical Structure**: All data organized under user documents
- **Security by Design**: Every document includes userId for access control
- **Scalable Querying**: Efficient queries using hierarchical paths
- **Data Isolation**: Complete isolation between user data

### 4. Reactive Architecture
- **Stream-Based Updates**: Real-time UI updates via Firestore streams
- **Provider Pattern**: Reactive state management with automatic UI rebuilding
- **Event-Driven**: Operations trigger cascading updates through the system
- **Declarative UI**: UI describes what it should look like for any given state

## Core Components

### Data Models
**Location**: `lib/models/`

Immutable data classes that represent business entities:

```dart
Program
└── Week
    └── Workout
        └── Exercise (with ExerciseType enum)
            └── ExerciseSet
```

**Key Features**:
- Immutable design with copyWith() methods
- Firestore serialization (toFirestore/fromFirestore)
- Built-in validation rules
- Type-safe enum handling (ExerciseType)
- Parent ID references for hierarchical queries

### State Management (Providers)
**Location**: `lib/providers/`

#### AuthProvider
- Manages user authentication state
- Handles Firebase Auth integration
- Manages user profile data
- Provides authentication methods (signIn, signUp, signOut)
- Error handling and user feedback

#### ProgramProvider
- Manages workout data hierarchy
- Handles CRUD operations for all entities
- Maintains selection state (current program, week, etc.)
- Provides real-time data streaming
- Implements client-side duplication logic

**Provider Dependencies**:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProxyProvider<AuthProvider, ProgramProvider>(
      create: (_) => ProgramProvider(null),
      update: (_, authProvider, __) => ProgramProvider(authProvider.user?.uid),
    ),
  ],
  child: App(),
)
```

### Service Layer
**Location**: `lib/services/`

#### FirestoreService
- Singleton service for all Firestore operations
- Implements hierarchical queries following security model
- Provides client-side duplication with batched writes
- Handles offline persistence configuration
- Type-safe CRUD operations for all models

#### NotificationService
- Local notification scheduling and management
- Workout reminder functionality
- Platform-specific notification handling

### UI Layer
**Location**: `lib/screens/` and `lib/widgets/`

#### Screen Architecture
```
screens/
├── auth/
│   ├── auth_wrapper.dart         # Authentication routing
│   ├── sign_in_screen.dart       # User login
│   ├── sign_up_screen.dart       # User registration
│   └── forgot_password_screen.dart # Password recovery
├── home/
│   └── home_screen.dart          # Main navigation hub
├── programs/
│   ├── programs_screen.dart      # Program list
│   ├── create_program_screen.dart # Program creation
│   └── program_detail_screen.dart # Program details with weeks
├── weeks/
│   ├── weeks_screen.dart         # Week management
│   └── create_week_screen.dart   # Week creation
├── workouts/
│   ├── create_workout_screen.dart # Workout creation
│   └── workout_detail_screen.dart # Workout execution interface
├── exercises/
│   ├── create_exercise_screen.dart # Exercise creation with type selection
│   └── exercise_detail_screen.dart # Exercise management with set tracking
├── sets/
│   └── create_set_screen.dart    # Set logging with type-specific fields
├── profile/
│   └── profile_screen.dart       # User profile and settings
└── settings/
    └── settings_screen.dart      # App settings (placeholder)
```

#### Widget Architecture
- **Screens**: Full-page components with state management
- **Widgets**: Reusable UI components
- **Consumer Widgets**: Components that listen to Provider changes
- **Stateless/Stateful**: Appropriate widget types based on requirements

## Data Flow

### Authentication Flow
```
1. App Launch → AuthWrapper
2. AuthProvider checks Firebase Auth state
3. If authenticated → Load user profile → HomeScreen
4. If not authenticated → SignInScreen
5. User signs in → AuthProvider updates → AuthWrapper rebuilds → HomeScreen
```

### Data Operation Flow
```
1. UI Action (Create Program) → ProgramProvider method
2. Provider calls FirestoreService
3. FirestoreService writes to Firestore
4. Firestore stream emits update
5. Provider receives update → notifies listeners
6. UI rebuilds with new data
```

### Offline Operation Flow
```
1. User performs action while offline
2. FirestoreService writes to local cache
3. UI updates optimistically
4. When online, Firestore syncs changes
5. Conflicts resolved automatically (last-write-wins)
6. UI receives final state via streams
```

## Security Architecture

### Authentication Security
- **Firebase Auth**: Industry-standard authentication service
- **JWT Tokens**: Automatic token management and refresh
- **User Sessions**: Secure session handling with automatic expiration
- **Password Policy**: Client and server-side password validation

### Data Security
- **Firestore Rules**: Server-side access control and validation
- **User Isolation**: Each user can only access their own data
- **Admin Role**: Custom claims for support access with audit logging
- **Hierarchical Security**: Security rules follow data hierarchy

### Client Security
- **Input Validation**: All user inputs validated before submission
- **Error Handling**: Secure error messages without information leakage
- **Local Storage**: Sensitive data handled by Firebase SDKs only

## Performance Architecture

### Query Optimization
- **Hierarchical Queries**: Direct collection paths instead of collectionGroup
- **Indexed Fields**: All query fields properly indexed
- **Pagination**: Large result sets paginated to prevent memory issues
- **Stream Management**: Proper subscription lifecycle management

### Offline Performance
- **Local Cache**: Firestore offline persistence reduces network requests
- **Optimistic Updates**: Immediate UI feedback without waiting for network
- **Background Sync**: Data syncs automatically in background
- **Conflict Resolution**: Efficient handling of concurrent modifications

### Memory Management
- **Stream Cleanup**: All subscriptions cancelled in dispose methods
- **Immutable Data**: Models prevent accidental mutations
- **Provider Lifecycle**: Providers disposed when no longer needed
- **Widget Optimization**: Selective rebuilding with Selector widgets

## Scalability Considerations

### Data Scalability
- **User-Centric Sharding**: Data naturally partitioned by user
- **Hierarchical Structure**: Efficient queries within user data
- **Batch Operations**: Support for large operations with proper chunking
- **Index Management**: Composite indexes for complex queries

### Feature Scalability
- **Modular Architecture**: New features added as separate modules
- **Service Layer**: Business logic encapsulated in services
- **Provider Pattern**: New state management as needed
- **Plugin Architecture**: Third-party integrations via plugins

### Infrastructure Scalability
- **Firebase Auto-Scaling**: Automatic scaling of Firebase services
- **Global Distribution**: Firebase's global infrastructure
- **Offline Support**: Reduced server load with local caching
- **Efficient Protocols**: Optimized Firebase protocols for mobile

## Development Workflow

### Code Organization
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── providers/                # State management
├── services/                 # Business logic services
├── screens/                  # UI screens
├── widgets/                  # Reusable UI components
├── utils/                    # Utility functions
└── constants/                # App constants
```

### Testing Strategy
- **Unit Tests**: Models, services, and providers
- **Widget Tests**: UI components and screens
- **Integration Tests**: End-to-end user flows
- **Firebase Emulator**: Local testing environment

### Build and Deployment
- **Environment Configuration**: Dev, staging, production
- **Firebase Configuration**: Per-environment Firebase projects
- **CI/CD Pipeline**: Automated testing and deployment
- **Code Quality**: Linting, formatting, and analysis

## Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile framework
- **Dart**: Programming language
- **Provider**: State management library
- **Material Design**: UI design system

### Backend
- **Firebase Auth**: User authentication
- **Cloud Firestore**: NoSQL document database
- **Firebase Functions**: Serverless compute (future use)
- **Firebase Storage**: File storage (future use)

### Development Tools
- **Firebase Emulator Suite**: Local development environment
- **Firebase CLI**: Project management and deployment
- **Flutter DevTools**: Debugging and profiling
- **VS Code/Android Studio**: Development environment

## Future Architecture Enhancements

### Planned Features
1. **Analytics Service**: Client-side analytics and reporting
2. **Export Service**: Data export to various formats
3. **Sync Service**: Advanced conflict resolution
4. **Cache Service**: Intelligent local caching
5. **Settings Service**: Centralized app settings management

### Scalability Preparations
1. **Microservices**: Service-oriented architecture for complex features
2. **Event Sourcing**: Audit trail and data history
3. **CQRS**: Command Query Responsibility Segregation for complex queries
4. **Real-time Features**: WebSocket support for collaborative features

### Platform Expansions
1. **Web Support**: Progressive web app capabilities
2. **Desktop Support**: Windows, macOS, Linux applications
3. **Watch Integration**: Apple Watch and Wear OS support
4. **IoT Integration**: Fitness device integrations

This architecture provides a solid foundation for the FitTrack application with room for future growth and feature expansion while maintaining security, performance, and user experience standards.