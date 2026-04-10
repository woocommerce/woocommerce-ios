import Foundation


/// NSObject: Helper Methods
///
extension NSObject {

    /// Returns the receiver's classname as a string, not including the namespace.
    ///
    class func classNameWithoutNamespaces() -> String {
        guard let name = NSStringFromClass(self).components(separatedBy: ".").last else {
            fatalError()
        }

        return name
    }
}
