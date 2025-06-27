import Foundation


// MARK: - Action Methods meant for internal usage.
//
extension Action {

    /// TypeIdentifier Typealias.
    ///
    typealias TypeIdentifier = String

    /// Returns the TypeIdentifier associated with the Receiver's Type.
    ///
    var identifier: TypeIdentifier {
        return type(of: self).identifier
    }

    /// Returns the TypeIdentifier associated with the Receiver's Type.
    ///
    static var identifier: TypeIdentifier {
        return "\(self)"
    }
}


// MARK: - Actions Processor meant for internal usage.
//
extension ActionsProcessor {

    /// TypeIdentifier Typealias.
    ///
    typealias TypeIdentifier = ObjectIdentifier

    /// Returns the TypeIdentifier associated with the Receiver's Type.
    ///
    var identifier: TypeIdentifier {
        return ObjectIdentifier(self)
    }
}
