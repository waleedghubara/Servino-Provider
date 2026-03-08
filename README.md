<div align="center">
  <img src="assets/images/app_logo.png" alt="Servino Provider Logo" width="150" height="auto" />
  <h1>Servino Provider</h1>
  <p>A powerful Flutter application enabling service providers to manage their business, bookings, and clients efficiently.</p>

  <p>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-%2302569B.svg?logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-%230175C2.svg?logo=dart&logoColor=white" alt="Dart" /></a>
  </p>
</div>

---

## 📖 Project Description

**Servino Provider** is the dedicated counterpart to the Servino Client app, designed specifically for professionals and service creators. It empowers providers with a robust suite of tools to handle scheduling, communicate with clients securely, and securely track their services and earnings. Built with Clean Architecture principles, this app ensures performance, scalability, and an excellent developer experience.

## ✨ Key Features

- **📅 Booking Management**: Manage your schedule, accept/reject requests, and track all upcoming and past appointments.
- **💬 Direct Client Communication**: Built-in chat and full audio/video calling powered by `ZegoCloud` with offline calling support.
- **🔔 Real-Time Notifications**: Stay updated instantly regarding new bookings and messages via `Firebase Cloud Messaging (FCM)`.
- **📍 Location Services**: Set your work area and track client locations using `flutter_map`, `Geolocator`, and `Geocoding`.
- **📄 Invoicing & Reports**: Generate and print professional PDF documents and invoices on the fly using the `pdf` and `printing` packages.
- **🔒 Advanced Security Checks**: Built-in SSL Pinning, Root/Jailbreak detection, and App Device Integrity features to guarantee secure transactions.
- **💰 Currency & Payments**: Integrated `currency_picker` to manage service pricing easily.
- **📱 In-App Updates**: Seamless update flows using `in_app_update`.
- **🌍 Multi-language & Localization**: Fully localized with RTL support via `Easy Localization`.
- **🎨 Dynamic Theming**: Automatic Light and Dark mode switching to match your system preferences.
- **📢 Ads Integration**: Monetization support utilizing `google_mobile_ads`.

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Architecture**: Clean Architecture & MVVM 
- **State Management**: `Provider` & Dependency Injection (`get_it`)
- **Networking**: `Dio` with interceptors and Pretty Logger
- **Local Storage**: `Hive` & `Flutter Secure Storage`
- **Real-time Comms**: `ZegoCloud` & `Firebase`
- **Media & Files**: `image_picker`, `video_player`, `just_audio`, `audioplayers`

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.11.0-200.1.beta` or higher
- Dart SDK
- Android Studio / Xcode

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/waleedghubara/Servino.git
   ```

2. **Navigate to the project directory**:
   ```bash
   cd servino_provider
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## 🔐 Security & Integrity

Servino Provider enforces strict security policies to protect both the provider's business data and the clients' personal information. Active measures include blocking execution on compromised (rooted/jailbroken) devices and validating network requests through SSL Pinning.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
<div align="center">
  <b>Developed by <a href="https://github.com/waleedghubara">Waleed Ghubara</a></b>
</div>
