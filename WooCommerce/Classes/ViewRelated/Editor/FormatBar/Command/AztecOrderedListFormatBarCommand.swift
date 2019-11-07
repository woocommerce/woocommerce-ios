import Aztec
import WordPressEditor

struct AztecOrderedListFormatBarCommand: AztecFormatBarCommand, AztecToggleListCommand {
    let formattingIdentifier: FormattingIdentifier = .orderedlist

    private let optionsTablePresenter: OptionsTablePresenter

    init(optionsTablePresenter: OptionsTablePresenter) {
        self.optionsTablePresenter = optionsTablePresenter
    }

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        toggleList(formatBarItem: formatBarItem, editorView: editorView, optionsTablePresenter: optionsTablePresenter)
    }
}
