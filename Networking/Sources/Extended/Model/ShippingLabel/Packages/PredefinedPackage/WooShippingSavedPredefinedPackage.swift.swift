import Foundation
import Codegen
import WooFoundation

/// Container struct for a predefined Shipping Label Packages for the WooCommerce Shipping extension with group title and provider identifier.
///
public struct WooShippingSavedPredefinedPackage: Equatable, GeneratedFakeable, Identifiable {
    public let groupTitle: String
    public let providerID: String
    public let package: WooShippingPredefinedPackage

    public var id: String {
        return package.id
    }

    public init(groupTitle: String, providerID: String, package: WooShippingPredefinedPackage) {
        self.groupTitle = groupTitle
        self.providerID = providerID
        self.package = package
    }
}
