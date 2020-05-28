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
    var onDeletedSections: ((IndexSet) -> Void)?

    /// Closure to be executed whenever `insertSections` is called.
    ///
    var onInsertedSections: ((IndexSet) -> Void)?



    // MARK: - Overridden Methods

    override func beginUpdates() {
        super.beginUpdates()
        onBeginUpdates?()
    }

    override func endUpdates() {
        super.endUpdates()
        onEndUpdates?()
    }

    override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        super.insertRows(at: indexPaths, with: animation)
        onInsertedRows?(indexPaths)
    }

    override func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        super.deleteRows(at: indexPaths, with: animation)
        onDeletedRows?(indexPaths)
    }

    override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        super.reloadRows(at: indexPaths, with: animation)
        onReloadRows?(indexPaths)
    }

    override func deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        super.deleteSections(sections, with: animation)
        onDeletedSections?(sections)
    }

    override func insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        super.insertSections(sections, with: animation)
        onInsertedSections?(sections)
    }
}
