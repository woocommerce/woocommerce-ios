import Combine
import UIKit
import WebKit
import struct Networking.ApplicationPassword

/// View with embedded web view to authorize application password for a site.
///
final class ApplicationPasswordAuthorizationWebViewController: UIViewController {

    /// Callback when application password is authorized.
    private let onSuccess: (ApplicationPassword, UINavigationController?) -> Void

    /// Main web view
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    /// Progress bar for the web view
    private lazy var progressBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    /// WP Core requires that the UUID has lowercased letters.
    private let appID = UUID().uuidString.lowercased()

    /// Name of the app to display in the authorization page
    private lazy var appName: String = {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Unknown"
        let model = UIDevice.current.model
        return bundleIdentifier + ".ios-app-client." + model
    }()

    private let viewModel: ApplicationPasswordAuthorizationViewModel
    private var subscriptions: Set<AnyCancellable> = []

    init(viewModel: ApplicationPasswordAuthorizationViewModel,
         onSuccess: @escaping (ApplicationPassword, UINavigationController?) -> Void) {
        self.viewModel = viewModel
        self.onSuccess = onSuccess
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureWebView()
        configureProgressBar()
        configureActivityIndicator()
        fetchAuthorizationURL()
    }
}

private extension ApplicationPasswordAuthorizationWebViewController {
    func configureNavigationBar() {
        title = Localization.login
    }

    func configureWebView() {
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            view.safeTopAnchor.constraint(equalTo: webView.topAnchor),
            view.safeBottomAnchor.constraint(equalTo: webView.bottomAnchor),
        ])

        extendContentUnderSafeAreas()
        webView.configureForSandboxEnvironment()

        webView.publisher(for: \.estimatedProgress)
            .sink { [weak self] progress in
                if progress == 1 {
                    self?.progressBar.setProgress(0, animated: false)
                } else {
                    self?.progressBar.setProgress(Float(progress), animated: true)
                }
            }
            .store(in: &subscriptions)

        webView.publisher(for: \.url)
            .sink { [weak self] url in
                self?.handleAuthorizationResponse(with: url)
            }
            .store(in: &subscriptions)
    }

    func extendContentUnderSafeAreas() {
        webView.scrollView.clipsToBounds = false
        view.backgroundColor = webView.underPageBackgroundColor
    }

    func configureProgressBar() {
        view.addSubview(progressBar)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: progressBar.trailingAnchor),
            view.safeTopAnchor.constraint(equalTo: progressBar.topAnchor)
        ])
    }

    func configureActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: activityIndicator.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor)
        ])
    }

    func fetchAuthorizationURL() {
        Task { @MainActor in
            activityIndicator.startAnimating()
            do {
                guard let url = try await viewModel.fetchAuthURL() else {
                    DDLogError("⛔️ No authorization URL found for application passwords")
                    return showErrorAlert(message: Localization.applicationPasswordDisabled)
                }
                loadAuthorizationPage(url: url)
            } catch {
                DDLogError("⛔️ Error fetching authorization URL for application passwords \(error)")
                showErrorAlert(message: Localization.errorFetchingAuthURL, onRetry: { [weak self] in
                    self?.fetchAuthorizationURL()
                })
            }
            activityIndicator.stopAnimating()
        }
    }

    func loadAuthorizationPage(url: URL) {
        let parameters: [URLQueryItem] = [
            URLQueryItem(name: Constants.Query.appName, value: appName),
            URLQueryItem(name: Constants.Query.appID, value: appID),
            URLQueryItem(name: Constants.Query.successURL, value: Constants.successURL)
        ]
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = parameters
        guard let urlWithQueries = components?.url else {
            DDLogError("⛔️ Error building authorization URL request")
            return
        }
        let request = URLRequest(url: urlWithQueries)
        webView.load(request)
    }

    func handleAuthorizationResponse(with url: URL?) {
        guard let url, url.absoluteString.hasPrefix(Constants.successURL) else {
            return
        }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        guard let queryItems = components?.queryItems,
              let username = queryItems.first(where: { $0.name == Constants.Query.username })?.value,
              let password = queryItems.first(where: { $0.name == Constants.Query.password })?.value else {
            DDLogError("⛔️ Authorization rejected for application passwords")
            return showErrorAlert(message: Localization.authorizationRejected)
        }

        // hide content and show loading indicator
        webView.isHidden = true
        progressBar.setProgress(0, animated: false)
        activityIndicator.startAnimating()

        let applicationPassword = ApplicationPassword(wpOrgUsername: username, password: .init(password), uuid: "", appID: appID)
        onSuccess(applicationPassword, navigationController)
        DDLogInfo("✅ Application password authorized")
    }

    func showErrorAlert(message: String, onRetry: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: Localization.cancel, style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(action)
        if let onRetry {
            let retryAction = UIAlertAction(title: Localization.tryAgain, style: .default) { _ in
                onRetry()
            }
            alertController.addAction(retryAction)
        }
        present(alertController, animated: true)
    }
}

private extension ApplicationPasswordAuthorizationWebViewController {
    enum Constants {
        static let successURL = "woocommerce://application-password"
        enum Query {
            static let username = "user_login"
            static let password = "password"
            static let appName = "app_name"
            static let appID = "app_id"
            static let successURL = "success_url"
        }
    }
    enum Localization {
        static let login = NSLocalizedString("Log In", comment: "Title for the application password authorization web view")
        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the view or error alerts of the application password authorization web view"
        )
        static let tryAgain = NSLocalizedString("Retry", comment: "Button to retry fetching application password authorization URL during login")
        static let authorizationRejected = NSLocalizedString(
            "Unable to log in because the request to use application passwords to your site has been rejected.",
            comment: "Error message displayed when the user rejects application password authorization request during login"
        )
        static let applicationPasswordDisabled = NSLocalizedString(
            "Unable to log in because application passwords are disabled on your site.",
            comment: "Error message displayed when application password authorization fails " +
            "during login due to the feature being disabled on the input site."
        )
        static let errorFetchingAuthURL = NSLocalizedString(
            "Failed to fetch the authorization URL for application passwords. Please try again.",
            comment: "Error message displayed when failed to fetch application password authorization URL during login"
        )
    }
}
