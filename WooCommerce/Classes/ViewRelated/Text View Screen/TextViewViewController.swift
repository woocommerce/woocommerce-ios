import UIKit

/// Contains an editable text view with a placeholder label when the text is empty.
///
final class TextViewViewController: UIViewController {

    typealias Completion = (_ text: String?) -> Void

    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var placeholderLabel: UILabel!

    // Placeholder label constraints.
    @IBOutlet private weak var placeholderLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var placeholderLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var placeholderLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var placeholderLabelBottomConstraint: NSLayoutConstraint!

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: handleKeyboardFrameUpdate(keyboardFrame:))
        return keyboardFrameObserver
    }()

    private let initialText: String?
    private let placeholder: String
    private let navigationTitle: String?
    private let keyboardType: UIKeyboardType
    private let autocapitalizationType: UITextAutocapitalizationType
    private let onCompletion: Completion

    init(text: String?,
         placeholder: String,
         navigationTitle: String?,
         keyboardType: UIKeyboardType = .default,
         autocapitalizationType: UITextAutocapitalizationType = .sentences,
         completion: @escaping Completion) {
        self.initialText = text
        self.placeholder = placeholder
        self.navigationTitle = navigationTitle
        self.keyboardType = keyboardType
        self.autocapitalizationType = autocapitalizationType
        self.onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTextView()
        configurePlaceholderLabel()
        refreshPlaceholderVisibility()
        startListeningToNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        textView.becomeFirstResponder()
    }
}

// MARK: - Navigation actions handling
//
extension TextViewViewController {
    override func shouldPopOnBackButton() -> Bool {
        if initialText != textView.text {
            presentBackNavigationActionSheet()
        }
        else {
            navigationController?.popViewController(animated: true)
        }
        return false
    }

    @objc private func completeEditing() {
        onCompletion(textView.text)
    }

    func presentBackNavigationActionSheet() {
        let actionSheetMessage = NSLocalizedString("Are you sure you want to discard these changes?",
                                                 comment: "Action sheet title in Edit Product > Edit Pricing")
        let actionSheet = UIAlertController(title: nil, message: actionSheetMessage, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addDefaultActionWithTitle(ActionSheetStrings.save) { [weak self] _ in
            self?.completeEditing()
        }

        actionSheet.addDestructiveActionWithTitle(ActionSheetStrings.discard) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }

        actionSheet.addCancelActionWithTitle(ActionSheetStrings.cancel)

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = view
        popoverController?.sourceRect = view.bounds

        present(actionSheet, animated: true)
    }
}

// MARK: Configurations
//
private extension TextViewViewController {
    func configureNavigation() {
        title = navigationTitle

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completeEditing))
    }

    func configureTextView() {
        textView.text = initialText
        textView.keyboardType = keyboardType
        textView.autocapitalizationType = autocapitalizationType

        textView.adjustsFontForContentSizeCategory = true
        textView.font = .body
        textView.textColor = .text
        textView.textContainerInset = Constants.textContainerInset

        textView.delegate = self
    }

    /// Note: configure the placeholder after the text view as the constraints depend on the text view insets.
    func configurePlaceholderLabel() {
        placeholderLabel.text = placeholder
        placeholderLabel.applyBodyStyle()
        placeholderLabel.textColor = .textSubtle

        let insets = textView.textContainerInset

        placeholderLabelLeadingConstraint.constant = insets.left + textView.textContainer.lineFragmentPadding
        placeholderLabelTrailingConstraint.constant = -insets.right - textView.textContainer.lineFragmentPadding
        placeholderLabelTopConstraint.constant = insets.top
        placeholderLabelBottomConstraint.constant = insets.bottom
    }
}

extension TextViewViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        refreshPlaceholderVisibility()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        refreshPlaceholderVisibility()
    }
}

// MARK: - Keyboard management
//
private extension TextViewViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension TextViewViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return textView
    }
}

// MARK: Helpers
//
private extension TextViewViewController {
    func refreshPlaceholderVisibility() {
        placeholderLabel.isHidden = textView.isHidden || !textView.text.isEmpty
    }
}

private extension TextViewViewController {
    enum Constants {
        static let textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    enum ActionSheetStrings {
        static let save = NSLocalizedString("Save changes",
                                            comment: "Button title in the action sheet in the generic text editor")
        static let discard = NSLocalizedString("Discard changes",
                                              comment: "Button title in the action sheet in the generic text editor")
        static let cancel = NSLocalizedString("Cancel",
                                              comment: "Dismiss the action sheet in the generic text editor")
    }

}
