import UIKit

/// Displays a button inside a `UITableViewCell`.
///
final class ButtonTableViewCell: UITableViewCell {
    @IBOutlet private(set) var button: ButtonActivityIndicator!
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingConstraint: NSLayoutConstraint!

    /// The style of this view, particularly the button.
    enum Style {
        /// Uses the primary button style. This is the default.
        case primary
        /// Uses the secondary button style.
        case secondary
        /// Uses the subtle style with lighter background color.
        case subtle

        fileprivate static let `default` = Self.primary
    }

    private var onButtonTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        apply(style: .default)
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }

    /// Define this cell's UI attributes.
    ///
    /// - Parameters:
    ///   - style: The style of the cell.
    ///   - title: Button title.
    ///   - bottomSpacing: If non-nil, the value is set to the spacing between the button bottom edge and cell bottom edge.
    ///   - onButtonTouchUp: Called when the button is tapped.
    func configure(style: Style = .default,
                   title: String?,
                   image: UIImage? = nil,
                   accessibilityIdentifier: String? = nil,
                   topSpacing: CGFloat = Constants.defaultSpacing,
                   bottomSpacing: CGFloat = Constants.defaultSpacing,
                   onButtonTouchUp: (() -> Void)? = nil) {
        apply(style: style)
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.accessibilityIdentifier = accessibilityIdentifier
        self.onButtonTouchUp = onButtonTouchUp

        topConstraint.constant = topSpacing
        bottomConstraint.constant = bottomSpacing
    }

    func enableButton(_ enabled: Bool) {
        button.isEnabled = enabled
    }

    func showActivityIndicator(_ show: Bool) {
        guard show else {
            button.hideActivityIndicator()
            return
        }
        button.showActivityIndicator()
    }
}

private extension ButtonTableViewCell {
    @IBAction func sendButtonTouchUpEvent() {
        onButtonTouchUp?()
    }
}

private extension ButtonTableViewCell {
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    func apply(style: Style) {
        let pinsButtonToTrailingEdge: Bool
        switch style {
        case .primary:
            button.applyPrimaryButtonStyle()
            pinsButtonToTrailingEdge = true
        case .secondary:
            button.applySecondaryButtonStyle()
            pinsButtonToTrailingEdge = true
        case .subtle:
            button.applySubtleButtonStyle()
            pinsButtonToTrailingEdge = false
        }
        trailingConstraint?.isActive = pinsButtonToTrailingEdge
    }
}

extension ButtonTableViewCell {
    enum Constants {
        static let defaultSpacing = CGFloat(20)
    }
}

// MARK: - Previews

#if canImport(SwiftUI) && DEBUG

import SwiftUI

private struct ButtonTableViewCellRepresentable: UIViewRepresentable {
    typealias Style = ButtonTableViewCell.Style
    private let style: Style
    private let title: String

    init(style: Style, title: String) {
        self.style = style
        self.title = title
    }

    func makeUIView(context: Context) -> UIView {
        let cell: ButtonTableViewCell = .instantiateFromNib()
        cell.configure(style: style, title: title)
        return cell
    }

    func updateUIView(_ view: UIView, context: Context) {
        // noop
    }
}

struct ButtonTableViewCell_Previews: PreviewProvider {
    private static func makeStack() -> some View {
        VStack {
            ButtonTableViewCellRepresentable(style: .primary, title: "Primary button")
            ButtonTableViewCellRepresentable(style: .secondary, title: "Secondary button")
            ButtonTableViewCellRepresentable(style: .subtle, title: "Subtle button")
        }
    }

    static var previews: some View {
        Group {
            makeStack()
                .previewDisplayName("Light")

            makeStack()
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")

            makeStack()
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Large Font")
        }
    }
}

#endif
