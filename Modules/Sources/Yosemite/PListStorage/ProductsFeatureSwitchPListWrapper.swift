/// A wrapper of an array of a single Boolean value that indicates whether the Product Features are visible.
/// It has to be an array in order to be stored as a plist file.
///
struct ProductsFeatureSwitchPListWrapper: Codable, Equatable {
    let isEnabledArray: [Bool]

    public init(isEnabled: Bool) {
        self.isEnabledArray = [isEnabled]
    }
}

extension ProductsFeatureSwitchPListWrapper {
    var isEnabled: Bool {
        return isEnabledArray[0]
    }
}
