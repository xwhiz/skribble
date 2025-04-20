# Skribble

Skribble is a Flutter-based application with a backend powered by Bun and Express.js.

## Project Structure

### App

The `app/` directory contains the Flutter application. It includes:

- `lib/`: Main Dart code for the Flutter app.
- `assets/`: Static assets for the app.
- `android/` and `ios/`: Platform-specific configurations.

### Backend

The `backend/` directory contains the server-side code written in TypeScript using Express.js. It includes:

- `middlewares/`: Custom middleware for the server.
- `routes/`: API routes.
- `models/`: Data models.
- `utils/`: Utility functions.

## Getting Started

### App

1. Install Flutter: [Flutter Installation Guide](https://flutter.dev/docs/get-started/install).
2. Navigate to the `app/` directory:
   ```bash
   cd app
   flutter pub get
   flutter run
   ```
