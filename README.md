# 🚗 DriveOrbit - Fleet Management Mobile App

<div align="center">

![DriveOrbit Logo](assets/logo/logo.png)

**A comprehensive Flutter-based fleet management solution for drivers and fleet administrators**

[![Flutter](https://img.shields.io/badge/Flutter-3.5.4-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

</div>

## 📱 Overview

DriveOrbit is a modern, feature-rich fleet management mobile application built with Flutter. It provides comprehensive tools for drivers to manage their vehicles, track jobs, monitor fuel consumption, and maintain real-time communication with fleet administrators.

## ✨ Key Features

### 🎯 **Driver Dashboard**
- Real-time vehicle availability tracking
- Driver status management (Active/Break/Unavailable)
- Advanced search and filtering for vehicles
- Interactive vehicle cards with detailed information

### 🗺️ **Map & Navigation**
- Real-time GPS tracking with Google Maps integration
- Live location updates and route monitoring
- Fullscreen map mode for better navigation
- Mileage tracking and distance calculations

### 📋 **Job Management**
- Job assignment and tracking system
- QR code scanning for job verification
- Job completion workflow with detailed forms
- Job history and performance analytics

### ⛽ **Fuel Management**
- Fuel level monitoring and alerts
- Fuel refill recording with receipts
- Low fuel warnings and notifications
- Fuel consumption analytics

### 📸 **Vehicle Documentation**
- Multi-angle vehicle photo capture (Front, Back, Left, Right)
- Dashboard photo verification
- Image gallery with zoom functionality
- Secure cloud storage integration

### 🔔 **Notifications**
- Real-time push notifications
- In-app notification center
- Draggable notification interface
- Emergency assistance alerts

### 👤 **Profile Management**
- Driver profile with photo upload
- Personal information management
- Settings and preferences
- Authentication with Firebase Auth

## 🏗️ Architecture

### **Tech Stack**
- **Frontend**: Flutter 3.5.4 with Dart
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Maps**: Google Maps Flutter
- **State Management**: setState with StreamBuilder
- **UI**: Material Design with custom theming

### **Key Dependencies**
```yaml
flutter: ^3.5.4
firebase_core: ^2.27.1
firebase_auth: ^4.17.9
cloud_firestore: ^4.15.9
google_maps_flutter: ^2.10.0
geolocator: ^10.1.0
image_picker: Latest
mobile_scanner: ^6.0.6
google_fonts: ^6.2.1
flutter_screenutil: ^5.9.3
```

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK 3.5.4 or higher
- Dart SDK
- Android Studio / VS Code
- Firebase project setup
- Google Maps API key

### **Installation**

1. **Clone the repository**
   ```bash
   git clone [repository-url]
   cd driveorbit-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, and Storage
   - Download and place `google-services.json` in `android/app/`
   - For iOS, place `GoogleService-Info.plist` in `ios/Runner/`

4. **Google Maps Setup**
   - Get Google Maps API key from Google Cloud Console
   - Add the API key to `android/app/src/main/AndroidManifest.xml`
   - Add the API key to `ios/Runner/AppDelegate.swift`

5. **Run the application**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── app/
│   └── theme.dart           # App theming
├── models/                  # Data models
│   ├── vehicle_details_entity.dart
│   ├── job_details_entity.dart
│   └── notification_model.dart
├── screens/                 # UI screens
│   ├── auth/               # Authentication screens
│   ├── dashboard/          # Main dashboard
│   ├── vehicle_dashboard/  # Vehicle management
│   ├── job/               # Job management
│   ├── profile/           # User profile
│   └── qr_scan/          # QR scanning
├── services/              # Business logic
│   ├── vehicle_service.dart
│   ├── notification_service.dart
│   └── firebase_service.dart
├── widgets/               # Reusable widgets
└── utils/                # Utility functions
```

## 🔧 Configuration

### **Environment Setup**

1. **Android Configuration**
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
   ```

2. **iOS Configuration**
   ```swift
   // ios/Runner/AppDelegate.swift
   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
   ```

3. **Firebase Security Rules**
   ```javascript
   // Firestore rules
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /vehicles/{vehicleId} {
         allow read, write: if request.auth != null;
       }
       match /jobs/{jobId} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

## 🧪 Testing

### **Run Tests**
```bash
# Unit tests
flutter test

# Widget tests
flutter test test/form_page_test.dart
flutter test test/qr_scan_page_test.dart
```

### **Build for Production**
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 🔄 CI/CD

The project includes GitHub Actions workflows for automated building and testing:

- **Build Workflow**: Automated APK and iOS build generation
- **Test Workflow**: Automated testing and code formatting checks
- **Firebase Integration**: Secure configuration management

## 🎨 Features Showcase

### **Driver Dashboard**
- Real-time vehicle status updates
- Intuitive search and filtering
- Expandable vehicle lists
- Status indicator system

### **Map Integration**
- Live GPS tracking
- Interactive map controls
- Fullscreen navigation mode
- Location-based services

### **Job Management**
- QR code job verification
- Comprehensive job forms
- Progress tracking
- Completion workflows

### **Smart Notifications**
- Priority-based alerts
- Interactive notification drawer
- Real-time updates
- Emergency notifications

## 🔐 Security Features

- Firebase Authentication integration
- Secure data transmission
- Role-based access control
- Input validation and sanitization
- Secure file uploads

## 📱 Platform Support

- **Android**: Minimum API level 21 (Android 5.0)
- **iOS**: Minimum iOS 12.0
- **Web**: Progressive Web App support
- **Desktop**: Windows, macOS, Linux (experimental)


## 📄 License

This project is proprietary software. All rights reserved.

## 📞 Support

For support and questions:
- Email: info@driveorbit.pro
- Documentation: [Internal Wiki]
- Issue Tracker: [GitHub Issues]

## 🔄 Version History

- **v1.0.0** - Initial release with core features
- **Current**: Enhanced job management and real-time tracking

---

<div align="center">
Made with ❤️ by the DriveOrbit Team
</div>
