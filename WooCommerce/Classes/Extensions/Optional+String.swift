import Foundation

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        guard let self = self else {
            return true
        }
        return self.isEmpty
    }
}
