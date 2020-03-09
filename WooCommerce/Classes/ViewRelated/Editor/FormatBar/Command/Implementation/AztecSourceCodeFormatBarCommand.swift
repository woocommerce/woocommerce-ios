import Aztec

struct AztecSourceCodeFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .sourcecode

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        formatBar.overflowToolbar(expand: true)
        editorView.toggleEditingMode()

        // In HTML mode, disables the format bar except for the source code action.
        switch editorView.editingMode {
        case .richText:
            formatBar.enabled = true
        case .html:
            formatBar.enabled = false
        }
        formatBarItem.isEnabled = true
    }
}
