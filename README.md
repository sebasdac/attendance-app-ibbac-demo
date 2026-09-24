# IBBAC Attendance App

Cross-platform attendance management application built with **Flutter, Dart and Firebase**.

This project was developed to manage attendance, members, classes, reports and statistics for a real organization.

## Features

* Attendance registration
* Member management
* Class and group management
* Multiple attendance sessions
* Attendance history
* Dashboard with statistics
* Annual attendance reports
* PDF report generation
* Firebase cloud database
* Android APK builds
* Flutter Web support
* OTA updates using Shorebird

## Tech Stack

* Flutter
* Dart
* Firebase
* Cloud Firestore
* Git
* GitHub
* Shorebird

## Project Structure

The application separates UI, models, services and configuration to keep the project organized and maintainable.

```text
lib/
├── core/
│   ├── config/
│   ├── services/
│   └── utils/
├── models/
├── screens/
├── widgets/
└── main.dart
```

## Demo Environment

This public repository is intended for portfolio and demonstration purposes.

It uses a separate Firebase environment with fictitious or test data.

The production Firebase environment and real organizational information are not included in this repository.

## Getting Started

Clone the repository:

```bash
git clone https://github.com/sebasdac/attendance-app-ibbac-flutter.git
```

Enter the project folder:

```bash
cd attendance-app-ibbac-flutter
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## Android Build

Generate a release APK:

```bash
flutter build apk --release
```

## Web Build

Generate the web version:

```bash
flutter build web
```

## Shorebird

The project supports OTA Flutter updates using Shorebird.

Create a release:

```bash
shorebird release android
```

Create a patch:

```bash
shorebird patch android
```

## Security

This repository should not contain production credentials, private keys, signing keystores or real user information.

The demo Firebase environment is intended only for development and portfolio purposes.

## Project Context

This application was developed as a real-world attendance management solution for **IBBAC**.

The project includes experience with:

* Flutter mobile development
* Dart
* Firebase integration
* Firestore data management
* Reusable UI components
* Asynchronous programming
* PDF reporting
* Android deployment
* Web deployment
* Debugging and maintenance
* OTA application updates
* Git-based version control

## Author

**Sebastián Coto Arias**

Software Developer
Cartago, Costa Rica

GitHub: [@sebasdac](https://github.com/sebasdac)
