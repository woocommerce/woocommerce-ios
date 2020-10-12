import UIKit

extension UITableView {

    /// Return the last Index Path (the last row of the last section) if available
    func lastIndexPathOfTheLastSection() -> IndexPath? {
        guard numberOfSections > 0 else {
            return nil
        }
        let section = numberOfSections - 1

        guard numberOfRows(inSection: section) > 0 else {
            return nil
        }
        let row = numberOfRows(inSection: section) - 1

        return IndexPath(row: row, section: section)
    }
}

// MARK: Typesafe Register & Dequeue
extension UITableView {

    /// Registers a `UITableViewCell` using its `reuseIdentifier` property as the reuse identifier.
    ///
    func register(_ type: UITableViewCell.Type) {
        register(type, forCellReuseIdentifier: type.reuseIdentifier)
    }

    /// Registers a `UITableViewCell` nib  using its `reuseIdentifier` property as the reuse identifier.
    ///
    func registerNib(for type: UITableViewCell.Type) {
        register(type.loadNib(), forCellReuseIdentifier: type.reuseIdentifier)
    }

    /// Dequeue a previously registered cell by it's class `reuseIdentifier` property.
    /// Failing to dequeue the cell will throw a `fatalError`
    ///
    func dequeueReusableCell<T: UITableViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            let message = "Could not dequeue cell with identifier \(T.reuseIdentifier) at \(indexPath)"
            DDLogError(message)
            fatalError(message)
        }
        return cell
    }
}
