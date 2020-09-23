import Foundation

public protocol MutableStorageType: class {
    func write(_ closure: @escaping (TransactionType) throws -> Void)
}
