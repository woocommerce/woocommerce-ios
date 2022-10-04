import Yosemite

/// Converts the input customer model to properties ready to be shown on TODO:`CustomerSearchView`.
struct CustomerSearchViewModel {
    let userID: Int64
    let name: String

    init(customer: WCAnalyticsCustomer) {
        userID = customer.userID
        name = customer.name ?? ""
    }
}
