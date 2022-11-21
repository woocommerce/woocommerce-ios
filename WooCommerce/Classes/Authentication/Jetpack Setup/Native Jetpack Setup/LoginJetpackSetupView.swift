import SwiftUI

/// Hosting controller for `LoginJetpackSetupView`.
///
final class LoginJetpackSetupHostingController: UIHostingController<LoginJetpackSetupView> {
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
        configureTransparentNavigationBar()

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

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    init(viewModel: LoginJetpackSetupViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()

                // title and description
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    Text(viewModel.title)
                        .largeTitleStyle()
                    AttributedText(viewModel.descriptionAttributedString)
                }

                ForEach(viewModel.setupSteps) { step in
                    HStack(spacing: Constants.stepItemHorizontalSpacing) {
                        if viewModel.isSetupStepInProgress(step) {
                            ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        } else if viewModel.isSetupStepPending(step) {
                            Image(uiImage: .checkEmptyCircleImage)
                                .resizable()
                                .frame(width: Constants.stepImageSize * scale, height: Constants.stepImageSize * scale)
                        } else {
                            Image(uiImage: .checkCircleImage)
                                .resizable()
                                .frame(width: Constants.stepImageSize * scale, height: Constants.stepImageSize * scale)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step == .connection ? Localization.authorizing : step.title)
                                .font(.body)
                                .if(step <= viewModel.currentSetupStep) {
                                    $0.bold()
                                }
                                .foregroundColor(Color(.text))
                                .opacity(step <= viewModel.currentSetupStep ? 1 : 0.5)
                            Label {
                                Text(viewModel.currentConnectionStep.title)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            } icon: {
                                viewModel.currentConnectionStep.imageName.map { name in
                                    Image(systemName: name)
                                }
                            }
                            .foregroundColor(Color(uiColor: viewModel.currentConnectionStep.tintColor))
                            .renderedIf(step == .connection)
                        }
                    }
                }
                .padding(.top, Constants.contentVerticalSpacing)

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            Button {
                // TODO
            } label: {
                Text(Localization.goToStore)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, Constants.contentVerticalSpacing)
            .renderedIf(viewModel.currentSetupStep == .done)
        })
        .padding()
    }
}

private extension LoginJetpackSetupView {
    enum Localization {
        static let goToStore = NSLocalizedString("Go to Store", comment: "Title for the button to navigate to the home screen after Jetpack setup completes")
        static let authorizing = NSLocalizedString("Authorizing connection", comment: "Name of the connection step on the Jetpack setup screen")
    }

    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let stepItemHorizontalSpacing: CGFloat = 24
        static let stepItemsVerticalSpacing: CGFloat = 20
        static let stepImageSize: CGFloat = 24
    }
}

struct LoginJetpackSetupView_Previews: PreviewProvider {
    static var previews: some View {
        LoginJetpackSetupView(viewModel: LoginJetpackSetupViewModel(siteURL: "https://test.com", connectionOnly: true))
        LoginJetpackSetupView(viewModel: LoginJetpackSetupViewModel(siteURL: "https://test.com", connectionOnly: false))
    }
}
