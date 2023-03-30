import UIKit
import Aztec
import WordPressEditor

// TODO-JC: move this
final class InputAccessoryView: UIView, UITextViewDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Required to make the view grow vertically.
        self.autoresizingMask = .flexibleHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        // Calculates intrinsicContentSize that will fit to content.
        let contentSize = sizeThatFits(CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: bounds.width, height: contentSize.height)
    }
}

/// Aztec's Native Editor!
final class AztecEditorViewController: UIViewController, Editor {
    var onContentSave: OnContentSave?

    private var content: String

    private let product: ProductFormDataModel

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

    private lazy var generatorActionView: UIView = {
        let button = UIButton(type: .custom)
        button.setTitle("🪄 Write with magic", for: .normal)
        button.applyPrimaryButtonStyle()
        // TODO-JC: layout margins not working
        button.directionalLayoutMargins = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        button.on(.touchUpInside) { [weak self] _ in
            self?.showProductGeneratorBottomSheet()
        }
        return button
    }()

    private var generatorController: ProductDescriptionGenerationHostingController?

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

    private let textViewAttachmentDelegate: TextViewAttachmentDelegate

    required init(content: String?,
                  product: ProductFormDataModel,
                  viewProperties: EditorViewProperties,
                  textViewAttachmentDelegate: TextViewAttachmentDelegate = AztecTextViewAttachmentHandler()) {
        self.content = content ?? ""
        self.product = product
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
        disableLinkTapRecognizer(from: editorView.richTextView)

        setHTML(content)

        // getHTML() from the Rich Text View removes the HTML tags
        // so we align the original content to the value of the Rich Text View
        content = getHTML()

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissProductGeneratorBottomSheetIfNeeded()
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
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productDescriptionGenerator) else {
            return formatBar
        }

        let stackView = UIStackView(arrangedSubviews: [generatorActionView, formatBar])
        stackView.spacing = 0
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let accessoryView = InputAccessoryView()
        accessoryView.addSubview(stackView)
        accessoryView.pinSubviewToAllEdges(stackView)
        accessoryView.translatesAutoresizingMaskIntoConstraints = false

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
        dismissProductGeneratorBottomSheetIfNeeded()
        textView.inputAccessoryView = createInputAccessoryView()
        return true
    }
}

private extension AztecEditorViewController {
    func showProductGeneratorBottomSheet() {
        let controller = ProductDescriptionGenerationHostingController(viewModel: .init(product: product))
        generatorController = controller
        configureBottomSheetPresentation(for: controller)
        view.endEditing(true)
        present(controller, animated: true)
    }

    func configureBottomSheetPresentation(for viewController: UIViewController) {
        if let sheet = viewController.sheetPresentationController {
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
            sheet.detents = [.medium(), .large()]
        }
    }

    func dismissProductGeneratorBottomSheetIfNeeded() {
        generatorController?.dismiss(animated: false) { [weak self] in
            self?.generatorController = nil
        }
    }
}
