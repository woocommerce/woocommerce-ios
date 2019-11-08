import Aztec

struct AztecHorizontalRulerFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .horizontalruler

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        let richTextView = editorView.richTextView
        richTextView.replaceWithHorizontalRuler(at: richTextView.selectedRange)
    }
}
