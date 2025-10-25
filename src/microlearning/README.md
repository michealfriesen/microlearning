# microlearning

Make learning fast and fun, from any source.

## Prerequisites

Before you begin, ensure you have the following installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (SDK version ^3.8.1)
- [Dart SDK](https://dart.dev/get-dart) (comes with Flutter)
- An IDE (Android Studio, VS Code, or IntelliJ IDEA)
- For iOS development: Xcode (macOS only)
- For Android development: Android Studio and Android SDK

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd microlearning
```

### 2. Verify Flutter Installation

Check that Flutter is properly installed and configured:

```bash
flutter doctor
```
This will show you if there are any dependencies you need to install or configuration steps you need to complete.

### 3. Install Flutter Dependencies

Run the following command to install all the required dependencies:

```bash
flutter pub get
```

### 4. Build the Project

```bash
flutter build apk
```

### 5. Run the Project
#### On default device

```bash
flutter run
```

#### On a Specific Device:
To see available devices:

```bash
flutter devices
```

To run on a specific device:

```bash
flutter run -d <device-id>
```

#### On Chrome (Web):

```bash
flutter run -d chrome
```
