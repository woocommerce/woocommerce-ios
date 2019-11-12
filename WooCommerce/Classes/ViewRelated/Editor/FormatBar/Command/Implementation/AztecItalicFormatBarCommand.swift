import Aztec

struct AztecItalicFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .italic

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        let richTextView = editorView.richTextView
        richTextView.toggleItalic(range: richTextView.selectedRange)
    }
}
