import UIKit
import Aztec
import WordPressEditor

/// Aztec's Native Editor!
final class AztecEditorViewController: UIViewController, Editor {
    var onContentSave: OnContentSave?

    private var content: String
    private var productName: String?

    private let product: ProductFormDataModel?

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

    private lazy var aiActionView: UIView = AztecAIViewFactory().aiButtonNextToFormatBar { [weak self] in
        self?.showDescriptionGenerationBottomSheet()
    }

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
        label.text = viewProperties.placeholderText
        label.textColor = .textPlaceholder
        label.font = StyleManager.subheadlineFont
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
        return keyboardFrameObserver
    }()

    // FIXME: This has a long call chain and cannot be quickly addressed as part of the current SwiftLint violations smashing round
    // swiftlint:disable:next weak_delegate
    private let textViewAttachmentDelegate: TextViewAttachmentDelegate

    private let isAIGenerationEnabled: Bool
    private var descriptionAICoordinator: ProductDescriptionAICoordinator?

    required init(content: String?,
                  product: ProductFormDataModel? = nil,
                  viewProperties: EditorViewProperties,
                  textViewAttachmentDelegate: TextViewAttachmentDelegate = AztecTextViewAttachmentHandler(),
                  isAIGenerationEnabled: Bool) {
        self.content = content ?? ""
        self.product = product
        self.textViewAttachmentDelegate = textViewAttachmentDelegate
        self.viewProperties = viewProperties
        self.isAIGenerationEnabled = isAIGenerationEnabled
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
        disableLinkTapRecognizer(from: editorView.richTextView)

        updateContent()

        refreshPlaceholderVisibility()
        handleSwipeBackGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningToNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        richTextView.becomeFirstResponder()
    }

    func getLatestContent() -> String {
        return getHTML()
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

    /**
    This handles a bug introduced by iOS 13.0 (tested up to 13.2) where link interactions don't respect what the documentation says.
    The documenatation for textView(_:shouldInteractWith:in:interaction:) says:
    > Links in text views are interactive only if the text view is selectable but noneditable.
    Our Aztec Text views are selectable and editable, and yet iOS was opening links on Safari when tapped.
    */
    func disableLinkTapRecognizer(from textView: UITextView) {
        guard let recognizer = textView.gestureRecognizers?.first(where: { $0.name == "UITextInteractionNameLinkTap" }) else {
            return
        }
        recognizer.isEnabled = false
    }

    func createInputAccessoryView() -> UIView {
        guard isAIGenerationEnabled else {
            return formatBar
        }

        let stackView = UIStackView(arrangedSubviews: [aiActionView, formatBar])
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let accessoryView = InputAccessoryView()
        accessoryView.addSubview(stackView)
        accessoryView.pinSubviewToAllEdges(stackView)
        accessoryView.translatesAutoresizingMaskIntoConstraints = false

        accessoryView.sizeToFit()

        return accessoryView
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
extension AztecEditorViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        editorView.activeView
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
        onContentSave?(content, productName)
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

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
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
        textView.inputAccessoryView = createInputAccessoryView()
        return true
    }
}

private extension AztecEditorViewController {
    func showDescriptionGenerationBottomSheet() {
        guard let navigationController else {
            return
        }

        guard let product else {
            return
        }

        let coordinator = ProductDescriptionAICoordinator(product: product,
                                                          navigationController: navigationController,
                                                          source: .aztecEditor,
                                                          analytics: ServiceLocator.analytics,
                                                          onApply: { [weak self] output in
            guard let self else { return }
            self.content = output.description
            self.productName = output.name
            self.updateContent()
        })
        descriptionAICoordinator = coordinator
        coordinator.start()
    }

    func updateContent() {
        setHTML(content)

        // getHTML() from the Rich Text View removes the HTML tags
        // so we align the original content to the value of the Rich Text View
        content = getHTML()
    }
}
