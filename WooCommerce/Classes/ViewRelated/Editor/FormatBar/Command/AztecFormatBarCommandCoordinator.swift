import Aztec

struct AztecFormatBarCommandCoordinator {
    let commandsByFormattingIdentifier: [FormattingIdentifier: AztecFormatBarCommand]

    init(commands: [AztecFormatBarCommand]) {
        var commandsByFormattingIdentifier: [FormattingIdentifier: AztecFormatBarCommand] = [:]
        commands.forEach { command in
            commandsByFormattingIdentifier[command.formattingIdentifier] = command
        }
        self.commandsByFormattingIdentifier = commandsByFormattingIdentifier
    }

    func handleAction(formatBarItem: FormatBarItem, editorView: EditorView, formatBar: FormatBar) {
        guard let identifier = formatBarItem.identifier,
            let formattingIdentifier = FormattingIdentifier(rawValue: identifier) else {
            return
        }
        commandsByFormattingIdentifier[formattingIdentifier]?.handleAction(editorView: editorView, formatBarItem: formatBarItem, formatBar: formatBar)
    }
}
