import Foundation
import Yosemite

/// Represents a ProductVisibility Entity.
///
enum ProductVisibility {

    case publicVisibility
    case passwordProtected
    case privateVisibility

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .publicVisibility:
            return NSLocalizedString("Public", comment: "One of the possible options in Product Visibility")
        case .passwordProtected:
            return NSLocalizedString("Password Protected", comment: "One of the possible options in Product Visibility")
        case .privateVisibility:
            return NSLocalizedString("Private", comment: "One of the possible options in Product Visibility")
        }
    }

    /// Designated Initializer.
    ///
    public init(status: ProductStatus, password: String?) {
        if password?.isNotEmpty == true {
            self = .passwordProtected
        }
        else if status == .privateStatus {
            self = .privateVisibility
        }
        else {
            self = .publicVisibility
        }
    }
}
