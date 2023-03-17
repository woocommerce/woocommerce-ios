import Combine
import UIKit
import WebKit
import struct Networking.ApplicationPassword

/// View with embedded web view to authorize application password for a site.
///
final class ApplicationPasswordAuthorizationWebViewController: UIViewController {

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

    private let viewModel: ApplicationPasswordAuthorizationViewModel
    private let successHandler: (ApplicationPassword, UINavigationController?) -> Void
    private var subscriptions: Set<AnyCancellable> = []

    init(viewModel: ApplicationPasswordAuthorizationViewModel,
         onSuccess: @escaping (ApplicationPassword, UINavigationController?) -> Void) {
        self.viewModel = viewModel
        self.successHandler = onSuccess
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
        loadAuthorizationURL()
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
                guard let url, url.absoluteString.hasPrefix(Constants.successURL) else {
                    return
                }
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

    func loadAuthorizationURL() {
        Task { @MainActor in
            activityIndicator.startAnimating()
            do {
                guard let url = try await viewModel.fetchAuthURL() else {
                    // show error alert
                    return
                }
                let request = URLRequest(url: url)
                webView.load(request)
            } catch {
                // show error alert
            }
            activityIndicator.stopAnimating()
        }
    }

    func handleAuthorizationResponse(with url: URL) {
        // TODO
    }
}

private extension ApplicationPasswordAuthorizationWebViewController {
    enum Constants {
        static let successURL = "woocommerce://application-password"
    }
    enum Localization {
        static let login = "Log In"
    }
}
