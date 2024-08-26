import SwiftUI

/// SwiftUI conformance for `SettingsViewController`
///
struct SettingsView: UIViewControllerRepresentable {

    typealias UIViewControllerType = SettingsViewController

    func makeUIViewController(context: Self.Context) -> SettingsViewController {
        let viewController = SettingsViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: SettingsViewController, context: Context) {
        // nothing to do here
    }
}
