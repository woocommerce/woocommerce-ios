import Aztec

struct AztecStrikethroughFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .strikethrough

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        let richTextView = editorView.richTextView
        richTextView.toggleStrikethrough(range: richTextView.selectedRange)
    }
}
