import SwiftUI

/// `SwiftUI` wrapper for `ListSelectorViewController`
///
struct ListSelector<Command: ListSelectorCommand>: UIViewControllerRepresentable {

    /// Command that defines cell style and provide data.
    ///
    let command: Command

    /// Table view style.
    ///
    let tableStyle: UITableView.Style

    /// Closure to be invoked when the view is dismissed.
    ///
    var onDismiss: (Command.Model?) -> Void = { _ in }

    /// Creates `ViewController` with the provided parameters.
    ///
    func makeUIViewController(context: Context) -> ListSelectorViewController<Command, Command.Model, Command.Cell> {
        ListSelectorViewController(command: command, tableViewStyle: tableStyle, onDismiss: onDismiss)
    }

    /// Update the `ViewController` from parent `SwiftUI` view
    ///
    func updateUIViewController(_ uiViewController: ListSelectorViewController<Command, Command.Model, Command.Cell>, context: Context) {
        // No op
    }
}
