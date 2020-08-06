import Foundation
import UIKit

/// Loading view to show while the survey is loading
///
final class SurveyLoadingView: UIView {

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
        label.text = Localization.wait
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        addComponents()
        styleComponents()
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

// MARK: Constants
private extension SurveyLoadingView {
    enum Localization {
        static let wait = NSLocalizedString("Please wait", comment: "Text on the loading view of the survey screen indicating the user to wait")
    }

    enum Layout {
        static let stackViewEdges = UIEdgeInsets(top: 38, left: 54, bottom: 48, right: 54)
        static let stackViewSpacing = CGFloat(40)
        static let indicatorScaleFactor = CGFloat(2.5)
        static let cornerRadius = CGFloat(14.5)
    }
}
