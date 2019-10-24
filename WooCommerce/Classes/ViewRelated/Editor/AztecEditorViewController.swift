import Foundation
import UIKit
import Aztec
import CocoaLumberjack
import Gridicons
import WordPressShared
import MobileCoreServices
import WordPressEditor
import AutomatticTracks

// MARK: - Aztec's Native Editor!
//
class AztecEditorViewController: UIViewController {
    private let content: String

    /// The editor view.
    ///
    fileprivate(set) lazy var editorView: Aztec.EditorView = {

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
        let headerButton = makeToolbarButton(identifier: .p)

        var alternativeIcons = [String: UIImage]()
        let headings = Constants.headers.suffix(from: 1) // Remove paragraph style
        for heading in headings {
            alternativeIcons[heading.formattingIdentifier.rawValue] = heading.iconImage
        }

        headerButton.alternativeIcons = alternativeIcons


        let listButton = makeToolbarButton(identifier: .unorderedlist)
        var listIcons = [String: UIImage]()
        for list in Constants.lists {
            listIcons[list.formattingIdentifier.rawValue] = list.iconImage
        }

        listButton.alternativeIcons = listIcons

        return [
            headerButton,
            listButton,
            makeToolbarButton(identifier: .blockquote),
            makeToolbarButton(identifier: .bold),
            makeToolbarButton(identifier: .italic),
            makeToolbarButton(identifier: .link)
        ]
    }

    var overflowItemsForToolbar: [FormatBarItem] {
        return [
            makeToolbarButton(identifier: .underline),
            makeToolbarButton(identifier: .strikethrough),
            makeToolbarButton(identifier: .horizontalruler),
            makeToolbarButton(identifier: .more),
            makeToolbarButton(identifier: .sourcecode)
        ]
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

    /// Raw HTML Editor
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
        label.text = NSLocalizedString("Share your story here...", comment: "Aztec's Text Placeholder")
        label.textColor = StyleManager.cellSeparatorColor
        label.font = StyleManager.subheadlineFont
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .natural
        label.accessibilityIdentifier = "aztec-content-placeholder"
        return label
    }()

    /// Current keyboard rect used to help size the inline media picker
    ///
    fileprivate var currentKeyboardFrame: CGRect = .zero

    init(content: String?) {
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

    deinit {
        stopListeningToNotifications()
    }
}

private extension AztecEditorViewController {
    func configureNavigationBar() {
        title = NSLocalizedString("Description", comment: "The navigation bar title of the Product description editor screen.")

        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.accessibilityIdentifier = "Aztec Editor Navigation Bar"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelButtonTapped))
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
                                                             .foregroundColor: UIColor.red]

        textView.delegate = self
//        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self
        textView.backgroundColor = StyleManager.wooWhite
//            Colors.aztecBackground
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

        NSLayoutConstraint.activate([
            placeholderLabel.leftAnchor.constraint(equalTo: richTextView.leftAnchor, constant: 0),
            placeholderLabel.rightAnchor.constraint(equalTo: richTextView.rightAnchor, constant: 0),
            placeholderLabel.topAnchor.constraint(equalTo: richTextView.topAnchor, constant: 0),
            placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: richTextView.bottomAnchor, constant: 0)
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
        toolbar.highlightedTintColor = StyleManager.wooCommerceBrandColor
        toolbar.selectedTintColor = .red
        toolbar.disabledTintColor = StyleManager.buttonDisabledColor
        toolbar.dividerTintColor = .orange
        toolbar.overflowToggleIcon = Gridicon.iconOfType(.ellipsis)

        updateToolbar(toolbar)
//
//        toolbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: Constants.toolbarHeight)
//        toolbar.formatter = self
//
        toolbar.barItemHandler = { [weak self] item in
            self?.handleAction(for: item)
        }

        return toolbar
    }

    func updateToolbar(_ toolbar: Aztec.FormatBar) {
        toolbar.trailingItem = nil

        toolbar.setDefaultItems(scrollableItemsForToolbar,
                                overflowItems: overflowItemsForToolbar)
    }

    func makeToolbarButton(identifier: FormattingIdentifier) -> FormatBarItem {
        return makeToolbarButton(identifier: identifier.rawValue, provider: identifier)
    }

    func makeToolbarButton(identifier: String, provider: FormatBarItemProvider) -> FormatBarItem {
        let button = FormatBarItem(image: provider.iconImage, identifier: identifier)
        button.accessibilityLabel = provider.accessibilityLabel
        button.accessibilityIdentifier = provider.accessibilityIdentifier
        return button
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

// MARK: FormatBar Actions
//
extension AztecEditorViewController {
    func handleAction(for barItem: FormatBarItem) {
        guard let identifier = barItem.identifier else { return }

        if let formattingIdentifier = FormattingIdentifier(rawValue: identifier) {
            switch formattingIdentifier {
            case .bold:
                toggleBold()
            case .italic:
                toggleItalic()
            case .underline:
                toggleUnderline()
            case .strikethrough:
                toggleStrikethrough()
            case .blockquote:
                toggleBlockquote()
            case .unorderedlist, .orderedlist:
                toggleList(fromItem: barItem)
            case .link:
                toggleLink()
            case .sourcecode:
                toggleEditingMode()
            case .p, .header1, .header2, .header3, .header4, .header5, .header6:
                toggleHeader(fromItem: barItem)
            case .horizontalruler:
                insertHorizontalRuler()
            case .more:
                insertMore()
            case .code:
                toggleCode()
            default:
                break
            }

            updateFormatBar()
        }
    }

    @objc func toggleBold() {
//        trackFormatBarAnalytics(stat: .editorTappedBold)
        richTextView.toggleBold(range: richTextView.selectedRange)
    }

    @objc func toggleCode() {
        richTextView.toggleCode(range: richTextView.selectedRange)
    }

    @objc func toggleItalic() {
//        trackFormatBarAnalytics(stat: .editorTappedItalic)
        richTextView.toggleItalic(range: richTextView.selectedRange)
    }


    @objc func toggleUnderline() {
//        trackFormatBarAnalytics(stat: .editorTappedUnderline)
        richTextView.toggleUnderline(range: richTextView.selectedRange)
    }


    @objc func toggleStrikethrough() {
//        trackFormatBarAnalytics(stat: .editorTappedStrikethrough)
        richTextView.toggleStrikethrough(range: richTextView.selectedRange)
    }

    @objc func toggleOrderedList() {
//        trackFormatBarAnalytics(stat: .editorTappedOrderedList)
        richTextView.toggleOrderedList(range: richTextView.selectedRange)
    }

    @objc func toggleUnorderedList() {
//        trackFormatBarAnalytics(stat: .editorTappedUnorderedList)
        richTextView.toggleUnorderedList(range: richTextView.selectedRange)
    }

    func toggleList(fromItem item: FormatBarItem) {
        let listOptions = Constants.lists.map { listType -> OptionsTableViewOption in
            let title = NSAttributedString(string: listType.description, attributes: [:])
            return OptionsTableViewOption(image: listType.iconImage,
                                          title: title,
                                          accessibilityLabel: listType.accessibilityLabel)
        }

        var index: Int? = nil
        if let listType = listTypeForSelectedText() {
            index = Constants.lists.firstIndex(of: listType)
        }

        let optionsTableViewController = OptionsTableViewController(options: listOptions)

//        optionsTableViewController.cellDeselectedTintColor = WPStyleGuide.aztecFormatBarInactiveColor
//        optionsTableViewController.cellBackgroundColor = WPStyleGuide.aztecFormatPickerBackgroundColor
//        optionsTableViewController.cellSelectedBackgroundColor = WPStyleGuide.aztecFormatPickerSelectedCellBackgroundColor
//        optionsTableViewController.view.tintColor = WPStyleGuide.aztecFormatBarActiveColor

        optionsTablePresenter.present(
            optionsTableViewController,
            fromBarItem: item,
            selectedRowIndex: index,
            onSelect: { [weak self] selected in
                let listType = Constants.lists[selected]

                switch listType {
                case .unordered:
                    self?.toggleUnorderedList()
                case .ordered:
                    self?.toggleOrderedList()
                }
        })
    }


    @objc func toggleBlockquote() {
//        trackFormatBarAnalytics(stat: .editorTappedBlockquote)
        richTextView.toggleBlockquote(range: richTextView.selectedRange)
    }


    func listTypeForSelectedText() -> TextList.Style? {
        var identifiers = Set<FormattingIdentifier>()
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: TextList.Style] = [
            .orderedlist: .ordered,
            .unorderedlist: .unordered
        ]
        for (key, value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }

        return nil
    }

    @objc func toggleEditingMode() {
//        trackFormatBarAnalytics(stat: .editorTappedHTML)
        formatBar.overflowToolbar(expand: true)

        editorView.toggleEditingMode()
//        editorSession.switch(editor: analyticsEditor)
    }

    // MARK: Link Actions

    @objc func toggleLink() {
//        trackFormatBarAnalytics(stat: .editorTappedLink)

        var linkTitle = ""
        var linkURL: URL? = nil
        var linkTarget: String?
        var linkRange = richTextView.selectedRange
        // Let's check if the current range already has a link assigned to it.
        if let expandedRange = richTextView.linkFullRange(forRange: richTextView.selectedRange) {
            linkRange = expandedRange
            linkURL = richTextView.linkURL(forRange: expandedRange)
            linkTarget = richTextView.linkTarget(forRange: expandedRange)
        }

        linkTitle = richTextView.attributedText.attributedSubstring(from: linkRange).string
        showLinkDialog(forURL: linkURL, title: linkTitle, target: linkTarget, range: linkRange)
    }

    func showLinkDialog(forURL url: URL?, title: String?, target: String?, range: NSRange) {

        let isInsertingNewLink = (url == nil)
        var urlToUse = url

        if isInsertingNewLink {
            if UIPasteboard.general.hasURLs,
                let pastedURL = UIPasteboard.general.url {
                urlToUse = pastedURL
            }
        }

        let alertController = UIAlertController(title: NSLocalizedString("Link Settings", comment: ""), message: nil, preferredStyle: .alert)
        let removeLinkAction = UIAlertAction(title: NSLocalizedString("Remove link", comment: ""), style: .destructive, handler: { [weak self] _ in
            self?.removeLink(in: range)
        })
        let addLinkAction = UIAlertAction(title: NSLocalizedString("Add link", comment: ""), style: .default) { [weak self] _ in
            guard let urlTextField = alertController.textFields?[0],
                let url = urlTextField.text else {
                return
            }
            self?.insertLink(url: url, text: title, target: nil, range: range)
        }
        let addLinkToNewWindowAction = UIAlertAction(title: NSLocalizedString("Add link to a new window", comment: ""), style: .default) { [weak self] _ in
            guard let urlTextField = alertController.textFields?[0],
                let url = urlTextField.text else {
                return
            }
            self?.insertLink(url: url, text: title, target: "_blank", range: range)
        }

        alertController.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Enter link URL", comment: "")
            textField.text = urlToUse?.absoluteString ?? ""
        })

        alertController.addAction(addLinkAction)
        alertController.addAction(addLinkToNewWindowAction)

        if urlToUse != nil {
            alertController.addAction(removeLinkAction)
        }

        alertController.addActionWithTitle(NSLocalizedString("Cancel", comment: ""), style: .cancel)
        present(alertController, animated: true, completion: nil)

//        let linkSettings = LinkSettings(url: urlToUse?.absoluteString ?? "", text: title ?? "", openInNewWindow: target != nil, isNewLink: isInsertingNewLink)
//        let linkController = LinkSettingsViewController(settings: linkSettings, callback: { [weak self](action, settings) in
//            guard let strongSelf = self else {
//                return
//            }
//            strongSelf.dismiss(animated: true, completion: {
//                strongSelf.richTextView.becomeFirstResponder()
//                switch action {
//                case .insert, .update:
//                    strongSelf.insertLink(url: settings.url, text: settings.text, target: settings.openInNewWindow ? "_blank" : nil, range: range)
//                case .remove:
//                    strongSelf.removeLink(in: range)
//                case .cancel:
//                    break
//                }
//            })
//        })
//        linkController.blog = self.post.blog
//
//        let navigationController = UINavigationController(rootViewController: linkController)
//        navigationController.modalPresentationStyle = .popover
//        navigationController.popoverPresentationController?.permittedArrowDirections = [.any]
//        navigationController.popoverPresentationController?.sourceView = richTextView
//        navigationController.popoverPresentationController?.backgroundColor = WPStyleGuide.aztecFormatPickerBackgroundColor
//        if richTextView.selectedRange.length > 0, let textRange = richTextView.selectedTextRange, let selectionRect = richTextView.selectionRects(for: textRange).first {
//            navigationController.popoverPresentationController?.sourceRect = selectionRect.rect
//        } else if let textRange = richTextView.selectedTextRange {
//            let caretRect = richTextView.caretRect(for: textRange.start)
//            navigationController.popoverPresentationController?.sourceRect = caretRect
//        }
//        present(navigationController, animated: true)
        richTextView.resignFirstResponder()
    }

    func insertLink(url: String, text: String?, target: String?, range: NSRange) {
        let linkURLString = url
        var linkText = text

        if linkText == nil || linkText!.isEmpty {
            linkText = linkURLString
        }

        guard let url = URL(string: linkURLString), let title = linkText else {
            return
        }

        richTextView.setLink(url.normalizedURLForWordPressLink(), title: title, target: target, inRange: range)
    }

    func removeLink(in range: NSRange) {
//        trackFormatBarAnalytics(stat: .editorTappedUnlink)
        richTextView.removeLink(inRange: range)
    }

    func toggleHeader(fromItem item: FormatBarItem) {
        guard !optionsTablePresenter.isOnScreen() else {
            optionsTablePresenter.dismiss()
            return
        }

//        trackFormatBarAnalytics(stat: .editorTappedHeader)

        let headerOptions = Constants.headers.map { headerType -> OptionsTableViewOption in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: CGFloat(headerType.fontSize)),
//                .foregroundColor: UIColor.neutral(shade: .shade70)
            ]

            let title = NSAttributedString(string: headerType.description, attributes: attributes)

            return OptionsTableViewOption(image: headerType.iconImage,
                                          title: title,
                                          accessibilityLabel: headerType.accessibilityLabel)
        }

        let selectedIndex = Constants.headers.firstIndex(of: self.headerLevelForSelectedText())

        let optionsTableViewController = OptionsTableViewController(options: headerOptions)

//        optionsTableViewController.cellDeselectedTintColor = WPStyleGuide.aztecFormatBarInactiveColor
//        optionsTableViewController.cellBackgroundColor = WPStyleGuide.aztecFormatPickerBackgroundColor
//        optionsTableViewController.cellSelectedBackgroundColor = WPStyleGuide.aztecFormatPickerSelectedCellBackgroundColor
//        optionsTableViewController.view.tintColor = WPStyleGuide.aztecFormatBarActiveColor

        optionsTablePresenter.present(
            optionsTableViewController,
            fromBarItem: item,
            selectedRowIndex: selectedIndex,
            onSelect: { [weak self] selected in
                guard let range = self?.richTextView.selectedRange else { return }

//                let selectedStyle = Analytics.headerStyleValues[selected]
//                self?.trackFormatBarAnalytics(stat: .editorTappedHeaderSelection, headingStyle: selectedStyle)

                self?.richTextView.toggleHeader(Constants.headers[selected], range: range)
                self?.optionsTablePresenter.dismiss()
        })
    }

    func insertHorizontalRuler() {
//        trackFormatBarAnalytics(stat: .editorTappedHorizontalRule)
        richTextView.replaceWithHorizontalRuler(at: richTextView.selectedRange)
    }

    func insertMore() {
//        trackFormatBarAnalytics(stat: .editorTappedMore)
        richTextView.replace(richTextView.selectedRange, withComment: Constants.moreAttachmentText)
    }

    func headerLevelForSelectedText() -> Header.HeaderType {
        var identifiers = Set<FormattingIdentifier>()
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: Header.HeaderType] = [
            .header1: .h1,
            .header2: .h2,
            .header3: .h3,
            .header4: .h4,
            .header5: .h5,
            .header6: .h6,
        ]
        for (key, value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }
        return .none
    }
}

private extension AztecEditorViewController {
    // MARK: - Keyboard Handling

    override internal var keyCommands: [UIKeyCommand] {

        if richTextView.isFirstResponder {
            return [
                UIKeyCommand(input: "B", modifierFlags: .command, action: #selector(toggleBold), discoverabilityTitle: NSLocalizedString("Bold", comment: "Discoverability title for bold formatting keyboard shortcut.")),
                UIKeyCommand(input: "I", modifierFlags: .command, action: #selector(toggleItalic), discoverabilityTitle: NSLocalizedString("Italic", comment: "Discoverability title for italic formatting keyboard shortcut.")),
                UIKeyCommand(input: "S", modifierFlags: [.command], action: #selector(toggleStrikethrough), discoverabilityTitle: NSLocalizedString("Strikethrough", comment: "Discoverability title for strikethrough formatting keyboard shortcut.")),
                UIKeyCommand(input: "U", modifierFlags: .command, action: #selector(toggleUnderline(_:)), discoverabilityTitle: NSLocalizedString("Underline", comment: "Discoverability title for underline formatting keyboard shortcut.")),
                UIKeyCommand(input: "Q", modifierFlags: [.command, .alternate], action: #selector(toggleBlockquote), discoverabilityTitle: NSLocalizedString("Block Quote", comment: "Discoverability title for block quote keyboard shortcut.")),
                UIKeyCommand(input: "K", modifierFlags: .command, action: #selector(toggleLink), discoverabilityTitle: NSLocalizedString("Insert Link", comment: "Discoverability title for insert link keyboard shortcut.")),
                UIKeyCommand(input: "U", modifierFlags: [.command, .alternate], action: #selector(toggleUnorderedList), discoverabilityTitle: NSLocalizedString("Bullet List", comment: "Discoverability title for bullet list keyboard shortcut.")),
                UIKeyCommand(input: "O", modifierFlags: [.command, .alternate], action: #selector(toggleOrderedList), discoverabilityTitle: NSLocalizedString("Numbered List", comment: "Discoverability title for numbered list keyboard shortcut.")),
                UIKeyCommand(input: "H", modifierFlags: [.command, .shift], action: #selector(toggleEditingMode), discoverabilityTitle: NSLocalizedString("Toggle HTML Source ", comment: "Discoverability title for HTML keyboard shortcut."))
            ]
        }

        if htmlTextView.isFirstResponder {
            return [
                UIKeyCommand(input: "H", modifierFlags: [.command, .shift], action: #selector(toggleEditingMode), discoverabilityTitle: NSLocalizedString("Toggle HTML Source ", comment: "Discoverability title for HTML keyboard shortcut."))
            ]
        }

        return []
    }

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

private extension AztecEditorViewController {
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        nc.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
    }

    /// Unregisters from the Notification Center
    ///
    func stopListeningToNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func applicationWillResignActive(_ notification: Foundation.Notification) {

        // [2018-03-05] Need to close the options VC on backgrounding to prevent view hierarchy inconsistency crasher.
        optionsTablePresenter.dismiss()
    }
}

private extension AztecEditorViewController {
    @objc func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc func saveButtonTapped() {
        // TODO
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
        return UIImage.productPlaceholderImage
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
