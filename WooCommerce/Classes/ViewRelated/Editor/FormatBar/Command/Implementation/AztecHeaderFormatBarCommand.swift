import Aztec
import WordPressEditor

struct AztecHeaderFormatBarCommand: AztecFormatBarCommand {
    let formattingIdentifier: FormattingIdentifier = .p

    private let optionsTablePresenter: OptionsTablePresenter

    init(optionsTablePresenter: OptionsTablePresenter) {
        self.optionsTablePresenter = optionsTablePresenter
    }

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        toggleHeader(formatBarItem: formatBarItem,
                     editorView: editorView,
                     optionsTablePresenter: optionsTablePresenter)
    }
}

private extension AztecHeaderFormatBarCommand {
    func toggleHeader(formatBarItem: FormatBarItem, editorView: EditorView, optionsTablePresenter: OptionsTablePresenter) {
        guard !optionsTablePresenter.isOnScreen() else {
            optionsTablePresenter.dismiss()
            return
        }

        let headers = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]

        let headerOptions = headers.map { headerType -> OptionsTableViewOption in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: CGFloat(headerType.fontSize)),
                .foregroundColor: StyleManager.defaultTextColor
            ]

            let title = NSAttributedString(string: headerType.description, attributes: attributes)

            return OptionsTableViewOption(image: headerType.iconImage,
                                          title: title,
                                          accessibilityLabel: headerType.accessibilityLabel)
        }

        let selectedIndex = headers.firstIndex(of: headerLevelForSelectedText(richTextView: editorView.richTextView))

        let optionsTableViewController = OptionsTableViewController(options: headerOptions)
        optionsTableViewController.applyDefaultStyles()

        optionsTablePresenter.present(
            optionsTableViewController,
            fromBarItem: formatBarItem,
            selectedRowIndex: selectedIndex,
            onSelect: { selected in
                let range = editorView.richTextView.selectedRange
                editorView.richTextView.toggleHeader(headers[selected], range: range)
                optionsTablePresenter.dismiss()
        })
    }

    func headerLevelForSelectedText(richTextView: Aztec.TextView) -> Header.HeaderType {
        var identifiers = Set<FormattingIdentifier>()
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: Header.HeaderType] = [
            .header1: .h1,
            .header2: .h2,
            .header3: .h3,
            .header4: .h4,
            .header5: .h5,
            .header6: .h6,
        ]
        for (key, value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }
        return .none
    }
}
