import Foundation

extension Comparable {
    func clamped(to bounds: ClosedRange<Self>) -> Self {
        return max(min(self, bounds.upperBound), bounds.lowerBound)
    }
}
