import Aztec

extension Aztec.FormatBar {
    /// Updates the format bar to highlight the formatting options applied to the text being edited.
    func update(editorView: EditorView) {
        switch editorView.editingMode {
        case .html:
            updateFormatBarForHTMLMode()
        case .richText:
            updateFormatBarForVisualMode(richTextView: editorView.richTextView)
        }
    }
}

private extension Aztec.FormatBar {
    func updateFormatBarForHTMLMode() {
        selectItemsMatchingIdentifiers([FormattingIdentifier.sourcecode.rawValue])
    }

    func updateFormatBarForVisualMode(richTextView: Aztec.TextView) {
        let identifiers: Set<FormattingIdentifier>

        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }

        selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
    }
}
