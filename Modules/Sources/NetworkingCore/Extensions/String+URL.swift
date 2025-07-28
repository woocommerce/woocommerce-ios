import Foundation

public extension String {
    /// Trims forward slash
    ///
    /// - Returns: String after removing prefix and suffix "/"
    ///
    func trimSlashes() -> String {
        removingPrefix("/").removingSuffix("/")
    }
}
