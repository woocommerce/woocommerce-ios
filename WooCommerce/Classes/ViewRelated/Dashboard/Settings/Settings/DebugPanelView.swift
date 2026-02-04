import SwiftUI

struct DebugPanelView: View {
    private var debugSettings = DebugSettings.shared

    var body: some View {
        List {
            Button {
                UserDefaults.standard[.hasSavedPrivacyBannerSettings] = false
            } label: {
                Text("Reset Privacy Choice Banner State")
            }

            Button {
                ServiceLocator.crashLogging.crash()
            } label: {
                Text("Crash Immediately")
            }

            NavigationLink(destination: OverrideFeatureFlagsView()) {
                Text("Override Feature Flags")
            }

            Section("WPCom Connection Setup") {
                Toggle("Simulate Outdated Plugin", isOn: debugSettings.$forcedMinimumWooCommerceVersion)
                Text("Sets minimum required version to 9999.9.9")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentMargins(20)
        .navigationTitle("Debug Panel")
    }
}
