import Foundation

extension String {
    /// Trims front slash
    ///
    /// - Returns: String after removing prefix and suffix "/"
    ///
    func trimSlashes() -> String {
        removingPrefix("/").removingSuffix("/")
    }
}
