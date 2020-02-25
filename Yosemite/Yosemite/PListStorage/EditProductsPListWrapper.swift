/// A wrapper of an array of a single Boolean value that indicates whether the Edit Product feature is enabled for the user.
/// It has to be an array in order to be stored as a plist file.
///
struct EditProductsPListWrapper: Codable, Equatable {
    let isEnabledArray: [Bool]

    public init(isEnabled: Bool) {
        self.isEnabledArray = [isEnabled]
    }
}

extension EditProductsPListWrapper {
    var isEnabled: Bool {
        return isEnabledArray[0]
    }
}
