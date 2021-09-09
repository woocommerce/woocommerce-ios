import SwiftUI

/// Protocol required to re-render the view when the command updates any of it's content.
///
protocol ObservableListSelectorCommand: ListSelectorCommand, ObservableObject {}

/// `SwiftUI` wrapper for `ListSelectorViewController`
///
struct ListSelector<Command: ObservableListSelectorCommand>: UIViewControllerRepresentable {

    /// Command that defines cell style and provide data.
    ///
    @ObservedObject var command: Command

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
        uiViewController.reloadData()
    }
}
