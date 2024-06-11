import Foundation
import Yosemite
import WooFoundation

final class CustomerDetailViewModel: ObservableObject {
    private let stores: StoresManager

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

    /// Whether to show the customer's location data
    var showLocation: Bool {
        billing.isNilOrEmpty && shipping.isNilOrEmpty
    }

    /// Customer country
    let country: String?

    /// Customer region
    let region: String?

    /// Customer city
    let city: String?

    /// Customer postal code
    let postcode: String?

    // MARK: Address

    /// Formatted billing name and address
    @Published private(set) var billing: String?

    /// Formatted shipping name and address
    @Published private(set) var shipping: String?

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
         postcode: String?,
         billing: String?,
         shipping: String?,
         stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
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
                     currencySettings: CurrencySettings = ServiceLocator.currencySettings,
                     stores: StoresManager = ServiceLocator.stores) {
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
                  postcode: customer.postcode.nullifyIfEmptyOrWhitespace(),
                  billing: nil,
                  shipping: nil,
                  stores: stores)

        syncCustomerAddressData(siteID: customer.siteID, userID: customer.userID)
    }

    /// Copies the customer email to the pasteboard.
    func copyEmail() {
        email?.sendToPasteboard(includeTrailingNewline: false)
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailCopyEmailOptionTapped())
    }

    /// Tracks when the email menu is opened.
    func trackEmailMenuTapped() {
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailEmailMenuTapped())
    }

    /// Tracks when the option to send an email is tapped.
    func trackEmailOptionTapped() {
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailEmailOptionTapped())
    }
}

private extension CustomerDetailViewModel {
    /// Retrieves and sets the customer billing and shipping address from remote, for registered customers.
    ///
    func syncCustomerAddressData(siteID: Int64, userID: Int64) {
        // Only try to sync the address data for registered customers
        guard userID != 0 else {
            return
        }

        let action = CustomerAction.retrieveCustomer(siteID: siteID, customerID: userID) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(customer):
                billing = customer.billing?.fullNameWithCompanyAndAddress
                shipping = customer.shipping?.fullNameWithCompanyAndAddress
            case let .failure(error):
                DDLogError("⛔️ Error fetching customer details: \(error)")
            }
        }
        stores.dispatch(action)
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
