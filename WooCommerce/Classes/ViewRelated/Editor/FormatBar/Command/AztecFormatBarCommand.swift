import Aztec

/// Handles an Aztec format bar action.
protocol AztecFormatBarCommand {
    var formattingIdentifier: FormattingIdentifier { get }
    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar)
}
