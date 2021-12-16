import Foundation

extension Bool {
    /// Represents bool value with a string
    ///
    var stringRepresentable: String {
        self ? "✔" : "–"
    }
}
