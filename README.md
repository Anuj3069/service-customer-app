# Airveat Customer App

Airveat Customer is the primary mobile application for users to discover, book, and manage on-demand services. Whether you need queue standing assistance, a personal helper, elderly support, or a local tour guide, Airveat connects you with verified service providers quickly and reliably.

## Features

- **Service Browsing**: Explore categorized on-demand services.
- **Real-Time Booking**: Seamlessly book services with your preferred date and time slot.
- **Smart Matching**: Automatically match with available service providers.
- **Booking Management**: View past, current, and upcoming bookings with real-time status updates.
- **Reviews & Ratings**: Share your feedback on completed services.
- **Secure Authentication**: Simple registration and login flow.
- **Dynamic UI**: A modern, glassmorphic UI built with Flutter, featuring smooth shimmer loading effects.

## Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: Provider
- **Networking**: HTTP package
- **Local Storage**: Shared Preferences
- **UI & Typography**: Material Design, Google Fonts, Shimmer

## Getting Started

### Prerequisites
- Flutter SDK (`>=3.9.2`)
- Android Studio / VS Code with Flutter extension
- An Android Emulator or physical device

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Anuj3069/service-customer-app.git
   ```

2. Navigate to the project directory:
   ```bash
   cd service-customer-app
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

*(Note: The app requires the Airveat Node.js backend to be running locally or hosted for authentication and data fetching. Update the API base URL in `lib/config/api_config.dart` accordingly.)*

## Project Structure

- `lib/models/`: Data models (User, Service, Booking, etc.)
- `lib/providers/`: State management for authentication, bookings, and services.
- `lib/screens/`: UI screens (Home, Login, Booking Detail, etc.)
- `lib/services/`: API integration services.
- `lib/widgets/`: Reusable custom UI components (Glass cards, Gradient buttons).
- `lib/config/`: Theme and API configurations.
