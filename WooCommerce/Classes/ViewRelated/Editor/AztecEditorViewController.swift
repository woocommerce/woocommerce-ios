import UIKit
import Aztec
import Gridicons
import WordPressEditor

// MARK: - Aztec's Native Editor!
//
class AztecEditorViewController: UIViewController, Editor {
    var onContentSave: OnContentSave?

    private let content: String

    /// The editor view.
    ///
    private(set) lazy var editorView: Aztec.EditorView = {

        let paragraphStyle = ParagraphStyle.default

        // Paragraph style customizations will go here.
        paragraphStyle.lineSpacing = 4
        let missingIcon = UIImage.errorStateImage

        let editorView = Aztec.EditorView(
            defaultFont: StyleManager.subheadlineFont,
            defaultHTMLFont: StyleManager.subheadlineFont,
            defaultParagraphStyle: paragraphStyle,
            defaultMissingImage: missingIcon)

        editorView.clipsToBounds = false
        setupHTMLTextView(editorView.htmlTextView)
        setupRichTextView(editorView.richTextView)

        return editorView
    }()

    /// Format Bar
    ///
    fileprivate(set) lazy var formatBar: Aztec.FormatBar = {
        return createToolbar()
    }()

    private var scrollableItemsForToolbar: [FormatBarItem] {
        return []
    }

    var overflowItemsForToolbar: [FormatBarItem] {
        return []
    }

    // MARK: - Styling Options

    private lazy var optionsTablePresenter = OptionsTablePresenter(presentingViewController: self, presentingTextView: editorView.richTextView)

    /// Aztec's Awesomeness
    ///
    private var richTextView: Aztec.TextView {
        get {
            return editorView.richTextView
        }
    }

    /// Aztec's Raw HTML Editor
    ///
    private var htmlTextView: UITextView {
        get {
            return editorView.htmlTextView
        }
    }

    /// Aztec's Text Placeholder
    ///
    fileprivate(set) lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Start writing...", comment: "Aztec's Text Placeholder")
        label.textColor = StyleManager.wooGreyMid
        label.font = StyleManager.subheadlineFont
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.accessibilityIdentifier = "aztec-content-placeholder"
        return label
    }()

    /// Current keyboard rect used to help size the inline media picker
    ///
    fileprivate var currentKeyboardFrame: CGRect = .zero

    required init(content: String?) {
        self.content = content ?? ""
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        registerAttachmentImageProviders()

        configureNavigationBar()
        configureView()
        configureSubviews()

        configureConstraints()

        setHTML(content)

        refreshPlaceholderVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningToNotifications()
    }
}

private extension AztecEditorViewController {
    func configureNavigationBar() {
        title = NSLocalizedString("Description", comment: "The navigation bar title of the Product description editor screen.")

        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.accessibilityIdentifier = "Aztec Editor Navigation Bar"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveButtonTapped))
    }

    func configureView() {
        edgesForExtendedLayout = UIRectEdge()
        view.backgroundColor = StyleManager.wooWhite
    }

    func configureSubviews() {
        view.addSubview(richTextView)
        view.addSubview(htmlTextView)
        view.addSubview(placeholderLabel)
    }

    private func setupHTMLTextView(_ textView: UITextView) {
        let accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        textView.isHidden = true
        textView.delegate = self
        textView.accessibilityIdentifier = "HTMLContentView"
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none

        // We need this false to be able to set negative `scrollInset` values.
        textView.clipsToBounds = false

        textView.adjustsFontForContentSizeCategory = true
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
    }

    private func setupRichTextView(_ textView: TextView) {
        textView.load(WordPressPlugin())

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        let linkAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                             .foregroundColor: StyleManager.wooCommerceBrandColor]

        textView.delegate = self
        textView.textAttachmentDelegate = self
        textView.backgroundColor = StyleManager.wooWhite
        textView.linkTextAttributes = linkAttributes

        // We need this false to be able to set negative `scrollInset` values.
        textView.clipsToBounds = false

        textView.smartDashesType = .no
        textView.smartQuotesType = .no
    }

    private func configureDefaultProperties(for textView: UITextView, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.keyboardDismissMode = .interactive
        textView.textColor = UIColor.darkText
        textView.translatesAutoresizingMaskIntoConstraints = false
    }

    func configureConstraints() {
        NSLayoutConstraint.activate([
            richTextView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            richTextView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            richTextView.topAnchor.constraint(equalTo: view.topAnchor),
            richTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            htmlTextView.leftAnchor.constraint(equalTo: richTextView.leftAnchor),
            htmlTextView.rightAnchor.constraint(equalTo: richTextView.rightAnchor),
            htmlTextView.topAnchor.constraint(equalTo: richTextView.topAnchor),
            htmlTextView.bottomAnchor.constraint(equalTo: richTextView.bottomAnchor)
            ])

        let insets = richTextView.textContainerInset

        NSLayoutConstraint.activate([
            placeholderLabel.leftAnchor.constraint(equalTo: richTextView.leftAnchor, constant: insets.left + richTextView.textContainer.lineFragmentPadding),
            placeholderLabel.rightAnchor.constraint(equalTo: richTextView.rightAnchor, constant: -insets.right - richTextView.textContainer.lineFragmentPadding),
            placeholderLabel.topAnchor.constraint(equalTo: richTextView.topAnchor, constant: insets.top),
            placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: richTextView.bottomAnchor, constant: insets.bottom)
            ])
    }

    func registerAttachmentImageProviders() {
        let providers: [TextViewAttachmentImageProvider] = [
            SpecialTagAttachmentRenderer(),
            CommentAttachmentRenderer(font: StyleManager.subheadlineBoldFont),
            HTMLAttachmentRenderer(font: StyleManager.subheadlineBoldFont),
            GutenpackAttachmentRenderer()
        ]

        for provider in providers {
            richTextView.registerAttachmentImageProvider(provider)
        }
    }

    func createToolbar() -> Aztec.FormatBar {
        let toolbar = Aztec.FormatBar()

        toolbar.tintColor = StyleManager.wooCommerceBrandColor
        toolbar.highlightedTintColor = StyleManager.wooCommerceBrandColor.withAlphaComponent(0.5)
        toolbar.selectedTintColor = StyleManager.wooSecondary
        toolbar.disabledTintColor = StyleManager.buttonDisabledColor
        toolbar.dividerTintColor = StyleManager.cellSeparatorColor
        toolbar.overflowToggleIcon = Gridicon.iconOfType(.ellipsis)

        updateToolbar(toolbar)

        return toolbar
    }

    func updateToolbar(_ toolbar: Aztec.FormatBar) {
        toolbar.trailingItem = nil

        toolbar.setDefaultItems(scrollableItemsForToolbar,
                                overflowItems: overflowItemsForToolbar)
    }
}

private extension AztecEditorViewController {
    func setHTML(_ html: String) {
        editorView.setHTML(html)
    }

    func getHTML() -> String {
        return editorView.getHTML()
    }

    func refreshPlaceholderVisibility() {
        placeholderLabel.isHidden = richTextView.isHidden || !richTextView.text.isEmpty
    }
}

private extension AztecEditorViewController {

    @objc func keyboardWillShow(_ notification: Foundation.Notification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }
        // Convert the keyboard frame from window base coordinate
        currentKeyboardFrame = view.convert(keyboardFrame, from: nil)
        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    @objc func keyboardDidHide(_ notification: Foundation.Notification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        currentKeyboardFrame = .zero
        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        let referenceView = editorView.activeView

        let contentInsets  = UIEdgeInsets(top: referenceView.contentInset.top, left: 0, bottom: view.frame.maxY - (keyboardFrame.minY + self.view.layoutMargins.bottom), right: 0)

        htmlTextView.contentInset = contentInsets
        richTextView.contentInset = contentInsets

        updateScrollInsets()
    }

    func updateScrollInsets() {
        let referenceView = editorView.activeView
        var scrollInsets = referenceView.contentInset
        var rightMargin = (view.frame.maxX - referenceView.frame.maxX)
        rightMargin -= view.safeAreaInsets.right
        scrollInsets.right = -rightMargin
        referenceView.scrollIndicatorInsets = scrollInsets
    }
}

// MARK: - Notifications
//
private extension AztecEditorViewController {
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        nc.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc func applicationWillResignActive(_ notification: Foundation.Notification) {

        // [2018-03-05] Need to close the options VC on backgrounding to prevent view hierarchy inconsistency crasher.
        optionsTablePresenter.dismiss()
    }
}

// MARK: - Navigation actions
//
private extension AztecEditorViewController {
    @objc func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc func saveButtonTapped() {
        let content = getHTML()
        onContentSave?(content)

        navigationController?.popViewController(animated: true)
    }
}

// MARK: - TextViewAttachmentDelegate Conformance
//
extension AztecEditorViewController: TextViewAttachmentDelegate {
    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {

    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        return nil
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return UIImage.cameraImage
    }

    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {

    }

    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {

    }

    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {

    }
}

private extension AztecEditorViewController {
    func updateFormatBar() {
        switch editorView.editingMode {
        case .html:
            updateFormatBarForHTMLMode()
        case .richText:
            updateFormatBarForVisualMode()
        }
    }

    /// Updates the format bar for HTML mode.
    ///
    func updateFormatBarForHTMLMode() {
        assert(editorView.editingMode == .html)

        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        toolbar.selectItemsMatchingIdentifiers([FormattingIdentifier.sourcecode.rawValue])
    }

    /// Updates the format bar for visual mode.
    ///
    func updateFormatBarForVisualMode() {
        assert(editorView.editingMode == .richText)

        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        var identifiers = Set<FormattingIdentifier>()

        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }

        toolbar.selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
    }
}

// MARK: - UITextViewDelegate methods
//
extension AztecEditorViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        refreshPlaceholderVisibility()
        updateFormatBar()
    }

    func textViewDidChange(_ textView: UITextView) {
        refreshPlaceholderVisibility()

        switch textView {
        case richTextView:
            updateFormatBar()
        default:
            break
        }
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.textAlignment = .natural

        let htmlButton = formatBar.items.first(where: { $0.identifier == FormattingIdentifier.sourcecode.rawValue })

        switch textView {
        case richTextView:
            formatBar.enabled = true
        case htmlTextView:
            formatBar.enabled = false
        default:
            break
        }

        htmlButton?.isEnabled = true

        textView.inputAccessoryView = formatBar

        return true
    }
}

// MARK: - Constants
//
extension AztecEditorViewController {
    enum Constants {
        static let headers = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
        static let lists = [TextList.Style.unordered, .ordered]
        static let moreAttachmentText = "more"
    }
}
