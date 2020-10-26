import Foundation
import UIKit

/// Loading view to show a loader on top of a view
///
final class LoadingView: UIView {

    /// Main stack view to hold UI components vertically
    ///
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Layout.stackViewSpacing
        return stackView
    }()

    /// Label to indicate the user to wait
    ///
    private let waitLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    /// Extra Large and purple loading indicator
    ///
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.transform = CGAffineTransform(scaleX: Layout.indicatorScaleFactor, y: Layout.indicatorScaleFactor)
        indicator.startAnimating()
        return indicator
    }()

    init(waitMessage: String) {
        super.init(frame: CGRect.zero)
        addComponents()
        styleComponents()
        waitLabel.text = waitMessage
    }

    /// Adds and layouts components in the main view
    ///
    private func addComponents() {
        addSubview(mainStackView)
        mainStackView.addArrangedSubviews([waitLabel, loadingIndicator])
        pinSubviewToAllEdges(mainStackView, insets: Layout.stackViewEdges)
    }

    /// Applies custom styles to components
    ///
    private func styleComponents() {
        backgroundColor = .listBackground
        layer.cornerRadius = Layout.cornerRadius
        waitLabel.applyHeadlineStyle()
        loadingIndicator.color = .primary
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }
}

// MARK: Public Methods
extension LoadingView {
    func showLoader(in view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        alpha = 1.0
        isHidden = false
        view.addSubview(self)
        view.pinSubviewAtCenter(self)
    }

    func hideLoader() {
        fadeOut { [weak self] _ in
            self?.removeFromSuperview()
        }
    }
}

// MARK: Constants
private extension LoadingView {
    enum Layout {
        static let stackViewEdges = UIEdgeInsets(top: 38, left: 54, bottom: 48, right: 54)
        static let stackViewSpacing = CGFloat(40)
        static let indicatorScaleFactor = CGFloat(2.5)
        static let cornerRadius = CGFloat(14.5)
    }
}
