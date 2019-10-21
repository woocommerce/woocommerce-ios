import UIKit

extension UIView {
    /// Determines the axis along which the two views are laid out.
    /// This is based on the assumption that there are two subviews.
    /// Otherwise, nil is returned.
    ///
    func axisOfTwoSubviews() -> UIView.Axis? {
        guard subviews.count == 2 else {
            return nil
        }
        let sortedSubviews = subviews
            .sorted { (lhs, rhs) -> Bool in
                lhs.frame.minY < rhs.frame.minY
            }

        let subviewWithSmallerY = sortedSubviews[0]
        let subviewWithLargerY = sortedSubviews[1]

        return subviewWithLargerY.frame.minY >= subviewWithSmallerY.frame.maxY ? .vertical: .horizontal
    }
}
