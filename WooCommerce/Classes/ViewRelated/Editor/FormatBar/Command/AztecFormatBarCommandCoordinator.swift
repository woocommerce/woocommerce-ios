import Aztec

/// Coordinates the format bar commands for handling formatting actions.
struct AztecFormatBarCommandCoordinator {
    let commandsByFormattingIdentifier: [FormattingIdentifier: AztecFormatBarCommand]

    init(commands: [AztecFormatBarCommand]) {
        var commandsByFormattingIdentifier: [FormattingIdentifier: AztecFormatBarCommand] = [:]
        for command in commands {
            let formattingIdentifier = command.formattingIdentifier
            guard commandsByFormattingIdentifier[formattingIdentifier] == nil else {
                assertionFailure(
                    "Formatting command '\(formattingIdentifier.rawValue)'" +
                    "is already implemented by " +
                    "\(String(describing: commandsByFormattingIdentifier[formattingIdentifier]))"
                )
                continue
            }
            commandsByFormattingIdentifier[formattingIdentifier] = command
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
