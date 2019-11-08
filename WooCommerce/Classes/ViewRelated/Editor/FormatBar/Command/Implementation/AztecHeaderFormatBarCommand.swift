import Aztec
import WordPressEditor

struct AztecHeaderFormatBarCommand: AztecFormatBarCommand, AztecToggleHeaderCommand {
    let formattingIdentifier: FormattingIdentifier = .p

    private let optionsTablePresenter: OptionsTablePresenter

    init(optionsTablePresenter: OptionsTablePresenter) {
        self.optionsTablePresenter = optionsTablePresenter
    }

    func handleAction(editorView: EditorView, formatBarItem: FormatBarItem, formatBar: FormatBar) {
        toggleHeader(formatBarItem: formatBarItem, editorView: editorView, optionsTablePresenter: optionsTablePresenter)
    }
}
