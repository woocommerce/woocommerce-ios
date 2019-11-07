import Aztec

struct AztecCodeFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .code

    func handleAction(editorView: EditorView, formatBar: FormatBar) {
        let richTextView = editorView.richTextView
        richTextView.toggleCode(range: richTextView.selectedRange)
    }
}
