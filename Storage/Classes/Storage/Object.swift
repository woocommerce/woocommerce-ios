import Foundation


///
///
public protocol Object: class {

    ///
    ///
    associatedtype ObjectID

    ///
    ///
    var objectID: ObjectID { get }

    ///
    ///
    static var entityName: String { get }
}
