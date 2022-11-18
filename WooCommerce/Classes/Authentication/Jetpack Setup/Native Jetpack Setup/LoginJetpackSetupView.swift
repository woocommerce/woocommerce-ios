import SwiftUI

/// Hosting controller for `LoginJetpackSetupView`.
///
final class LoginJetpackSetupHostingViewController: UIHostingController<LoginJetpackSetupView> {
    init(siteURL: String, connectionOnly: Bool) {
        let viewModel = LoginJetpackSetupViewModel(siteURL: siteURL, connectionOnly: connectionOnly)
        super.init(rootView: LoginJetpackSetupView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBarAppearance()
    }

    /// Shows a transparent navigation bar without a bottom border.
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance

        let title = NSLocalizedString("Cancel", comment: "Button to dismiss the site credential login screen")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(dismissView))
    }

    @objc
    private func dismissView() {
        dismiss(animated: true)
    }
}

/// View to show the process of Jetpack setup during login.
///
struct LoginJetpackSetupView: View {
    @ObservedObject private var viewModel: LoginJetpackSetupViewModel

    init(viewModel: LoginJetpackSetupViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Hello, World!")
    }
}

struct LoginJetpackSetupView_Previews: PreviewProvider {
    static var previews: some View {
        LoginJetpackSetupView(viewModel: LoginJetpackSetupViewModel(siteURL: "https://test.com", connectionOnly: true))
        LoginJetpackSetupView(viewModel: LoginJetpackSetupViewModel(siteURL: "https://test.com", connectionOnly: false))
    }
}
