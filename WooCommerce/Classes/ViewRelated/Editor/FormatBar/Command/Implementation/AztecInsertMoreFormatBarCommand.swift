import Aztec

struct AztecInsertMoreFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .more

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        let richTextView = editorView.richTextView
        richTextView.replace(richTextView.selectedRange, withComment: Constants.moreAttachmentText)
    }
}

private extension AztecInsertMoreFormatBarCommand {
    enum Constants {
        static let moreAttachmentText = "more"
    }
}
