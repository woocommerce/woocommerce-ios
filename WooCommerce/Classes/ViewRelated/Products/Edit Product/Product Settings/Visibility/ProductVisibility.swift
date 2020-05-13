import Foundation
import Yosemite

/// Represents a ProductVisibility Entity.
///
enum ProductVisibility {

    case `public`
    case passwordProtected
    case `private`

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .public:
            return NSLocalizedString("Public", comment: "One of the possible options in Product Visibility")
        case .passwordProtected:
            return NSLocalizedString("Password Protected", comment: "One of the possible options in Product Visibility")
        case .private:
            return NSLocalizedString("Private", comment: "One of the possible options in Product Visibility")
        }
    }

    /**
    * Designated Initializer.
    * The visibility is determined by the status and the password. If the password isn't empty, then
    * visibility is `passwordProtected`. If there's no password and the product status is `private`
    * then the visibility is `privateVisibility`, otherwise it's `publicVisibility`.
    */
    public init(status: ProductStatus, password: String?) {
        if password?.isNotEmpty == true {
            self = .passwordProtected
        }
        else if status == .privateStatus {
            self = .private
        }
        else {
            self = .public
        }
    }
}
