import Foundation
import UIKit


/// Activity Indicator, meant for UITableView.footerView usage.
///
final class FooterSpinnerView: UIView {

    /// Activity Spinner!
    ///
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)

    /// Designated Initializer
    ///
    init() {
        super.init(frame: Settings.defaultFrame)
        setupSubviews()
    }

    /// Required Initializer
    ///
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    /// Setup: Subview Hierarchy
    ///
    private func setupSubviews() {
        addSubview(activityIndicatorView)
        activityIndicatorView.color = .text
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: activityIndicatorView.leadingAnchor),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: activityIndicatorView.trailingAnchor),
            centerYAnchor.constraint(equalTo: activityIndicatorView.centerYAnchor)
            ])
    }

    /// Starts the spinner animation
    ///
    func startAnimating() {
        activityIndicatorView.startAnimating()
    }

    /// Stops the spinner animation
    ///
    func stopAnimating() {
        activityIndicatorView.stopAnimating()
    }
}


// MARK: - Nested Types
//
private extension FooterSpinnerView {

    enum Settings {
        static let defaultFrame = CGRect(x: 0, y: 0, width: 320, height: 45)
    }
}
