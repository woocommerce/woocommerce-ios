import SwiftUI
import Combine

/// SwiftUI view for App Settings
///
struct SettingsView: View {
    @Binding var showingPrivacySettings: Bool

    var body: some View {
        SettingsWrapperView()
            .navigationTitle(Localization.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingPrivacySettings) {
                PrivacySettingsView()
                    .navigationTitle(Localization.privacySettings)
            }
    }
}

private extension SettingsView {
    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "settingsView.navigationTitle",
            value: "Settings",
            comment: "Settings navigation title"
        )
        static let privacySettings = NSLocalizedString(
            "settingsView.privacySettings",
            value: "Privacy Settings",
            comment: "Privacy settings screen title"
        )
    }
}

/// SwiftUI wrapper for `SettingsViewController`
///
private struct SettingsWrapperView: UIViewControllerRepresentable {

    func makeUIViewController(context: Self.Context) -> SettingsViewController {
        let viewController = SettingsViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: SettingsViewController, context: Context) {
        // nothing to do here
    }
}

/// A SwiftUI wrapper for `PrivacySettingsViewController`.
///
struct PrivacySettingsView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> PrivacySettingsViewController {
        guard let privacy = UIStoryboard.dashboard.instantiateViewController(ofClass: PrivacySettingsViewController.self) else {
            fatalError("⛔️ Could not instantiate PrivacySettingsViewController")
        }
        return privacy
    }

    func updateUIViewController(_ uiViewController: PrivacySettingsViewController, context: Context) {
        // no-op
    }
}
