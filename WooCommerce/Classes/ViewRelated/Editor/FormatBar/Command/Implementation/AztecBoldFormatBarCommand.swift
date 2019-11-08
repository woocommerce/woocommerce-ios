import Aztec

struct AztecBoldFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .bold

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        let richTextView = editorView.richTextView
        richTextView.toggleBold(range: richTextView.selectedRange)
    }
}
