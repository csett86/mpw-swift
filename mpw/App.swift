import SwiftUI

@main
struct MPWiOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Master Password iOS Credential Provider")
                .font(.title2)
                .bold()

            Text("This iOS app bundles a credential provider extension that provides the Master Password algorithm.")
                .fixedSize(horizontal: false, vertical: true)

            Text("Enable the credential provider from iOS Settings → General → Autofill & Password Options.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
    }
}
