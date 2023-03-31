import SwiftUI
import enum Yosemite.Credentials

/// Hosting controller for `JetpackSetupView`.
///
final class JetpackSetupHostingController: UIHostingController<JetpackSetupView> {
    private let viewModel: JetpackSetupViewModel
    private let authentication: Authentication
    private let connectionWebViewCredentials: Credentials?

    init(siteURL: String,
         connectionOnly: Bool,
         connectionWebViewCredentials: Credentials? = nil,
         authentication: Authentication = ServiceLocator.authenticationManager,
         onStoreNavigation: @escaping (String?) -> Void) {
        self.viewModel = JetpackSetupViewModel(siteURL: siteURL, connectionOnly: connectionOnly, onStoreNavigation: onStoreNavigation)
        self.authentication = authentication
        self.connectionWebViewCredentials = connectionWebViewCredentials
        super.init(rootView: JetpackSetupView(viewModel: viewModel))

        rootView.webViewPresentationHandler = { [weak self] in
            self?.presentJetpackConnectionWebView()
        }

        rootView.supportHandler = { [weak self] in
            guard let self else { return }

            self.viewModel.trackSetupDuringLogin(.loginJetpackSetupScreenGetSupportTapped, properties: self.viewModel.currentSetupStep?.analyticsDescription)
            self.viewModel.trackSetupAfterLogin(tap: .support)
            self.presentSupport()
        }

        rootView.cancellationHandler = dismissView
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.trackSetupDuringLogin(.loginJetpackSetupScreenViewed)
        configureNavigationBarAppearance()
    }

    /// Shows a transparent navigation bar without a bottom border.
    private func configureNavigationBarAppearance() {
        configureTransparentNavigationBar()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
    }

    @objc
    private func dismissView() {
        viewModel.trackSetupDuringLogin(.loginJetpackSetupScreenDismissed, properties: viewModel.currentSetupStep?.analyticsDescription)
        viewModel.trackSetupAfterLogin(tap: .dismiss)
        dismiss(animated: true)
    }

    @objc
    private func dismissWebView() {
        dismiss(animated: true)
    }

    private func presentJetpackConnectionWebView() {
        guard let connectionURL = viewModel.jetpackConnectionURL else {
            return
        }

        let webViewModel = JetpackConnectionWebViewModel(initialURL: connectionURL,
                                                         siteURL: viewModel.siteURL,
                                                         completion: { [weak self] in
            guard let self else { return }
            self.viewModel.shouldPresentWebView = false
            self.viewModel.didAuthorizeJetpackConnection()
            self.dismissView()
        }, onDismissal: { [weak self] in
            guard let self else { return }
            self.viewModel.jetpackConnectionInterrupted = true
        })
        let webView = AuthenticatedWebViewController(viewModel: webViewModel, extraCredentials: connectionWebViewCredentials)
        webView.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel,
                                                                   style: .plain,
                                                                   target: self,
                                                                   action: #selector(self.dismissWebView))
        let navigationController = UINavigationController(rootViewController: webView)
        self.present(navigationController, animated: true)
    }

    private func presentSupport() {
        // dismiss any presented view if possible
        presentedViewController?.dismiss(animated: true)
        authentication.presentSupport(from: self, screen: .jetpackRequired)
    }
}

private extension JetpackSetupHostingController {
    enum Localization {
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the site credential login screen")
    }
}

/// View to show the process of Jetpack setup for non-JCP sites.
/// For JCP sites, look for `JCPJetpackInstallView`.
///
struct JetpackSetupView: View {
    /// To be set by the hosting controller
    var webViewPresentationHandler: () -> Void = {}

    /// Triggered when the user choose to cancel setup after failure. To be set by the hosting controller.
    var cancellationHandler: () -> Void = {}

    /// Triggered when the user selects Get support.
    var supportHandler: () -> Void = {}

    @ObservedObject private var viewModel: JetpackSetupViewModel

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    init(viewModel: JetpackSetupViewModel) {
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
                        if viewModel.isSetupStepFailed(step) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .resizable()
                                .frame(width: Constants.stepImageSize * scale, height: Constants.stepImageSize * scale)
                                .foregroundColor(Color(uiColor: .error))
                        } else if viewModel.isSetupStepInProgress(step) {
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
                            // Title of the setup step
                            Text(step == .connection ? Localization.authorizing : step.title)
                                .font(.body)
                                .if(viewModel.isSetupStepPending(step) == false) {
                                    $0.bold()
                                }
                                .foregroundColor(Color(.text))
                                .opacity(viewModel.isSetupStepPending(step) == false ? 1 : 0.5)

                            // Status of the connection step
                            viewModel.currentConnectionStep.map { step in
                                Text(step.title)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(uiColor: step.tintColor))
                            }
                            .renderedIf(step == .connection)

                            // Error label
                            Text(Localization.error)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(uiColor: .error))
                                .renderedIf(viewModel.isSetupStepFailed(step))
                        }
                    }
                }
                .padding(.top, Constants.contentVerticalSpacing)
                .renderedIf(viewModel.shouldShowSetupSteps)

                // Error state contents: title and messages
                viewModel.setupErrorDetail.map { detail in
                    VStack(alignment: .leading, spacing: Constants.errorContentSpacing) {
                        Text(detail.setupErrorMessage)
                            .font(.title2)
                            .foregroundColor(Color(uiColor: .label))
                        Text(detail.setupErrorSuggestion)
                            .font(.body)
                            .foregroundColor(Color(uiColor: .label))
                        detail.errorCode.map { code in
                            Text(String.localizedStringWithFormat(Localization.errorCode, code))
                                .font(.footnote)
                                .bold()
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }

                        // Support button
                        Button {
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
                }

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            // Go to Store button
            Button {
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
            JetpackSetupInterruptedView(siteURL: viewModel.siteURL, onSupport: {
                viewModel.shouldPresentWebView = false
                supportHandler()
            }, onContinue: {
                viewModel.shouldPresentWebView = false
                viewModel.jetpackConnectionInterrupted = false
                viewModel.didTapContinueConnectionButton()
            }, onCancellation: {
                viewModel.shouldPresentWebView = false
                viewModel.jetpackConnectionInterrupted = false
                // delay for the dismissal of the interrupted screen to complete.
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.interruptedConnectionActionHandlerDelayTime) {
                    cancellationHandler()
                }
            })
        }
    }
}

private extension JetpackSetupView {
    enum Localization {
        static let goToStore = NSLocalizedString("Go to Store", comment: "Title for the button to navigate to the home screen after Jetpack setup completes")
        static let authorizing = NSLocalizedString("Connect store to Jetpack", comment: "Name of the connection step on the Jetpack setup screen")
        static let errorCode = NSLocalizedString("Error code %1$d", comment: "Error code displayed when the Jetpack setup fails. %1$d is the code.")
        static let getSupport = NSLocalizedString("Get support", comment: "Button to contact support when Jetpack setup fails")
        static let cancelInstallation = NSLocalizedString("Cancel Installation", comment: "Action button to cancel Jetpack installation.")
        static let error = NSLocalizedString("Error", comment: "Title indicating a failed step in Jetpack installation.")
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

struct JetpackSetupView_Previews: PreviewProvider {
    static var previews: some View {
        JetpackSetupView(viewModel: JetpackSetupViewModel(siteURL: "https://test.com", connectionOnly: true))
        JetpackSetupView(viewModel: JetpackSetupViewModel(siteURL: "https://test.com", connectionOnly: false))
    }
}
