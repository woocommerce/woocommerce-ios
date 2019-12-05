/// A wrapper of an array of a single Boolean value that indicates whether the Product Features are visible.
/// It has to be an array in order to be stored as a plist file.
///
struct ProductsVisibilityPListWrapper: Codable, Equatable {
    let isVisibleArray: [Bool]

    public init(isVisible: Bool) {
        self.isVisibleArray = [isVisible]
    }
}

extension ProductsVisibilityPListWrapper {
    var isVisible: Bool {
        return isVisibleArray[0]
    }
}
