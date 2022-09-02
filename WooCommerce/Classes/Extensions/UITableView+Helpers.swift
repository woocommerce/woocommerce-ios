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

// MARK: Swipe Actions
extension UITableView {

    /// Represents the values needed to provide a glance an animation to a swipe action.
    /// The `cell` is used to animate the view out in the glance animation.
    /// The `color` is used as a background color to give the swipe action effect.
    ///
    private struct GlanceActionConfiguration {
        let cell: UITableViewCell
        let color: UIColor
    }

    /// Slightly reveal swipe actions of the first visible cell that contains at least one swipe action.
    ///
    func glanceTrailingSwipeActions() {
        // If no swipe action configuration is found, do nothing.
        guard let glanceConfiguration = firstTrailingSwipeActionConfiguration() else {
            return
        }
        performGlanceAnimation(on: glanceConfiguration.cell, with: glanceConfiguration.color)
    }

    /// Returns the view configuration of the first visible cell that contains a swipe action.
    ///
    private func firstTrailingSwipeActionConfiguration() -> GlanceActionConfiguration? {
        // If there are no visible index paths, then there is no swipe action to glance.
        guard let visibleIndexPath = indexPathsForVisibleRows else {
            return nil
        }

        // Traverse through the visible cells and find the first one who has a swipe action.
        for indexPath in visibleIndexPath {
            guard
                let configuration = delegate?.tableView?(self, trailingSwipeActionsConfigurationForRowAt: indexPath),
                let action = configuration.actions.first,
                let cell = cellForRow(at: indexPath) else {
                    continue
                }

            return GlanceActionConfiguration(cell: cell, color: action.backgroundColor)
        }

        // Return `nil` if nothing is found.
        return nil
    }

    // Animates the cell out and in while leaving a solid color in place as a background to achieve a swipe action glance animation.
    //
    private func performGlanceAnimation(on cell: UITableViewCell, with color: UIColor) {
        // Defines animation time for glancing in/out
        let glanceAnimationDuration = 0.15

        // Amount of points of a swipe action to reveal during the animation
        let amountToReveal = 20.0

        // Color to be used as a background while the cell is animating.
        let colorBackground = UIView(frame: .init(x: cell.frame.width - amountToReveal,
                                                  y: cell.frame.origin.y,
                                                  width: amountToReveal,
                                                  height: cell.frame.height))
        colorBackground.backgroundColor = color
        addSubview(colorBackground)
        sendSubviewToBack(colorBackground)

        // Animate cell out
        UIView.animate(withDuration: glanceAnimationDuration, delay: 0, options: [.curveEaseOut]) {

            cell.transform = CGAffineTransform(translationX: -amountToReveal, y: 0) // Translate to the left.
        } completion: { _ in

            // Animate cell in
            UIView.animate(withDuration: glanceAnimationDuration, delay: 0, options: [.curveEaseIn]) {
                cell.transform = .identity // Restore its matrix transformation.
            } completion: { _ in

                // Clean state
                colorBackground.removeFromSuperview()
            }
        }
    }
}
