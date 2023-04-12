import Foundation

extension CaseIterable where Self: Equatable {
    /// Get the next item in of a `CaseIterable` `enum`
    /// - Returns: Next case if available.
    func next() -> Self? {
        let all = Self.allCases
        guard let selfIndex = all.firstIndex(of: self) else {
            return nil
        }

        let next = all.index(after: selfIndex)

        if next == all.endIndex {
            return nil
        }

        return all[next]
    }
}
