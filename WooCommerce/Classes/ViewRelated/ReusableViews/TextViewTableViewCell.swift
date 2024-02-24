import UIKit
import Gridicons

/// A table view cell that contains an icon and a text view.
///
final class TextViewTableViewCell: UITableViewCell {
    struct ViewModel {
        var icon: UIImage? = nil
        var iconAccessibilityLabel: String? = nil
        var iconTint: UIColor? = nil
        var text: String? = nil
        var attributedText: NSAttributedString? = nil
        var placeholder: String? = nil
        var textViewMinimumHeight: CGFloat? = nil
        var isEditable: Bool = true
        var isSelectable: Bool = true
        var isScrollEnabled: Bool = true
        var onTextChange: ((_ text: String) -> Void)? = nil
        var onTextDidBeginEditing: (() -> Void)? = nil
        var keyboardType: UIKeyboardType = .default
        var style: Style = .body
        var edgeInsets: UIEdgeInsets?
        var onLinkTapped: ((URL) -> Void)?
    }

    @IBOutlet private weak var noteIconView: UIView!
    @IBOutlet private var noteIconButton: UIButton!

    @IBOutlet private var noteTextView: EnhancedTextView!

    /// Constraints
    @IBOutlet private weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomContraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingContraint: NSLayoutConstraint!
    @IBOutlet private weak var leadingContraint: NSLayoutConstraint!
    @IBOutlet private weak var topContraint: NSLayoutConstraint!

    private var iconImage: UIImage? {
        get {
            return noteIconButton.image(for: .normal)
        }
        set {
            noteIconButton.setImage(newValue, for: .normal)
            noteIconButton.tintColor = .listForeground(modal: false)
            noteIconButton.layer.cornerRadius = noteIconButton.frame.width / 2
            noteIconView.isHidden = newValue == nil
        }
    }

    private var iconTint: UIColor? {
        get {
            return noteIconButton.backgroundColor
        }
        set {
            noteIconButton.backgroundColor = newValue
        }
    }

    private var onLinkTapped: ((URL) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTextView()

        noteIconButton.accessibilityTraits = .image
    }

    func configure(with viewModel: ViewModel) {

        iconImage = viewModel.icon
        iconImage?.accessibilityLabel = viewModel.iconAccessibilityLabel
        iconTint = viewModel.iconTint
        noteTextView.text = viewModel.text
        noteTextView.attributedText = viewModel.attributedText
        noteTextView.placeholder = viewModel.placeholder
        if let minimumHeight = viewModel.textViewMinimumHeight {
            textViewHeightConstraint.constant = minimumHeight
        }
        noteTextView.isScrollEnabled = viewModel.isScrollEnabled
        noteTextView.onTextChange = viewModel.onTextChange
        noteTextView.onTextDidBeginEditing = viewModel.onTextDidBeginEditing
        noteTextView.keyboardType = viewModel.keyboardType
        noteTextView.isEditable = viewModel.isEditable
        noteTextView.isSelectable = viewModel.isSelectable
        if let onLinkTapped = viewModel.onLinkTapped {
            self.onLinkTapped = onLinkTapped
            noteTextView.delegate = self
        }
        self.applyStyle(style: viewModel.style)

        // Compensate for line fragment padding and container insets if icon is nil
        trailingContraint.constant = -(noteTextView.textContainer.lineFragmentPadding + noteTextView.textContainerInset.right)
        if iconImage == nil {
            leadingContraint.constant = -(noteTextView.textContainer.lineFragmentPadding + noteTextView.textContainerInset.left)
        } else {
            leadingContraint.constant = 0
        }

        if let edgeInsets = viewModel.edgeInsets {
            bottomContraint.constant = edgeInsets.bottom
            trailingContraint.constant += edgeInsets.right
            leadingContraint.constant += edgeInsets.left
            topContraint.constant = edgeInsets.top
        }
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        noteTextView.becomeFirstResponder()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}

extension TextViewTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let onLinkTapped {
            onLinkTapped(URL)
            return false
        }
        return true
    }
}

// Styles
extension TextViewTableViewCell {

    enum Style {
        case body
        case headline
        case caption
    }

    func applyStyle(style: Style) {
        switch style {
        case .body:
            noteTextView.adjustsFontForContentSizeCategory = true
            noteTextView.font = .body
            noteTextView.textColor = .text
        case .headline:
            noteTextView.adjustsFontForContentSizeCategory = true
            noteTextView.font = .headline
            noteTextView.textColor = .text
        case .caption:
            noteTextView.adjustsFontForContentSizeCategory = true
            noteTextView.font = .caption1
            noteTextView.textColor = .secondaryLabel
        }
    }
}

// Private methods
private extension TextViewTableViewCell {
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    func configureTextView() {
        noteTextView.backgroundColor = .listForeground(modal: false)
    }
}
