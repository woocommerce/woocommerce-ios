import UIKit

/// Additional utilities for `UITableViewDiffableDataSource`.
///
@available(iOS 13.0, *)
extension UITableViewDiffableDataSource {
    /// Returns the index of the item pointed to by `indexPath` relative to the number of
    /// items in `snapshot()`.
    func indexOfItem(for indexPath: IndexPath) -> Int? {
        guard let identifier = itemIdentifier(for: indexPath) else {
            return nil
        }

        return snapshot().indexOfItem(identifier)
    }

    /// Returns the total number of items in the current `snapshot()`.
    var numberOfItems: Int {
        snapshot().numberOfItems
    }

    /// Returns `true` if there are no items in the current `snapshot()`.
    var isEmpty: Bool {
        numberOfItems == 0
    }

    /// Returns the section identifier for the given index.
    ///
    /// Note that the identifier is _not_ the title of the section. It should probably be converted
    /// to something else before it is presented to the user.
    func sectionIdentifier(for sectionIndex: Int) -> SectionIdentifierType? {
        snapshot().sectionIdentifiers[safe: sectionIndex]
    }
}
