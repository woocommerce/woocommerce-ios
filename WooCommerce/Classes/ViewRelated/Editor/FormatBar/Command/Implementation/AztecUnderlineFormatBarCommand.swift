import Aztec

struct AztecUnderlineFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .underline

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        let richTextView = editorView.richTextView
        richTextView.toggleUnderline(range: richTextView.selectedRange)
    }
}
