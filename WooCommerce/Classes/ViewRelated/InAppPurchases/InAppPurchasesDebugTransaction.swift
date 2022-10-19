import StoreKit
import SwiftUI

struct InAppPurchasesDebugTransaction: View {
    let id: UInt64
    let productDescription: String
    let purchaseDate: Date
    let expirationDate: Date?
    let revocationDate: Date?

    init(
        id: UInt64,
        productDescription: String,
        purchaseDate: Date,
        expirationDate: Date? = nil,
        revocationDate: Date? = nil
    ) {
        self.id = id
        self.productDescription = productDescription
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
    }

    init(transaction: StoreKit.Transaction) {
        self.init(
            id: transaction.id,
            productDescription: transaction.productID,
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate,
            revocationDate: transaction.revocationDate)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(id): \(productDescription)")
                .bold()
            Text("Purchased: \(purchaseDate.formatted())")
            if let expirationDate {
                Text("Expires: \(expirationDate.formatted())")
            }
            if revocationDate != nil {
                Text("Refunded")
                    .footnoteStyle()
            }
        }
    }
}

struct InAppPurchasesDebugTransaction_Previews: PreviewProvider {
    static var previews: some View {
        List {
            // Regular subscription
            InAppPurchasesDebugTransaction(
                id: 0,
                productDescription: "woocommerce_entry_monthly",
                purchaseDate: .now.adding(days: -1)!,
                expirationDate: .now.adding(days: 20),
                revocationDate: nil)

            // Refunded subscription
            InAppPurchasesDebugTransaction(
                id: 1,
                productDescription: "woocommerce_entry_monthly",
                purchaseDate: .now.adding(days: -1)!,
                expirationDate: .now.adding(days: 20),
                revocationDate: .now)
        }
    }
}
