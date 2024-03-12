import SwiftUI

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
