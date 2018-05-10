import Foundation


// MARK: - Action Methods meant for internal usage.
//
extension Action {

    /// TypeIdentifier Typealias.
    ///
    typealias TypeIdentifier = String

    /// Returns the TypeIdentifier associated with the Receiver's Kind.
    ///
    static var identifier: TypeIdentifier {
        return "\(self)"
    }
}
