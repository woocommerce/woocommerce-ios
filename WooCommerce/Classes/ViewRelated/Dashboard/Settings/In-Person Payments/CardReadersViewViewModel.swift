import Foundation
import SwiftUI

struct Manual: Identifiable {
    let id: Int
    let image: UIImage
    let name: String
    let urlString: String
}

final class CardReadersViewViewModel {
    let manuals: [Manual]

    init(manuals: [Manual] = [bbposChipper2XBT, stripeM2, wisepad3]) {
        self.manuals = manuals
    }
}

extension CardReadersViewViewModel {
    static let bbposChipper2XBT = Manual(
        id: 0,
        image: .cardReaderImageBBPOSChipper,
        name: "BBPOS Chipper 2X BT",
        urlString: "https://stripe.com/files/docs/terminal/c2xbt_product_sheet.pdf"
    )
    static let stripeM2 = Manual(
        id: 1,
        image: .cardReaderImageM2,
        name: "Stripe Reader M2",
        urlString: "https://stripe.com/files/docs/terminal/m2_product_sheet.pdf"
    )
    static let wisepad3 = Manual(
        id: 2,
        image: .cardReaderImageWisepad3,
        name: "Wisepad 3",
        urlString: "https://stripe.com/files/docs/terminal/wp3_product_sheet.pdf"
    )
}
