import Aztec

private extension URL {
    /// This methods returns an url that has a scheme for sure unless the original url is an absolute path
    ///
    /// - Returns: an url
    func normalizedURLForWordPressLink() -> URL {
        let urlString = self.absoluteString

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

        let isInsertingNewLink = (url == nil)
        var urlToUse = url

        if isInsertingNewLink {
            if UIPasteboard.general.hasURLs,
                let pastedURL = UIPasteboard.general.url {
                urlToUse = pastedURL
            }
        }

        // TODO: replace the alert implementation with something nicer like `LinkSettingsViewController` on WPiOS.

        let alertController = UIAlertController(title: NSLocalizedString("Link Settings", comment: ""), message: nil, preferredStyle: .alert)
        let removeLinkAction = UIAlertAction(title: NSLocalizedString("Remove link", comment: ""), style: .destructive, handler: { _ in
            self.removeLink(in: range, editorView: editorView)
        })
        let addLinkAction = UIAlertAction(title: NSLocalizedString("Add link", comment: ""), style: .default) { _ in
            guard let urlTextField = alertController.textFields?[0],
                let url = urlTextField.text else {
                    return
            }
            self.insertLink(url: url, text: title, target: nil, range: range, editorView: editorView)
        }
        let addLinkToNewWindowAction = UIAlertAction(title: NSLocalizedString("Add link to a new window", comment: ""), style: .default) { _ in
            guard let urlTextField = alertController.textFields?[0],
                let url = urlTextField.text else {
                    return
            }
            self.insertLink(url: url, text: title, target: "_blank", range: range, editorView: editorView)
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
        presenter.present(alertController, animated: true, completion: nil)

        editorView.richTextView.resignFirstResponder()
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
