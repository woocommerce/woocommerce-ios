import Aztec

private extension URL {
    /// This methods returns an url that has a scheme for sure unless the original url is an absolute path
    ///
    /// - Returns: an url
    func normalizedURLForWordPressLink() -> URL {
        let urlString = absoluteString

        guard self.scheme == nil,
            !urlString.hasPrefix("/") else {
            return self
        }

        guard let resultURL = URL(string: "http://\(urlString)")  else {
            return self
        }
        return resultURL
    }
}

struct AztecLinkFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .link

    private let presenter: UIViewController

    init(linkDialogPresenter: UIViewController) {
        self.presenter = linkDialogPresenter
    }

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        let richTextView = editorView.richTextView

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
        showLinkDialog(forURL: linkURL, title: linkTitle, target: linkTarget, range: linkRange, editorView: editorView)
    }
}

private extension AztecLinkFormatBarCommand {
    func showLinkDialog(forURL url: URL?, title: String?, target: String?, range: NSRange, editorView: EditorView) {
        let richTextView = editorView.richTextView

        let isInsertingNewLink = (url == nil)
        var urlToUse = url

        if isInsertingNewLink {
            if UIPasteboard.general.hasURLs,
                let pastedURL = UIPasteboard.general.url {
                urlToUse = pastedURL
            }
        }

        let linkSettings = LinkSettings(url: urlToUse?.absoluteString ?? "",
                                        text: title ?? "",
                                        openInNewWindow: target != nil,
                                        isNewLink: isInsertingNewLink)
        let linkController = LinkSettingsViewController(linkSettings: linkSettings,
                                                        callback: { (action, settings) in
            self.presenter.dismiss(animated: true) {
                richTextView.becomeFirstResponder()
                switch action {
                case .insert, .update:
                    self.insertLink(url: settings.url, text: settings.text, target: settings.openInNewWindow ? "_blank" : nil, range: range, editorView: editorView)
                case .remove:
                    self.removeLink(in: range, editorView: editorView)
                case .cancel:
                    break
                }
            }
        })

        // TODO-1496: show the Link Settings as a popover.
        let navigationController = UINavigationController(rootViewController: linkController)
        presenter.present(navigationController, animated: true)
        richTextView.resignFirstResponder()
    }

    func insertLink(url: String, text: String?, target: String?, range: NSRange, editorView: EditorView) {
        let linkURLString = url
        var linkText = text

        if linkText == nil || linkText!.isEmpty {
            linkText = linkURLString
        }

        guard let url = URL(string: linkURLString), let title = linkText else {
            return
        }

        editorView.richTextView.setLink(url.normalizedURLForWordPressLink(),
                                        title: title,
                                        target: target,
                                        inRange: range)
    }

    func removeLink(in range: NSRange, editorView: EditorView) {
        editorView.richTextView.removeLink(inRange: range)
    }
}
