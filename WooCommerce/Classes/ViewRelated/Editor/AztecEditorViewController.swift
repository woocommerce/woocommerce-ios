import UIKit
import Aztec
import WordPressEditor

/// Aztec's Native Editor!
final class AztecEditorViewController: UIViewController, Editor {
    var onContentSave: OnContentSave?

    private var content: String

    private let viewProperties: EditorViewProperties

    private let aztecUIConfigurator = AztecUIConfigurator()

    /// The editor view.
    ///
    private(set) lazy var editorView: Aztec.EditorView = {

        let paragraphStyle = ParagraphStyle.default
        paragraphStyle.lineSpacing = 4

        let missingIcon = UIImage.errorStateImage

        let editorView = Aztec.EditorView(
            defaultFont: StyleManager.subheadlineFont,
            defaultHTMLFont: StyleManager.subheadlineFont,
            defaultParagraphStyle: paragraphStyle,
            defaultMissingImage: missingIcon)

        aztecUIConfigurator.configureEditorView(editorView,
                                                textViewDelegate: self,
                                                textViewAttachmentDelegate: textViewAttachmentDelegate)

        return editorView
    }()

    /// Aztec's Awesomeness
    ///
    private var richTextView: Aztec.TextView {
        return editorView.richTextView
    }

    /// Aztec's Raw HTML Editor
    ///
    private var htmlTextView: UITextView {
        return editorView.htmlTextView
    }

    private lazy var formatBarFactory: AztecFormatBarFactory = {
        return AztecFormatBarFactory()
    }()

    /// Aztec's Format Bar (toolbar above the keyboard)
    ///
    private lazy var formatBar: Aztec.FormatBar = {
        let toolbar = formatBarFactory.formatBar() { [weak self] (formatBarItem, formatBar) in
            guard let self = self else {
                return
            }
            self.formatBarCommandCoordinator.handleAction(formatBarItem: formatBarItem,
                                                          editorView: self.editorView,
                                                          formatBar: formatBar)
            formatBar.update(editorView: self.editorView)
        }
        return toolbar
    }()

    /// Aztec's Format Bar Action Handling Coordinator
    ///
    private lazy var formatBarCommandCoordinator: AztecFormatBarCommandCoordinator = {
        return formatBarFactory.formatBarCommandCoordinator(optionsTablePresenter: optionsTablePresenter, linkDialogPresenter: self)
    }()

    /// Aztec's Format Bar Options Presenter
    private lazy var optionsTablePresenter = OptionsTablePresenter(presentingViewController: self,
                                                                   presentingTextView: editorView.richTextView)

    /// Aztec's Text Placeholder
    ///
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Start writing...", comment: "Aztec's Text Placeholder")
        label.textColor = .textPlaceholder
        label.font = StyleManager.subheadlineFont
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: handleKeyboardFrameUpdate(keyboardFrame:))
        return keyboardFrameObserver
    }()

    private let textViewAttachmentDelegate: TextViewAttachmentDelegate

    required init(content: String?,
                  viewProperties: EditorViewProperties,
                  textViewAttachmentDelegate: TextViewAttachmentDelegate = AztecTextViewAttachmentHandler()) {
        self.content = content ?? ""
        self.textViewAttachmentDelegate = textViewAttachmentDelegate
        self.viewProperties = viewProperties
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

        aztecUIConfigurator.configureConstraints(editorView: editorView,
                                                 editorContainerView: view,
                                                 placeholderView: placeholderLabel)

        setHTML(content)

        // getHTML() from the Rich Text View removes the HTML tags
        // so we align the original content to the value of the Rich Text View
        content = getHTML()

        refreshPlaceholderVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningToNotifications()
    }
}

private extension AztecEditorViewController {
    func configureNavigationBar() {
        title = viewProperties.navigationTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveButtonTapped))
    }

    func configureView() {
        edgesForExtendedLayout = UIRectEdge()
        view.backgroundColor = .basicBackground
    }

    func configureSubviews() {
        view.addSubview(richTextView)
        view.addSubview(htmlTextView)
        view.addSubview(placeholderLabel)
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

// MARK: Keyboard frame update handling
//
private extension AztecEditorViewController {
    func handleKeyboardFrameUpdate(keyboardFrame: CGRect) {
        let referenceView = editorView.activeView

        // Converts the keyboard frame from the window coordinate to the view's coordinate.
        let keyboardFrame = view.convert(keyboardFrame, from: nil)

        let bottomInset = referenceView.frame.maxY - (keyboardFrame.minY + view.layoutMargins.bottom)
        let contentInsets  = UIEdgeInsets(top: referenceView.contentInset.top,
                                          left: 0,
                                          bottom: max(0, bottomInset),
                                          right: 0)

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
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

// MARK: - Navigation actions
//
extension AztecEditorViewController {
    @objc private func saveButtonTapped() {
        let content = getHTML()
        ServiceLocator.analytics.track(.aztecEditorDoneButtonTapped)
        onContentSave?(content)
    }

    override func shouldPopOnBackButton() -> Bool {
        guard viewProperties.showSaveChangesActionSheet == true else {
            return true
        }

        let editedContent = getHTML()
        if content != editedContent {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
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
        formatBar.update(editorView: editorView)
    }

    func textViewDidChange(_ textView: UITextView) {
        refreshPlaceholderVisibility()
        formatBar.update(editorView: editorView)
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.inputAccessoryView = formatBar
        return true
    }
}
