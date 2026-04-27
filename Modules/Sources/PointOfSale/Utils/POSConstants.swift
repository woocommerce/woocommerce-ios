import Foundation

enum POSConstants {
    enum URLs: String, CaseIterable {
        /// Returns the URL version of the receiver
        ///
        func asURL() -> URL {
            Self.trustedURL(self.rawValue)
        }

        /// URL for Point of Sale documentation
        ///
        case pointOfSaleDocumentation = "https://woocommerce.com/document/woo-mobile-app-point-of-sale-mode/"

        /// URL for Point of Sale's barcode scanner documentation
        ///
        case pointOfSaleBarcodeScannerDocumentation = "https://woocommerce.com/document/point-of-sale-mode-barcode-scanning/"

        /// URL for Point of Sale's IPP Woo Payments documentation
        ///
        case inPersonPaymentsLearnMoreWCPay =
                "https://woocommerce.com/document/getting-started-with-in-person-payments-woopayments/"
    }
}

private extension POSConstants.URLs {
    /// Convert a `string` to a `URL`. Crash if it is malformed.
    ///
    private static func trustedURL(_ url: String) -> URL {

        if let url = URL(string: url) {
            return url
        } else if let escapedString = url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed),
                  let escapedURL = URL(string: escapedString) {
            return escapedURL
        } else {
            fatalError("Expected URL \(url) to be a well-formed URL.")
        }
    }
}
