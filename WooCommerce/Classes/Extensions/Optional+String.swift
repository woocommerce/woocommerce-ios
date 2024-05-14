import Foundation

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        guard let self = self else {
            return true
        }
        return self.isEmpty
    }

    var isNilOrEmptyOrZero: Bool {
        guard !isNilOrEmpty else {
            return true
        }

        return self == "0"
    }
}
