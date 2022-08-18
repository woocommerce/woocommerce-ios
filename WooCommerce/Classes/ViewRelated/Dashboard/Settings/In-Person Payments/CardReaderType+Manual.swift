import Foundation
import Yosemite

extension CardReaderType {
    var manual: Manual? {
        switch self {
        case .chipper:
            return Manual(
                id: 0,
                image: .cardReaderImageBBPOSChipper,
                name: "BBPOS Chipper 2X BT",
                urlString: "https://stripe.com/files/docs/terminal/c2xbt_product_sheet.pdf"
            )
        case .stripeM2:
            return Manual(
                id: 1,
                image: .cardReaderImageM2,
                name: "Stripe Reader M2",
                urlString: "https://stripe.com/files/docs/terminal/m2_product_sheet.pdf"
            )
        case .wisepad3:
            return Manual(
                id: 2,
                image: .cardReaderImageWisepad3,
                name: "Wisepad 3",
                urlString: "https://stripe.com/files/docs/terminal/wp3_product_sheet.pdf"
            )
        case .other:
            return nil
        }
    }
}
