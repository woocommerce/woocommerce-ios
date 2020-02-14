import Foundation

extension NSOrderedSet {
    func toArray<T>() -> [T] {
        guard let array = array as? [T] else {
            return []
        }
        return array
    }
}
