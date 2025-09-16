# 🚀 ISRO Quiz App

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)

An interactive quiz application built with Flutter that tests your knowledge about the Indian Space Research Organisation (ISRO). Features real-time data from ISRO APIs, comprehensive quiz analytics, and robust offline capabilities.

## ✨ Features

### 🎯 Quiz System
- **Dynamic Question Generation**: Real-time questions from ISRO API endpoints
- **Smart Fallback**: 20+ high-quality sample questions when API is unavailable
- **Multiple Categories**: Spacecrafts, Launchers, Satellites, ISRO Centers
- **Difficulty Levels**: Easy, Medium, Hard
- **Timed Challenges**: Configurable time limits (5-20 questions)
- **Real-time Evaluation**: Instant feedback with detailed explanations

### 🔐 Authentication & User Management
- **Dual Login Options**: 
  - OTP-based authentication
  - Email/Password authentication
- **Secure Sign-up**: Password creation with confirmation
- **Profile Management**: User statistics and progress tracking
- **Session Management**: Automatic data persistence during login sessions
- **Privacy Protection**: Complete data clearing on logout

### 📊 Analytics & Progress Tracking
- **Comprehensive Statistics**: 
  - Total quizzes taken
  - Average scores and best performance
  - Category-wise performance analysis
  - Recent quiz history
- **Dual Data Storage**: 
  - Primary: Firebase/Firestore
  - Backup: Local storage for offline access
- **Visual Indicators**: Clear data source identification (Database/Local)

### 🛡️ Robust Architecture
- **Offline-First Design**: Full functionality without internet
- **API Fallback System**: Seamless transition when external APIs fail
- **Local Profile Service**: Session-based data persistence
- **Database Resilience**: Works even when Firebase is down
- **Memory Management**: Efficient state management with Riverpod

### 🎨 User Experience
- **Material 3 Design**: Modern, intuitive interface
- **Responsive Layout**: Optimized for all screen sizes
- **Smooth Animations**: Polished user interactions
- **Accessibility**: Screen reader support and high contrast
- **Cross-Platform**: Web, Android, iOS, Windows, macOS, Linux

## 🏗️ Technical Architecture

### Frontend
- **Framework**: Flutter 3.24+
- **State Management**: Riverpod 2.6+
- **UI Components**: Material 3
- **Navigation**: Go Router
- **Local Storage**: SharedPreferences
- **HTTP Client**: Dio

### Backend & Services
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **External APIs**: ISRO Vercel API
- **Caching**: Local profile service
- **Analytics**: Custom quiz analytics

### Key Services
- **Enhanced Quiz Service**: Dynamic question generation with API fallback
- **Local Profile Service**: Session-based data persistence
- **Firebase Services**: Authentication and data storage
- **Mock Services**: Offline development and testing

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.24 or higher
- Dart 3.8.1 or higher
- Firebase project (optional for development)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Bhavikpim123/isroquiz.git
   cd isroquiz
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup (Optional)**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the respective platform directories
   - The app works without Firebase using mock services

4. **Run the application**
   ```bash
   # Web (recommended for development)
   flutter run -d chrome
   
   # Android
   flutter run -d android
   
   # iOS
   flutter run -d ios
   
   # Windows
   flutter run -d windows
   ```

### Development Setup

1. **Environment Configuration**
   ```bash
   # Check Flutter doctor
   flutter doctor
   
   # Enable web support
   flutter config --enable-web
   ```

2. **IDE Setup**
   - VS Code with Flutter extension
   - Android Studio with Flutter plugin
   - IntelliJ IDEA with Dart/Flutter plugins

## 📱 Usage

### For Users

1. **Sign Up/Login**
   - Choose between OTP or password authentication
   - Create account with email and secure password
   - Verify email (in OTP mode)

2. **Take Quizzes**
   - Select difficulty level (Easy/Medium/Hard)
   - Choose number of questions (5-20)
   - Start quiz with real-time timer
   - Get instant feedback and explanations

3. **Track Progress**
   - View comprehensive statistics
   - Check recent quiz history
   - Monitor category-wise performance
   - Access data even when offline

4. **Profile Management**
   - Update display name and preferences
   - View achievement statistics
   - Logout to clear local data

### For Developers

1. **API Integration**
   ```dart
   // Generate quiz from ISRO API
   final quiz = await quizService.generateQuizFromAPI(
     questionCount: 10,
     difficulty: QuestionDifficulty.medium,
   );
   ```

2. **Local Storage**
   ```dart
   // Save quiz result locally
   await localProfileService.saveQuizResult(result);
   
   // Load user statistics
   final stats = await localProfileService.calculateLocalStats(userId);
   ```

3. **State Management**
   ```dart
   // Watch authentication state
   final authState = ref.watch(authProvider);
   
   // Access local profile data
   final localProfile = ref.watch(localProfileProvider);
   ```

## 🏛️ Project Structure

```
lib/
├── config/
│   └── theme.dart              # App theming and Material 3 config
├── models/
│   ├── firebase_user.dart      # User and quiz result models
│   ├── isro_data.dart         # ISRO API data models
│   ├── quiz.dart              # Quiz and question models
│   └── user.dart              # Legacy user model
├── providers/
│   ├── auth_provider.dart      # Authentication state management
│   ├── enhanced_quiz_provider.dart  # Quiz session management
│   ├── local_profile_provider.dart  # Local data management
│   └── user_stats_provider.dart     # User statistics
├── screens/
│   ├── enhanced_quiz_taking_screen.dart  # Quiz interface
│   ├── enhanced_quiz_result_screen.dart  # Results display
│   ├── home_screen.dart        # Main navigation
│   ├── login_screen.dart       # Authentication UI
│   ├── profile_screen.dart     # User profile and stats
│   └── quiz_screen.dart        # Quiz configuration
├── services/
│   ├── enhanced_quiz_service.dart    # Quiz generation with fallback
│   ├── firebase_auth_service.dart    # Firebase authentication
│   ├── firestore_service.dart        # Database operations
│   ├── isro_api_service.dart         # External API integration
│   ├── local_profile_service.dart    # Local storage management
│   └── mock_firebase_service.dart    # Development/offline services
├── widgets/
│   └── shimmer_loading.dart    # Loading animations
├── firebase_options.dart       # Firebase configuration
└── main.dart                   # App entry point
```

## 🔧 Configuration

### Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project
   - Enable Authentication and Firestore

2. **Configure Authentication**
   ```bash
   # Enable Email/Password and Anonymous sign-in
   # Configure authorized domains for web
   ```

3. **Firestore Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       match /quiz_results/{resultId} {
         allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
       }
     }
   }
   ```

### Environment Variables

Create `.env` file in root directory:
```env
ISRO_API_BASE_URL=https://isro.vercel.app/api
FIREBASE_PROJECT_ID=your-project-id
DEVELOPMENT_MODE=true
```

## 🧪 Testing

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### Test Coverage
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📦 Building for Production

### Web
```bash
flutter build web --release
```

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Desktop
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## 🚀 Deployment

### Web Deployment
- **Firebase Hosting**: `firebase deploy --only hosting`
- **Netlify**: Drag and drop `build/web` folder
- **Vercel**: Connect GitHub repository

### Mobile App Stores
- **Google Play Store**: Upload `app-release.aab`
- **Apple App Store**: Submit via Xcode or App Store Connect

## 🤝 Contributing

1. **Fork the repository**
2. **Create feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit changes**
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. **Push to branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open Pull Request**

### Development Guidelines
- Follow [Flutter style guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
- Write tests for new features
- Update documentation
- Ensure code passes `flutter analyze`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **ISRO**: For providing open APIs and inspiring space education
- **Flutter Team**: For the amazing cross-platform framework
- **Firebase**: For reliable backend services
- **Material Design**: For beautiful UI components
- **Community**: For contributions and feedback

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Bhavikpim123/isroquiz/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Bhavikpim123/isroquiz/discussions)
- **Email**: [Contact Developer](mailto:bhavikpim123@gmail.com)

## 🔮 Roadmap

- [ ] **Multiplayer Mode**: Real-time quiz competitions
- [ ] **Achievements System**: Badges and rewards
- [ ] **Dark Mode**: Complete dark theme support
- [ ] **Offline Sync**: Background data synchronization
- [ ] **Voice Questions**: Audio-based quiz questions
- [ ] **AR Integration**: Augmented reality space exploration
- [ ] **Machine Learning**: Adaptive difficulty based on performance

---

<div align="center">
  <p><strong>Made with ❤️ for Space Education</strong></p>
  <p>🚀 Explore • 🎯 Learn • 🌟 Excel</p>
</div>

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
