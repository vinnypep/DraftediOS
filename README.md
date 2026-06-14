# Drafted

Drafted is a SwiftUI iOS 18+ social snake draft game with a dark material-glass interface, demo-mode gameplay, and Firebase-ready services.

## Open In Xcode

Open `Drafted.xcodeproj`, select the `Drafted` scheme, resolve Swift Package dependencies, and run on an iOS 18+ simulator or device.

This workspace currently uses local demo services when `GoogleService-Info.plist` is not present. Add your Firebase config file to the app target to enable the Firebase service path.

## Project Shape

- `Drafted/App`: app entry point, root shell, navigation, shared app state
- `Drafted/Models`: Codable app and Firestore-ready models
- `Drafted/Services`: draft engine, demo services, Firebase-ready service implementations
- `Drafted/DesignSystem`: reusable material-glass UI components
- `Drafted/Features`: onboarding, home/discover/history, draft room, results, settings, profile
- `backend`: Firestore rules and callable `judgeDraft` function scaffold

## Firebase Notes

The Xcode project references Firebase Apple SDK 12.x via Swift Package Manager:

- FirebaseCore
- FirebaseAuth
- FirebaseFirestore
- FirebaseFunctions
- FirebaseMessaging

The app intentionally stays clickable without Firebase configuration. Once `GoogleService-Info.plist` is added, startup configures Firebase and the live service implementations become available.

