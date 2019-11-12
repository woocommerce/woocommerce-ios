import Aztec

struct AztecBlockquoteFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .blockquote

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        let richTextView = editorView.richTextView
        richTextView.toggleBlockquote(range: richTextView.selectedRange)
    }
}
