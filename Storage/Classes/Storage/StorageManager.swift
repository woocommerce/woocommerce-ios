import Foundation


///
///
public protocol StorageManager {

    ///
    ///
    var viewStorage: Storage { get }

    ///
    ///
    func performBackgroundTask(_ closure: @escaping (Storage) -> Void)
}
