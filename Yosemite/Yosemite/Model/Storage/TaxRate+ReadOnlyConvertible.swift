import Foundation
import Storage

// MARK: - Storage.TaxRate: ReadOnlyConvertible
//
extension Storage.TaxRate: ReadOnlyConvertible {

    /// Updates the Storage.TaxRate with the ReadOnly.
    ///
    public func update(with taxRate: Yosemite.TaxRate) {
        id = taxRate.id
        country = taxRate.country
        state = taxRate.state
        postcode = taxRate.postcode
        postcodes = taxRate.postcodes as NSObject
        priority = taxRate.priority
        rate = taxRate.rate
        name = taxRate.name
        order = taxRate.order
        taxRateClass = taxRate.taxRateClass
        shipping = taxRate.shipping
        compound = taxRate.compound
        city = taxRate.city
        cities = taxRate.cities as NSObject
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.TaxRate {
        .init(id: id,
              siteID: siteID,
              name: name ?? "",
              country: country ?? "",
              state: state ?? "",
              postcode: postcode ?? "",
              postcodes: postcodes as? [String] ?? [],
              priority: priority,
              rate: rate ?? "",
              order: order,
              taxRateClass: taxRateClass ?? "",
              shipping: shipping,
              compound: compound,
              city: city ?? "",
              cities: cities as? [String] ?? [])
    }
}
