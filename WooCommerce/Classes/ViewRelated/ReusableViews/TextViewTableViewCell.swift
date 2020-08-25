import UIKit
import Gridicons

class TextViewTableViewCell: UITableViewCell {
    struct ViewModel {
        var icon: UIImage? = nil
        var iconAccessibilityLabel: String? = nil
        var iconTint: UIColor? = nil
        var text: String? = nil
        var placeholder: String? = nil
        var textViewMinimumHeight: CGFloat? = nil
        var isScrollEnabled: Bool = true
        var onTextChange: ((_ text: String) -> Void)? = nil
        var onTextDidBeginEditing: (() -> Void)? = nil
        var keyboardType: UIKeyboardType = .default
        var style: Style = .body
    }

    @IBOutlet private weak var noteIconView: UIView!
    @IBOutlet private var noteIconButton: UIButton!

    @IBOutlet private var noteTextView: EnhancedTextView!

    @IBOutlet private weak var textViewHeightConstraint: NSLayoutConstraint!

    private var viewModel: ViewModel?

    private var iconImage: UIImage? {
        get {
            return noteIconButton.image(for: .normal)
        }
        set {
            noteIconButton.setImage(newValue, for: .normal)
            noteIconButton.tintColor = .listForeground
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

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTextView()

        noteIconButton.accessibilityTraits = .image
    }

    func configure(viewModel: ViewModel) {
        self.viewModel = viewModel

        iconImage = viewModel.icon
        iconImage?.accessibilityLabel = viewModel.iconAccessibilityLabel
        iconTint = viewModel.iconTint
        noteTextView.text = viewModel.text
        noteTextView.placeholder = viewModel.placeholder
        if let minimumHeight = viewModel.textViewMinimumHeight {
            textViewHeightConstraint.constant = minimumHeight
        }
        noteTextView.isScrollEnabled = viewModel.isScrollEnabled
        noteTextView.onTextChange = viewModel.onTextChange
        noteTextView.onTextDidBeginEditing = viewModel.onTextDidBeginEditing
        noteTextView.keyboardType = viewModel.keyboardType
        self.applyStyle(style: viewModel.style)
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        noteTextView.becomeFirstResponder()
    }
}

// Styles
extension TextViewTableViewCell {

    enum Style {
        case body
        case headline
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
        }
    }
}

// Private methods
private extension TextViewTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureTextView() {
        noteTextView.backgroundColor = .listForeground
    }
}
