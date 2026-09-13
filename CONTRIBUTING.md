# Contributing to Project Zapp

## 1. Prerequisites

- Git.
- Visual Studio Code with the Flutter and Dart extensions.
- A physical Android or iOS device with USB debugging enabled.
- For iOS builds: a Mac with Xcode. This is an Apple requirement and cannot be avoided.

Android Studio is not required and should not be installed for this project.

## 2. Flutter SDK Installation (Command Line Only)

1. Download the latest stable Flutter SDK archive for your operating system from the official Flutter documentation site.
2. Extract it to a permanent location, for example `~/development/flutter` on Linux/macOS.
3. Add the `bin` directory to the system `PATH`:
   ```sh
   export PATH="$HOME/development/flutter/bin:$PATH"
   ```
4. Verify the installation:
   ```sh
   flutter --version
   ```

## 3. Android Toolchain (Command Line Tools Only)

The full Android Studio IDE is not required. Install the command-line tools and platform tools only:

1. Download the Android SDK command-line tools package (`commandlinetools`) for your operating system from the official Android developer site.
2. Extract it to `$ANDROID_HOME/cmdline-tools/latest`, where `ANDROID_HOME` is e.g. `~/Android/Sdk`.
3. Install the required packages:
   ```sh
   sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
   ```
4. Accept the licences:
   ```sh
   flutter doctor --android-licenses
   ```
5. Confirm the toolchain:
   ```sh
   flutter doctor
   ```
   Resolve any reported deficiencies before proceeding.

## 4. Project Setup

```sh
git clone <repository-url>
cd project-zapp
flutter pub get
```

## 5. Running on a Physical Device

Emulators are not used in this project.

1. Enable USB debugging on the device and connect it via USB.
2. Confirm detection:
   ```sh
   flutter devices
   ```
3. Launch the application:
   ```sh
   flutter run
   ```
   Hot reload remains available: press `r` in the terminal after saving changes.

## 6. iOS Builds

iOS builds and device deployment require a Mac with Xcode installed, a valid Apple developer signing identity, and a connected iPhone. Open `ios/Runner.xcworkspace` in Xcode once to configure signing; subsequent builds may use `flutter run`.

## 7. Branching and Pull Requests

- `main` must remain buildable. Do not commit directly to `main`.
- Branch names: `feature/gps-camera`, `feature/timetable`, `feature/auth`.
- Each developer commits only within their assigned feature directory, except for agreed changes to `lib/core/`.
- Submit pull requests into `main` for review by the project lead.

## 8. Verification Before a Pull Request

```sh
flutter analyze
flutter test
```
