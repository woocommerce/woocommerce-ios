import SwiftUI

/// SwiftUI wrapper for `SettingsViewController`
///
struct SettingsView: UIViewControllerRepresentable {

    func makeUIViewController(context: Self.Context) -> SettingsViewController {
        let viewController = SettingsViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: SettingsViewController, context: Context) {
        // nothing to do here
    }

    func makeCoordinator() -> Self.Coordinator { Coordinator() }
}
