import UIKit

// Pushed instantly on chat tap, swapped for the real detail once the fetch resolves.
final class AIAssistantLoadingPlaceholderViewController: UIViewController {

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Matches OrderDetailsViewController so the swap doesn't flash a different background.
        view.backgroundColor = .listBackground
        title = ""

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.accessibilityLabel = NSLocalizedString(
            "aiAssistant.loadingPlaceholder.accessibilityLabel",
            value: "Loading",
            comment: "Accessibility label for the loading spinner shown while a chat-linked detail is being fetched"
        )
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.startAnimating()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        activityIndicator.stopAnimating()
    }
}
