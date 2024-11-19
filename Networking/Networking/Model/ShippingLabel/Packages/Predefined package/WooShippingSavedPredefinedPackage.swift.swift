import Foundation
import Codegen
import WooFoundation

/// Container struct for a predefined Shipping Label Packages for the WooCommerce Shipping extension with group title and provider identifier.
///
public struct WooShippingSavedPredefinedPackage: Equatable, GeneratedFakeable, Identifiable {
    let groupTitle: String
    let providerID: String
    let package: WooShippingPredefinedPackage

    public var id: String {
        return package.id
    }
}
