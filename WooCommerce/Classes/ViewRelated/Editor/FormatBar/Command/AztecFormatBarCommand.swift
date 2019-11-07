import Aztec

/// Handles a Aztec format bar action.
protocol AztecFormatBarCommand {
    var formattingIdentifier: FormattingIdentifier { get }
    func handleAction(editorView: EditorView, formatBar: FormatBar)
}
