import Foundation
import Codegen

/// Represents a predefined option in Shipping Labels for the WooCommerce Shipping extension.
///
public struct WooShippingPredefinedOption: Equatable, GeneratedFakeable {

    /// The ID of the shipping carrier for the predefined option, e.g. "usps".
    public let id: String

    /// List of saved predefined package IDs.
    public let predefinedPackageIDs: [String]

    public init(id: String, predefinedPackageIDs: [String]) {
        self.id = id
        self.predefinedPackageIDs = predefinedPackageIDs
    }
}
