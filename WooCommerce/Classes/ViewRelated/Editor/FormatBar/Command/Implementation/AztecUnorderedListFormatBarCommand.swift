import Aztec
import WordPressEditor

struct AztecUnorderedListFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .unorderedlist

    private let optionsTablePresenter: OptionsTablePresenter

    init(optionsTablePresenter: OptionsTablePresenter) {
        self.optionsTablePresenter = optionsTablePresenter
    }

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        toggleList(formatBarItem: formatBarItem, editorView: editorView, optionsTablePresenter: optionsTablePresenter)
    }
}

private extension AztecUnorderedListFormatBarCommand {
    func toggleList(formatBarItem: FormatBarItem, editorView: EditorView, optionsTablePresenter: OptionsTablePresenter) {
        guard !optionsTablePresenter.isOnScreen() else {
            optionsTablePresenter.dismiss()
            return
        }

        let lists = [TextList.Style.unordered, .ordered]

        let listOptions = lists.map { listType -> OptionsTableViewOption in
            let title = NSAttributedString(string: listType.description, attributes: [
                .foregroundColor: StyleManager.defaultTextColor
            ])
            return OptionsTableViewOption(image: listType.iconImage,
                                          title: title,
                                          accessibilityLabel: listType.accessibilityLabel)
        }

        var index: Int? = nil
        if let listType = listTypeForSelectedText(editorView: editorView) {
            index = lists.firstIndex(of: listType)
        }

        let optionsTableViewController = OptionsTableViewController(options: listOptions)
        optionsTableViewController.applyDefaultStyles()

        optionsTablePresenter.present(
            optionsTableViewController,
            fromBarItem: formatBarItem,
            selectedRowIndex: index,
            onSelect: { selected in
                let listType = lists[selected]
                switch listType {
                case .unordered:
                    self.toggleUnorderedList(editorView: editorView)
                case .ordered:
                    self.toggleOrderedList(editorView: editorView)
                }
        })
    }

    func listTypeForSelectedText(editorView: EditorView) -> TextList.Style? {
        let richTextView = editorView.richTextView
        let identifiers: Set<FormattingIdentifier>
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: TextList.Style] = [
            .orderedlist: .ordered,
            .unorderedlist: .unordered
        ]
        for (key, value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }

        return nil
    }

    func toggleOrderedList(editorView: EditorView) {
        let richTextView = editorView.richTextView
        richTextView.toggleOrderedList(range: richTextView.selectedRange)
    }

    func toggleUnorderedList(editorView: EditorView) {
        let richTextView = editorView.richTextView
        richTextView.toggleUnorderedList(range: richTextView.selectedRange)
    }
}
