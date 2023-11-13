import Foundation
import UIKit
import Yosemite
import WooFoundation

struct OrderDetailsCustomAmountCellViewModel {
    let name: String
    let total: String
    let image: UIImage = .borderedCustomAmount

    init(customAmount: OrderFeeLine, currency: String, currencyFormatter: CurrencyFormatter) {
        name = customAmount.name ?? String()
        total = currencyFormatter.formatAmount(customAmount.total, with: currency) ?? String()
    }
}
