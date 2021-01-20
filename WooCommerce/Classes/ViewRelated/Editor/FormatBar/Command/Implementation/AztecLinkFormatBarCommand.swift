import Aztec

struct AztecLinkFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .link

    private weak var presenter: UIViewController?

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
            self.presenter?.dismiss(animated: true) {
                richTextView.becomeFirstResponder()
                switch action {
                case .insert, .update:
                    self.insertLink(url: settings.url,
                                    text: settings.text,
                                    target: settings.openInNewWindow ? "_blank" : nil,
                                    range: range,
                                    editorView: editorView)
                case .remove:
                    self.removeLink(in: range, editorView: editorView)
                case .cancel:
                    break
                }
            }
        })

        let navigationController = UINavigationController(rootViewController: linkController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.sourceView = richTextView
        if richTextView.selectedRange.length > 0,
           let textRange = richTextView.selectedTextRange,
           let selectionRect = richTextView.selectionRects(for: textRange).first {
            navigationController.popoverPresentationController?.sourceRect = selectionRect.rect
        } else if let textRange = richTextView.selectedTextRange {
            let caretRect = richTextView.caretRect(for: textRange.start)
            navigationController.popoverPresentationController?.sourceRect = caretRect
        }
        presenter?.present(navigationController, animated: true)
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

        editorView.richTextView.setLink(url,
                                        title: title,
                                        target: target,
                                        inRange: range)
    }

    func removeLink(in range: NSRange, editorView: EditorView) {
        editorView.richTextView.removeLink(inRange: range)
    }
}
