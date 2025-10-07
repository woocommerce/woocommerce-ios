import Foundation
import SwiftUI

public enum SharedImageAsset: CaseIterable {
    case cardReaderUpdateProgressArrow
    case cardReaderUpdateProgressCheckmark
    case coupons
    case location
    case shoppingBags

    public var image: Image {
        Image(imageName, bundle: .module)
    }

    public var decorativeImage: Image {
        Image(decorative: imageName, bundle: .module)
    }

    public var uiImage: UIImage? {
        UIImage(named: imageName, in: .module, compatibleWith: nil)
    }

    private var imageName: String {
        switch self {
        case .cardReaderUpdateProgressArrow:
            "card-reader-update-progress-arrow"
        case .cardReaderUpdateProgressCheckmark:
            "card-reader-update-progress-checkmark"
        case .coupons:
            "coupons"
        case .location:
            "location"
        case .shoppingBags:
            "shopping-bags"
        }
    }
}
