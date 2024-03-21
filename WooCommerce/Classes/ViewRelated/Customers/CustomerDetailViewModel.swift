import Foundation
import struct Yosemite.WCAnalyticsCustomer
import WooFoundation

final class CustomerDetailViewModel {
    /// Customer name
    let name: String

    /// Date the customer was last active
    let dateLastActive: String

    /// Customer email
    let email: String?

    /// Whether the customer can be contacted via email
    lazy var canEmailCustomer: Bool = {
        email != nil
    }()

    // MARK: Orders

    /// Number of orders from the customer
    let ordersCount: String

    /// Customer's total spend
    let totalSpend: String

    /// Customer's average order value
    let avgOrderValue: String

    // MARK: Registration

    /// Customer username
    let username: String?

    /// Date the customer was registered on the store
    let dateRegistered: String?

    // MARK: Location

    /// Customer country
    let country: String?

    /// Customer region
    let region: String?

    /// Customer city
    let city: String?

    /// Customer postal code
    let postcode: String?

    init(name: String?,
         dateLastActive: String,
         email: String?,
         ordersCount: String,
         totalSpend: String,
         avgOrderValue: String,
         username: String?,
         dateRegistered: String?,
         country: String?,
         region: String?,
         city: String?,
         postcode: String?) {
        self.name = name ?? Localization.guestName
        self.dateLastActive = dateLastActive
        self.email = email
        self.ordersCount = ordersCount
        self.totalSpend = totalSpend
        self.avgOrderValue = avgOrderValue
        self.username = username
        self.dateRegistered = dateRegistered
        self.country = country
        self.region = region
        self.city = city
        self.postcode = postcode
    }

    convenience init(customer: WCAnalyticsCustomer,
                     currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.init(name: customer.name?.nullifyIfEmptyOrWhitespace(),
                  dateLastActive: DateFormatter.mediumLengthLocalizedDateFormatter.string(from: customer.dateLastActive),
                  email: customer.email?.nullifyIfEmptyOrWhitespace(),
                  ordersCount: customer.ordersCount.description,
                  totalSpend: currencyFormatter.formatAmount(customer.totalSpend) ?? customer.totalSpend.description,
                  avgOrderValue: currencyFormatter.formatAmount(customer.averageOrderValue) ?? customer.averageOrderValue.description,
                  username: customer.username?.nullifyIfEmptyOrWhitespace(),
                  dateRegistered: customer.dateRegistered.map { DateFormatter.mediumLengthLocalizedDateFormatter.string(from: $0) },
                  country: customer.country.nullifyIfEmptyOrWhitespace(),
                  region: customer.region.nullifyIfEmptyOrWhitespace(),
                  city: customer.city.nullifyIfEmptyOrWhitespace(),
                  postcode: customer.postcode.nullifyIfEmptyOrWhitespace())
    }
}

private extension String {
    /// Returns nil if the string is empty or only contains whitespace
    func nullifyIfEmptyOrWhitespace() -> Self? {
        self.trimmingCharacters(in: .whitespaces).isNotEmpty ? self : nil
    }
}

private extension CustomerDetailViewModel {
    enum Localization {
        static let guestName = NSLocalizedString("customerDetail.guestName",
                                                 value: "Guest",
                                                 comment: "Label for a customer with no name in the Customer detail screen.")
    }
}
