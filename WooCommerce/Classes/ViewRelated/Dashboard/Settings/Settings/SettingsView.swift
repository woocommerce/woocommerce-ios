import SwiftUI
import Combine

/// SwiftUI view for App Settings
///
struct SettingsView: View {
    let navigationPublisher: AnyPublisher<Void, Never>

    var body: some View {
        SettingsWrapperView(navigationPublisher: navigationPublisher)
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
    let navigationPublisher: AnyPublisher<Void, Never>

    func makeUIViewController(context: Self.Context) -> SettingsViewController {
        let viewController = SettingsViewController(navigationPublisher: navigationPublisher)
        return viewController
    }

    func updateUIViewController(_ uiViewController: SettingsViewController, context: Context) {
        // nothing to do here
    }
}
