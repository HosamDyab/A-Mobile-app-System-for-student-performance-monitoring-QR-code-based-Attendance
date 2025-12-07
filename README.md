# 📱 ClassTrack - Student Performance Monitoring System

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.5.0-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5.0-0175C2?logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-2.5.0-3ECF8E?logo=supabase&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**A modern, feature-rich mobile application for student performance monitoring with QR code-based attendance tracking**

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Usage](#-usage) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

**ClassTrack** is a comprehensive mobile application designed for educational institutions to monitor student performance, manage attendance through QR codes, and provide real-time academic insights. The app features a modern, animated UI with smooth transitions and professional design patterns.

> **Project Status**: ✅ Active Development | 🚀 Ready for Testing | 📱 Cross-Platform Support

### Key Highlights

- ✅ **QR Code-Based Attendance**: Quick and accurate attendance tracking
- ✅ **Real-Time Performance Monitoring**: Track grades, GPA, and academic progress
- ✅ **Modern UI/UX**: Beautiful animations, gradients, and intuitive navigation
- ✅ **Multi-Role Support**: Separate interfaces for Students, Faculty, and Teacher Assistants
- ✅ **Offline Capability**: Local database support for GPA calculations
- ✅ **Secure Authentication**: Role-based access control with session management

## ✨ Features

### 👨‍🎓 Student Features

- **📊 Dashboard**
  - Personalized welcome with dynamic student information
  - Academic performance overview with visual charts
  - Course list with grades and progress tracking
  - Quick access to all features

- **📱 QR Code Scanning**
  - Real-time attendance marking via QR code scanning
  - Instant feedback and confirmation
  - Attendance history tracking

- **🧮 GPA Calculator**
  - Calculate cumulative and semester-wise GPA
  - Add/edit semesters and courses
  - Visual GPA trend charts
  - Local storage for offline access

- **🔍 Search Functionality**
  - Search courses by name, code, or instructor
  - Search faculty members
  - Grade distribution visualization
  - Animated course cards with detailed information

- **👤 Profile Management**
  - View personal information
  - Academic details and statistics
  - Secure logout functionality

- **📈 Attendance Tracking**
  - View attendance history
  - Statistics and analytics
  - Visual attendance distribution charts

### 👨‍🏫 Faculty/Teacher Assistant Features

- **📋 Attendance Management**
  - Generate QR codes for lectures
  - Live attendance tracking
  - Manual attendance entry
  - Attendance history and reports

- **📝 Grade Management**
  - Enter and update student grades
  - Grade distribution analysis
  - Export grade reports

- **👥 Student Management**
  - View student lists
  - Student performance overview
  - Course enrollment management

- **📊 Dashboard**
  - Quick statistics
  - Recent activities
  - Course management

## 🖼️ Screenshots

> *Screenshots will be added here*

## 🛠️ Tech Stack

### Frontend
- **Flutter** 3.5.0+ - Cross-platform mobile framework
- **Dart** 3.5.0+ - Programming language

### State Management
- **flutter_bloc** 8.1.3 - BLoC pattern for state management
- **Cubit** - Lightweight state management

### Backend & Database
- **Supabase** 2.5.0 - Backend-as-a-Service (BaaS)
  - PostgreSQL database
  - Real-time subscriptions
  - Authentication
- **sqflite** 2.3.0 - Local SQLite database for offline storage

### UI/UX Libraries
- **fl_chart** 0.65.0 - Beautiful charts and graphs
- **google_fonts** - Custom typography
- **lottie** - Animations
- **google_nav_bar** 5.0.6 - Navigation components

### QR Code & Scanning
- **mobile_scanner** 3.5.0 - QR code scanning
- **qr_flutter** 4.1.0 - QR code generation

### Utilities
- **intl** 0.19.0 - Internationalization
- **pdf** 3.11.1 - PDF generation
- **printing** 5.13.3 - Print functionality
- **shared_preferences** - Local data persistence

## 📦 Installation

### Prerequisites

- Flutter SDK (3.5.0 or higher)
- Dart SDK (3.5.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Supabase account and project
- Git

### Step 1: Clone the Repository

```bash
git clone https://github.com/HosamDyab/A-Mobile-app-System-for-student-performance-monitoring-QR-code-based-Attendance.git
cd A-Mobile-app-System-for-student-performance-monitoring-QR-code-based-Attendance
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Configure Supabase

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Get your project URL and anon key
3. Update `lib/ustils/supabase_manager.dart` with your credentials:

```dart
class SupabaseManager {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  // ...
}
```

### Step 4: Database Setup

1. Navigate to the `database/` folder
2. Execute the SQL scripts in your Supabase SQL editor:
   - `populate_student_data.sql`
   - `faculty_test_data.sql`
   - `teacher_assistant_test_data.sql`
   - Other relevant SQL files

### Step 5: Run the Application

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the root directory (optional, if using environment variables):

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### App Configuration

- **App Name**: Update in `pubspec.yaml` and platform-specific configs
- **Package Name**: Update in `android/app/build.gradle` and `ios/Runner.xcodeproj`
- **App Icons**: Replace icons in `android/app/src/main/res/` and `ios/Runner/Assets.xcassets/`

## 🚀 Usage

### For Students

1. **Login**: Use your MTI email (format: `name.id@cs.mti.edu.eg`)
2. **Dashboard**: View your academic overview
3. **Scan QR**: Scan QR codes during lectures to mark attendance
4. **GPA Calculator**: Add semesters and courses to calculate your GPA
5. **Search**: Find courses and faculty members
6. **Profile**: View and manage your profile

### For Faculty/Teacher Assistants

1. **Login**: Use your faculty credentials
2. **Generate QR Code**: Create QR codes for lectures
3. **Track Attendance**: Monitor real-time attendance
4. **Enter Grades**: Add and update student grades
5. **View Reports**: Access attendance and grade reports

## 🏗️ Architecture

The application follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── auth/                    # Authentication module
│   └── screens/             # Login, Welcome, Forgot Password
├── Student/                 # Student feature module
│   ├── data/                # Data layer (models, repositories)
│   ├── domain/               # Domain layer (entities, use cases)
│   └── presentation/        # Presentation layer (UI, BLoC)
├── Teacher/                 # Teacher/Faculty feature module
│   ├── models/              # Data models
│   ├── services/            # Business logic
│   └── views/               # UI components
├── shared/                  # Shared resources
│   ├── utils/               # Utilities (colors, transitions)
│   └── widgets/             # Reusable widgets
├── services/                # Core services (auth, email)
└── helpers/                 # Helper functions
```

### Design Patterns

- **BLoC Pattern**: State management using Cubit/BLoC
- **Repository Pattern**: Data abstraction layer
- **Dependency Injection**: Manual DI through constructors
- **Observer Pattern**: For state changes and updates

## 📁 Project Structure

```
lib/
├── auth/                    # Authentication
│   └── screens/
│       ├── welcome_screen.dart
│       ├── login_screen.dart
│       └── forgot_password_screen.dart
│
├── Student/                # Student Module
│   ├── data/
│   │   ├── models/         # Data models
│   │   └── repo_imp/       # Repository implementations
│   ├── domain/
│   │   ├── entities/       # Domain entities
│   │   └── repo/           # Repository interfaces
│   └── presentation/
│       ├── blocs/          # State management
│       ├── screens/        # UI screens
│       └── widgets/        # UI components
│
├── Teacher/                # Teacher Module
│   ├── models/             # Data models
│   ├── services/           # Business logic
│   ├── views/              # UI screens
│   └── viewmodels/         # View models
│
├── shared/                 # Shared Resources
│   ├── utils/
│   │   ├── app_colors.dart
│   │   ├── page_transitions.dart
│   │   └── student_utils.dart
│   └── widgets/
│       ├── animated_gradient_background.dart
│       ├── modern_bottom_nav_bar.dart
│       ├── loading_animation.dart
│       └── ...
│
├── services/               # Core Services
│   ├── auth_service.dart
│   └── email_service.dart
│
├── helpers/                # Helper Functions
│   └── ...
│
└── main.dart              # Application Entry Point
```

## 🎨 UI/UX Features

- **Modern Material Design 3**: Latest Material Design guidelines
- **Smooth Animations**: Page transitions, hover effects, and micro-interactions
- **Gradient Backgrounds**: Animated gradient backgrounds
- **Charts & Visualizations**: Beautiful charts using fl_chart
- **Responsive Design**: Adapts to different screen sizes
- **Dark Mode Ready**: Theme support for dark mode
- **Accessibility**: Screen reader support and semantic labels

## 🔒 Security

- **Role-Based Access Control**: Different access levels for students, faculty, and TAs
- **Secure Authentication**: Supabase authentication with session management
- **Data Encryption**: Secure data transmission
- **Remember Me**: Secure local storage for user preferences

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request**

### Coding Standards

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Write unit tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Hosam Dyab** - [GitHub](https://github.com/HosamDyab)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- All contributors and open-source libraries used in this project

## 📞 Support

For support, open an issue in the repository or contact through GitHub.

## 🔮 Future Enhancements

- [ ] Push notifications for attendance reminders
- [ ] Offline mode with sync
- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] Integration with learning management systems
- [ ] AI-powered performance predictions
- [ ] Social features for student collaboration

---

<div align="center">

**Made with ❤️ For MTI**

⭐ Star this repo if you find it helpful!

</div>
