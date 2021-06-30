import Foundation


/// Defines the basic properties of any persisted entity.
///
public protocol Object: AnyObject {

    /// ObjectID Instance Type.
    ///
    associatedtype ObjectID

    /// Returns an instance of ObjectID: expected to identify the current instance, unequivocally.
    ///
    var objectID: ObjectID { get }

    /// Returns the receiver's Entity Name.
    ///
    static var entityName: String { get }
}
