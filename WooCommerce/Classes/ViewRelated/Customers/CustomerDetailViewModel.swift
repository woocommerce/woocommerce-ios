import Foundation
import Yosemite
import WooFoundation

final class CustomerDetailViewModel: ObservableObject {
    private let stores: StoresManager
    private let siteID: Int64
    private let customerID: Int64

    /// Customer name
    let name: String

    /// Date the customer was last active
    let dateLastActive: String

    /// Customer email
    let email: String?

    /// Source `Address` for the customer's phone number
    private var phoneSource: Address? {
        billing
    }

    /// Customer phone
    var phone: String? {
        phoneSource?.phone
    }

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
        formattedBilling.isNilOrEmpty && formattedShipping.isNilOrEmpty
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

    @Published private var billing: Address?
    @Published private var shipping: Address?

    /// Formatted billing name and address
    var formattedBilling: String? {
        billing?.fullNameWithCompanyAndAddress
    }

    /// Formatted shipping name and address
    var formattedShipping: String? {
        shipping?.fullNameWithCompanyAndAddress
    }

    // MARK: Sync

    /// Whether the view model is currently syncing customer data
    var isSyncing: Bool {
        syncState == .syncing
    }

    @Published private var syncState: CustomerSyncState = .unsynced

    init(siteID: Int64,
         customerID: Int64,
         name: String?,
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
         stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        self.siteID = siteID
        self.customerID = customerID
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
        self.init(siteID: customer.siteID,
                  customerID: customer.userID,
                  name: customer.name?.nullifyIfEmptyOrWhitespace(),
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
                  stores: stores)
    }

    /// Whether a new order can be created for the customer.
    var canCreateNewOrder: Bool {
        customerID != 0
    }

    /// Navigates to the Orders tab and opens a new order with this customer pre-filled in the order form.
    func createNewOrder() {
        guard canCreateNewOrder else {
            return
        }
        MainTabBarController.presentOrderCreationFlow(for: customerID, billing: billing, shipping: shipping)
    }
}

// MARK: Contact actions
extension CustomerDetailViewModel {
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

    /// Tracks when the phone menu is opened.
    func trackPhoneMenuTapped() {
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailPhoneMenuTapped())
    }

    /// Tracks when the option to send a text message is tapped.
    func trackMessageActionTapped() {
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailActionTapped(.message))
    }

    /// Copies the customer phone to the pasteboard.
    func copyPhone() {
        phone?.sendToPasteboard(includeTrailingNewline: false)
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailActionTapped(.copyPhone))
    }

    /// Whether the device can perform a phone call
    var isPhoneCallAvailable: Bool {
        guard let phoneURL = phoneSource?.cleanedPhoneNumberAsActionableURL else {
            return false
        }
        return UIApplication.shared.canOpenURL(phoneURL)
    }

    /// Attempts to perform a phone call at the specified URL
    func callCustomer() {
        guard let phoneURL = phoneSource?.cleanedPhoneNumberAsActionableURL else {
            return
        }
        UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailActionTapped(.call))
    }

    /// Whatsapp deeplink to contact someone through their phone number
    private var whatsappDeeplink: URL? {
        guard let phone = phoneSource?.cleanedPhoneNumber else {
            return nil
        }
        return URL(string: "whatsapp://send?phone=\(phone)")
    }

    /// Whether the device can open a WhatsApp deep link
    var isWhatsappAvailable: Bool {
        guard let whatsappDeeplink else {
            return false
        }
        return UIApplication.shared.canOpenURL(whatsappDeeplink)
    }

    /// Initiates communication with a customer via WhatsApp
    func sendWhatsappMessage() {
        guard let whatsappDeeplink else {
            return
        }
        UIApplication.shared.open(whatsappDeeplink)
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailActionTapped(.whatsapp))
    }

    /// Telegram deeplink to contact someone through their phone number
    private var telegramDeeplink: URL? {
        guard let phone = phoneSource?.cleanedPhoneNumber else {
            return nil
        }
        return URL(string: "tg://resolve?phone=\(phone)")
    }

    /// Whether the device can open a Telegram deep link
    var isTelegramAvailable: Bool {
        guard let telegramDeeplink else {
            return false
        }
        return UIApplication.shared.canOpenURL(telegramDeeplink)
    }

    /// Initiates communication with a customer via Telegram
    func sendTelegramMessage() {
        guard let telegramDeeplink else {
            return
        }
        UIApplication.shared.open(telegramDeeplink)
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailActionTapped(.telegram))
    }

    /// Copies the billing address to the pasteboard.
    func copyBillingAddress() {
        formattedBilling?.sendToPasteboard()
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailAddressCopied(.billing))
    }

    /// Copies the shipping address to the pasteboard.
    func copyShippingAddress() {
        formattedShipping?.sendToPasteboard()
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailAddressCopied(.shipping))
    }
}

// MARK: Syncing
extension CustomerDetailViewModel {

    /// Possible sync states for customer data
    private enum CustomerSyncState {
        case unsynced
        case syncing
        case synced
    }

    /// Retrieves the customer billing and shipping details from remote and sets the corresponding addresses and phone number, for registered customers.
    ///
    func syncCustomerAddressData() {
        // Only try to sync the address data for registered customers
        guard customerID != 0 else {
            return
        }

        syncState = .syncing
        let action = CustomerAction.retrieveCustomer(siteID: siteID, customerID: customerID) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(customer):
                billing = customer.billing
                shipping = customer.shipping
            case let .failure(error):
                DDLogError("⛔️ Error fetching customer details: \(error)")
            }
            syncState = .synced
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
