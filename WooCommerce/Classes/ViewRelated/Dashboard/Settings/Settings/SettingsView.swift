import SwiftUI

/// SwiftUI view for App Settings
///
struct SettingsView: View {

    var body: some View {
        SettingsWrapperView()
            .navigationTitle(Localization.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private extension SettingsView {
    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "settingsView.navigationTitle",
            value: "Settings",
            comment: "Settings navigation title"
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
