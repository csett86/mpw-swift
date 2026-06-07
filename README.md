# Master Password in Swift

The Master Password algorithm as AuthenticationServices credential provider extension for macOS and iOS, implemented in pure Swift.

## Project contents

- `mpw-ios` iOS and macOS host app target
- `CredentialProviderExtension` app extension target shared by both host apps

## Open in Xcode

Open `mpw-swift.xcodeproj` in Xcode 16 or newer and build `mpw-ios`.

After installing the app, enable the bundled credential provider from:
- macOS: **System Settings → General -> Autofill & Passwords**
- iOS: **Settings → General → Autofill & Passwords**
