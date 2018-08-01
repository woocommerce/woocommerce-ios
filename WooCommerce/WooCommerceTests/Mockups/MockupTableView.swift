import Foundation
import UIKit


// MARK: - UITableView Mockup
//
class MockupTableView: UITableView {

    /// Closure to be executed whenever `beginUpdates` is called.
    ///
    var onBeginUpdates: (() -> Void)?

    /// Closure to be executed whenever `endUpdates` is called.
    ///
    var onEndUpdates: (() -> Void)?

    /// Closure to be executed whenever `insertRows` is called.
    ///
    var onInsertedRows: (([IndexPath]) -> Void)?

    /// Closure to be executed whenever `deleteRows` is called.
    ///
    var onDeletedRows: (([IndexPath]) -> Void)?

    /// Closure to be executed whenever `reloadRows` is called.
    ///
    var onReloadRows: (([IndexPath]) -> Void)?

    /// Closure to be executed whenever `deleteSections` is called.
    ///
    var onDeleteSections: ((IndexSet) -> Void)?

    /// Closure to be executed whenever `insertSections` is called.
    ///
    var onInsertSections: ((IndexSet) -> Void)?



    // MARK: - Overridden Methods

    override func beginUpdates() {
        onBeginUpdates?()
    }

    override func endUpdates() {
        onEndUpdates?()
    }

    override func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        onInsertedRows?(indexPaths)
    }

    override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        onDeletedRows?(indexPaths)
    }

    override func reloadRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        onReloadRows?(indexPaths)
    }

    override func deleteSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        onDeleteSections?(sections)
    }

    override func insertSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        onInsertSections?(sections)
    }
}
