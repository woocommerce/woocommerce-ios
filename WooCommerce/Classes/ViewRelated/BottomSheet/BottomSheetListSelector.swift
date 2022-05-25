import SwiftUI

/// SwiftUI wrapper of `BottomSheetListSelectorViewController`.
///
struct BottomSheetListSelector<Command: BottomSheetListSelectorCommand, Model, Cell>: UIViewControllerRepresentable
    where Command.Model == Model, Command.Cell == Cell {

    private let viewProperties: BottomSheetListSelectorViewProperties
    private let command: Command
    private let onDismiss: ((_ selected: Model?) -> Void)?

    init(viewProperties: BottomSheetListSelectorViewProperties,
         command: Command,
         onDismiss: ((_ selected: Model?) -> Void)?) {
        self.viewProperties = viewProperties
        self.command = command
        self.onDismiss = onDismiss
    }

    func makeUIViewController(context: Context) -> BottomSheetListSelectorViewController<Command, Model, Cell> {
        return BottomSheetListSelectorViewController(viewProperties: viewProperties, command: command, onDismiss: onDismiss)
    }

    func updateUIViewController(_ uiViewController: BottomSheetListSelectorViewController<Command, Model, Cell>, context: Context) {
        // no-op
    }
}
