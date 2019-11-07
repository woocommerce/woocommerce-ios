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

    func handleAction(formattingIdentifier: FormattingIdentifier, editorView: EditorView, formatBar: FormatBar) {
        commandsByFormattingIdentifier[formattingIdentifier]?.handleAction(editorView: editorView, formatBar: formatBar)
    }
}
