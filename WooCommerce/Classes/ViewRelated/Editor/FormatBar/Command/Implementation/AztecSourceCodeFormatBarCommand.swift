import Aztec

struct AztecSourceCodeFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .sourcecode

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        formatBar.overflowToolbar(expand: true)
        editorView.toggleEditingMode()

        switch editorView.editingMode {
        case .richText:
            formatBar.enabled = true
            updateFormatBarForVisualMode(editorView: editorView, formatBar: formatBar)
        case .html:
            formatBar.enabled = false
            updateFormatBarForHTMLMode(formatBar: formatBar)
        }
        formatBarItem.isEnabled = true
    }
}

private extension AztecSourceCodeFormatBarCommand {
    /// Updates the format bar for HTML mode.
    ///
    func updateFormatBarForHTMLMode(formatBar: FormatBar) {
        formatBar.selectItemsMatchingIdentifiers([FormattingIdentifier.sourcecode.rawValue])
    }

    /// Updates the format bar for visual mode.
    ///
    func updateFormatBarForVisualMode(editorView: EditorView, formatBar: FormatBar) {
        var identifiers = Set<FormattingIdentifier>()

        let richTextView = editorView.richTextView
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }

        formatBar.selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
    }
}
