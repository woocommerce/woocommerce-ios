import Foundation

final class WooRestAPIAuthenticationFormViewModel: ObservableObject {
    /// Email input.
    @Published var siteAddress: String = ""

    @Published private(set) var siteAddressErrorMessage: String?
}
