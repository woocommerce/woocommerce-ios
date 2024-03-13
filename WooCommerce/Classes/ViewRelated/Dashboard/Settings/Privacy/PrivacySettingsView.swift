import SwiftUI

/// SwiftUI view for privacy settings.
/// 
struct PrivacySettingsView: View {

    var body: some View {
        PrivacySettingsWrapperView()
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private extension PrivacySettingsView {
    enum Localization {
        static let title = NSLocalizedString(
            "privacySettingsView.title",
            value: "Privacy Settings",
            comment: "Privacy settings screen title"
        )
    }
}

/// A SwiftUI wrapper for `PrivacySettingsViewController`.
///
private struct PrivacySettingsWrapperView: UIViewControllerRepresentable {

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
