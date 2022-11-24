import SwiftUI

/// Hosting controller for `LoginJetpackSetupView`.
///
final class LoginJetpackSetupHostingController: UIHostingController<LoginJetpackSetupView> {
    private let viewModel: LoginJetpackSetupViewModel
    private let authentication: Authentication

    init(siteURL: String,
         connectionOnly: Bool,
         authentication: Authentication = ServiceLocator.authenticationManager,
         onStoreNavigation: @escaping (String?) -> Void) {
        self.viewModel = LoginJetpackSetupViewModel(siteURL: siteURL, connectionOnly: connectionOnly, onStoreNavigation: onStoreNavigation)
        self.authentication = authentication
        super.init(rootView: LoginJetpackSetupView(viewModel: viewModel))

        rootView.webViewPresentationHandler = { [weak self] in
            self?.presentJetpackConnectionWebView()
        }

        rootView.supportHandler = { [weak self] in
            self?.presentSupport()
        }

        rootView.cancellationHandler = dismissView
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

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
    }

    @objc
    private func dismissView() {
        dismiss(animated: true)
    }

    private func presentJetpackConnectionWebView() {
        guard let connectionURL = viewModel.jetpackConnectionURL else {
            return
        }

        let webViewModel = JetpackConnectionWebViewModel(initialURL: connectionURL,
                                                         siteURL: viewModel.siteURL,
                                                         title: Localization.approveConnection,
                                                         completion: { [weak self] in
            guard let self else { return }
            self.viewModel.shouldPresentWebView = false
            self.viewModel.didAuthorizeJetpackConnection()
            self.dismissView()
        }, onDismissal: { [weak self] in
            guard let self else { return }
            self.viewModel.jetpackConnectionInterrupted = true
        })
        let webView = AuthenticatedWebViewController(viewModel: webViewModel)
        webView.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel,
                                                                   style: .plain,
                                                                   target: self,
                                                                   action: #selector(self.dismissView))
        let navigationController = UINavigationController(rootViewController: webView)
        self.present(navigationController, animated: true)
    }

    private func presentSupport() {
        // dismiss any presented view if possible
        presentedViewController?.dismiss(animated: true)
        authentication.presentSupport(from: self, screen: .jetpackRequired)
    }
}

private extension LoginJetpackSetupHostingController {
    enum Localization {
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the site credential login screen")
        static let approveConnection = NSLocalizedString("Approve connection", comment: "Title of the web view to approve Jetpack connection")
    }
}

/// View to show the process of Jetpack setup during login.
///
struct LoginJetpackSetupView: View {
    /// To be set by the hosting controller
    var webViewPresentationHandler: () -> Void = {}

    /// Triggered when the user choose to cancel setup after failure. To be set by the hosting controller.
    var cancellationHandler: () -> Void = {}

    /// Triggered when the user selects Get support.
    var supportHandler: () -> Void = {}

    @ObservedObject private var viewModel: LoginJetpackSetupViewModel

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    init(viewModel: LoginJetpackSetupViewModel) {
        self.viewModel = viewModel
        viewModel.startSetup()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView(isError: viewModel.setupFailed)

                // title and description
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    Text(viewModel.title)
                        .largeTitleStyle()
                    AttributedText(viewModel.descriptionAttributedString)
                        .renderedIf(viewModel.setupFailed == false)
                }

                // Loading indicator for when checking plugin details
                HStack {
                    Spacer()
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    Spacer()
                }
                .renderedIf(viewModel.shouldShowInitialLoadingIndicator)

                // Setup steps and progress
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
                                .if(viewModel.isSetupStepPending(step) == false) {
                                    $0.bold()
                                }
                                .foregroundColor(Color(.text))
                                .opacity(viewModel.isSetupStepPending(step) == false ? 1 : 0.5)
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
                .renderedIf(viewModel.shouldShowSetupSteps)

                // Error state contents: title and messages
                VStack(alignment: .leading, spacing: Constants.errorContentSpacing) {
                    Text(viewModel.setupErrorMessage)
                        .font(.title2)
                        .foregroundColor(Color(uiColor: .withColorStudio(.gray, shade: .shade80)))
                    Text(viewModel.setupErrorSuggestion)
                        .font(.body)
                        .foregroundColor(Color(uiColor: .withColorStudio(.gray, shade: .shade80)))
                    viewModel.errorCode.map { code in
                        Text(String.localizedStringWithFormat(Localization.errorCode, code))
                            .font(.footnote)
                            .bold()
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }

                    // Support button
                    Button {
                        // TODO: add tracks?
                        supportHandler()
                    } label: {
                        Label {
                            Text(Localization.getSupport)
                                .font(.body)
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "questionmark.circle")
                                .resizable()
                                .frame(width: Constants.supportImageSize * scale, height: Constants.supportImageSize * scale)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color(uiColor: .withColorStudio(.blue, shade: .shade50)))

                }
                .renderedIf(viewModel.setupFailed)
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            // Go to Store button
            Button {
                // TODO: add tracks
                viewModel.navigateToStore()
            } label: {
                Text(Localization.goToStore)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, Constants.contentVerticalSpacing)
            .renderedIf(viewModel.shouldShowGoToStoreButton)

            // Error state buttons: Retry and Cancel
            VStack(spacing: Constants.contentVerticalSpacing) {
                Button {
                    // TODO: add tracks
                    viewModel.retryAllSteps()
                } label: {
                    Text(viewModel.tryAgainButtonTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .renderedIf(viewModel.hasEncounteredPermissionError == false)

                Button {
                    // TODO: add tracks
                    cancellationHandler()
                } label: {
                    Text(Localization.cancelInstallation)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .renderedIf(viewModel.setupFailed)
        })
        .padding()
        .onChange(of: viewModel.shouldPresentWebView) { shouldPresent in
            if shouldPresent {
                webViewPresentationHandler()
            }
        }
        .fullScreenCover(isPresented: $viewModel.jetpackConnectionInterrupted) {
            LoginJetpackSetupInterruptedView(onSupport: supportHandler, onContinue: {
                viewModel.jetpackConnectionInterrupted = false
                // delay for the dismissal of the interrupted screen to complete.
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.interruptedConnectionActionHandlerDelayTime) {
                    webViewPresentationHandler()
                }
            }, onCancellation: {
                viewModel.jetpackConnectionInterrupted = false
                // delay for the dismissal of the interrupted screen to complete.
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.interruptedConnectionActionHandlerDelayTime) {
                    cancellationHandler()
                }
            })
        }
    }
}

private extension LoginJetpackSetupView {
    enum Localization {
        static let goToStore = NSLocalizedString("Go to Store", comment: "Title for the button to navigate to the home screen after Jetpack setup completes")
        static let authorizing = NSLocalizedString("Authorizing connection", comment: "Name of the connection step on the Jetpack setup screen")
        static let errorCode = NSLocalizedString("Error code %1$d", comment: "Error code displayed when the Jetpack setup fails. %1$d is the code.")
        static let getSupport = NSLocalizedString("Get support", comment: "Button to contact support when Jetpack setup fails")
        static let cancelInstallation = NSLocalizedString("Cancel Installation", comment: "Action button to cancel Jetpack installation.")
    }

    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let stepItemHorizontalSpacing: CGFloat = 24
        static let stepItemsVerticalSpacing: CGFloat = 20
        static let stepImageSize: CGFloat = 24
        static let supportImageSize: CGFloat = 18
        static let errorContentSpacing: CGFloat = 16
        static let interruptedConnectionActionHandlerDelayTime: Double = 0.3
    }
}

struct LoginJetpackSetupView_Previews: PreviewProvider {
    static var previews: some View {
        LoginJetpackSetupView(viewModel: LoginJetpackSetupViewModel(siteURL: "https://test.com", connectionOnly: true))
        LoginJetpackSetupView(viewModel: LoginJetpackSetupViewModel(siteURL: "https://test.com", connectionOnly: false))
    }
}
