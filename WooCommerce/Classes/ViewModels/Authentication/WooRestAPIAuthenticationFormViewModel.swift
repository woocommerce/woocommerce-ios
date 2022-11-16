import Foundation
import Yosemite

final class WooRestAPIAuthenticationFormViewModel: ObservableObject {
    @Published var siteAddress: String = ""

    @Published private(set) var siteAddressErrorMessage: String?

    @Published var consumerKey: String = ""

    @Published private(set) var consumerKeyErrorMessage: String?

    @Published var consumerSecret: String = ""

    @Published private(set) var consumerSecretErrorMessage: String?

    var credentials: WooRestAPICredentials? {
        guard siteAddress.isNotEmpty, consumerKey.isNotEmpty, consumerSecret.isNotEmpty else {
            return nil
        }

        return WooRestAPICredentials(consumer_key: consumerKey,
                                     consumer_secret: consumerSecret,
                                     siteAddress: siteAddress)
    }
}
