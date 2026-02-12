import SwiftUI
import UIKit
import Combine
import Yosemite

/// Hosting controller for `WPComConnectionSetupView`
final class WPComConnectionSetupHostingController: UIHostingController<WPComConnectionSetupView> {

    private let viewModel: WPComConnectionSetupViewModel
    private let credentials: Credentials?
    private var connectionWebView: UINavigationController?
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: WPComConnectionSetupViewModel, credentials: Credentials? = nil) {
        self.viewModel = viewModel
        self.credentials = credentials
        super.init(rootView: WPComConnectionSetupView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
        observeWebViewPresentation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}

// MARK: - Web View Presentation
private extension WPComConnectionSetupHostingController {
    func observeWebViewPresentation() {
        viewModel.$webViewPresentation
            .compactMap { $0 }
            .sink { [weak self] presentation in
                self?.presentJetpackConnectionWebView(with: presentation.url, siteURL: presentation.siteURL)
            }
            .store(in: &cancellables)
    }

    func presentJetpackConnectionWebView(with url: URL, siteURL: String) {
        let webViewModel = JetpackConnectionWebViewModel(
            initialURL: url,
            siteURL: siteURL,
            completion: { [weak self] in
                guard let self else { return }
                self.dismissWebView()
                self.viewModel.didAuthorizeWebViewConnection()
            },
            onAuthorization: { [weak self] url in
                self?.presentJetpackConnectionWebView(with: url, siteURL: siteURL)
            },
            onFailure: { [weak self] errorCode in
                guard let self else { return }
                self.dismissWebView()
                self.viewModel.didEncounterWebViewError(code: errorCode)
            },
            onDismissal: { [weak self] in
                self?.viewModel.didCancelWebView()
            }
        )

        let webView = AuthenticatedWebViewController(viewModel: webViewModel, extraCredentials: credentials)
        webView.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Localization.cancel,
            style: .plain,
            target: self,
            action: #selector(dismissWebView)
        )

        if let connectionWebView {
            connectionWebView.viewControllers = [webView]
        } else {
            let navigationController = UINavigationController(rootViewController: webView)
            present(navigationController, animated: true)
            connectionWebView = navigationController
        }
    }

    @objc func dismissWebView() {
        connectionWebView?.dismiss(animated: true)
        connectionWebView = nil
    }
}

private extension WPComConnectionSetupHostingController {
    enum Localization {
        static let cancel = NSLocalizedString(
            "wpComConnectionSetupHostingController.cancel",
            value: "Cancel",
            comment: "Cancel button in the Jetpack connection web view."
        )
    }
}

struct WPComConnectionSetupView: View {
    @ObservedObject var viewModel: WPComConnectionSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    ConnectWPComHeaderView()
                    VStack(alignment: .leading, spacing: Constants.headerVerticalSpacing) {
                        Text(Localization.title)
                            .largeTitleStyle()
                            .bold()
                        Text(viewModel.subtitleAttributedString)
                    }
                    VStack(alignment: .leading, spacing: Constants.stepsVerticalSpacing) {
                        ForEach(viewModel.steps) { step in
                            WPComConnectionSetupStepView(step: step)
                        }
                    }
                }

                Spacer()

                if dynamicTypeSize.isAccessibilitySize {
                    footer
                }
            }
            .padding(Constants.contentPadding)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        viewModel.cancelTapped()
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                footer
                    .padding(Constants.contentPadding)
                    .background(Color(uiColor: .systemBackground))
                    .renderedIf(!dynamicTypeSize.isAccessibilitySize)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder var footer: some View {
        VStack {
            Button(viewModel.primaryButtonTitle) {
                viewModel.primaryButtonTapped()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.isPrimaryButtonEnabled)

            Button(viewModel.secondaryButtonTitle) {
                viewModel.secondaryButtonTapped()
            }
            .buttonStyle(SecondaryButtonStyle())
            .renderedIf(viewModel.isShowingSecondaryButton)
        }
    }
}

private extension WPComConnectionSetupView {
    enum Constants {
        static let contentVerticalSpacing: CGFloat = 32
        static let stepsVerticalSpacing: CGFloat = 32
        static let headerVerticalSpacing: CGFloat = 24
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString(
            "wpComConnectionSetupView.title",
            value: "Connect to WordPress.com",
            comment: "Title for the WPCom connection setup screen."
        )
        static let cancelButton = NSLocalizedString(
            "wpComConnectionSetupView.cancelButton",
            value: "Cancel",
            comment: "Cancel button title in the WPCom connection setup screen toolbar."
        )
    }
}

#Preview {
    let viewModel = WPComConnectionSetupViewModel(
        storeName: "coffeebeans.com",
        handler: WPComConnectionSetupHandler(siteID: 123, siteURL: "https://example.com", credentials: nil),
        onDismiss: {},
        onGoToStore: {},
        onUpdatePlugin: {}
    )
    WPComConnectionSetupView(viewModel: viewModel)
}
