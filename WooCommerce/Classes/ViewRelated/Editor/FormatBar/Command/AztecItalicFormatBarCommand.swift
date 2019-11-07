import Aztec

struct AztecItalicFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .italic

    func handleAction(editorView: EditorView, formatBar: FormatBar) {
        let richTextView = editorView.richTextView
        richTextView.toggleItalic(range: richTextView.selectedRange)
    }
}
