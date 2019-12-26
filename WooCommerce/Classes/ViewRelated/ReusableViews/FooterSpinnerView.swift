import Foundation
import UIKit


/// Activity Indicator, meant for UITableView.footerView usage.
///
class FooterSpinnerView: UIView {

    /// Activity Spinner!
    ///
    private let activityIndicatorView = UIActivityIndicatorView(style: .gray)

    private let tableViewStyle: UITableView.Style

    /// Designated Initializer
    ///
    init(tableViewStyle: UITableView.Style) {
        self.tableViewStyle = tableViewStyle
        super.init(frame: Settings.defaultFrame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Setup: Subview Hierarchy
    ///
    private func setupSubviews() {
        addSubview(activityIndicatorView)
        activityIndicatorView.color = .text
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        switch tableViewStyle {
        case .plain:
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: activityIndicatorView.leadingAnchor),
                trailingAnchor.constraint(equalTo: activityIndicatorView.trailingAnchor),
                topAnchor.constraint(equalTo: activityIndicatorView.topAnchor, constant: 10),
                centerYAnchor.constraint(equalTo: activityIndicatorView.centerYAnchor)
                ])
        default:
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: activityIndicatorView.leadingAnchor),
                trailingAnchor.constraint(equalTo: activityIndicatorView.trailingAnchor),
                topAnchor.constraint(equalTo: activityIndicatorView.topAnchor)
                ])
        }
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
