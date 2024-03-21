import Foundation
import struct Yosemite.WCAnalyticsCustomer
import WooFoundation

struct CustomerDetailViewModel {
    /// Customer name
    let name: String

    /// Date the customer was last active
    let dateLastActive: String

    /// Customer email
    let email: String?

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

    init(customer: WCAnalyticsCustomer,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)

        name = customer.name?.nullifyIfEmptyOrWhitespace() ?? Localization.guestName
        dateLastActive = DateFormatter.mediumLengthLocalizedDateFormatter.string(from: customer.dateLastActive)
        email = customer.email?.nullifyIfEmptyOrWhitespace()
        ordersCount = customer.ordersCount.description
        totalSpend = currencyFormatter.formatAmount(customer.totalSpend) ?? customer.totalSpend.description
        avgOrderValue = currencyFormatter.formatAmount(customer.averageOrderValue) ?? customer.averageOrderValue.description
        username = customer.username?.nullifyIfEmptyOrWhitespace()
        dateRegistered = customer.dateRegistered.map { DateFormatter.mediumLengthLocalizedDateFormatter.string(from: $0) }
        country = customer.country.nullifyIfEmptyOrWhitespace()
        region = customer.region.nullifyIfEmptyOrWhitespace()
        city = customer.city.nullifyIfEmptyOrWhitespace()
        postcode = customer.postcode.nullifyIfEmptyOrWhitespace()
    }
}

private extension String {
    /// Returns nil if the string is empty or only contains whitespace
    func nullifyIfEmptyOrWhitespace() -> Self? {
        self.trimmingCharacters(in: .whitespaces).isNotEmpty ? self : nil
    }
}

extension CustomerDetailView {
    init(viewModel: CustomerDetailViewModel) {
        self.name = viewModel.name
        self.email = viewModel.email
        self.dateLastActive = viewModel.dateLastActive
        self.ordersCount = viewModel.ordersCount
        self.totalSpend = viewModel.totalSpend
        self.avgOrderValue = viewModel.avgOrderValue
        self.username = viewModel.username
        self.dateRegistered = viewModel.dateRegistered
        self.country = viewModel.country
        self.region = viewModel.region
        self.city = viewModel.city
        self.postcode = viewModel.postcode
    }
}

private extension CustomerDetailViewModel {
    enum Localization {
        static let guestName = NSLocalizedString("customerDetail.guestName",
                                                 value: "Guest",
                                                 comment: "Label for a customer with no name in the Customer detail screen.")
    }
}
