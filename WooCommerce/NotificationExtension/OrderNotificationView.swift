import Foundation
import SwiftUI
import WooFoundation

/// Custom order notification view.
///
struct OrderNotificationView: View {

    /// Type that represents the necessary information for this view.
    ///
    struct Content: Equatable {
        struct Product: Hashable, Equatable {
            let count: String
            let name: String
        }

        let storeName: String
        let date: String
        let orderNumber: String
        let amount: String
        let paymentMethod: String?
        let shippingMethod: String?
        let products: [Product]
    }

    let content: Content

    var body: some View {
        VStack(spacing: .zero) {

            // Notification header
            HStack {
                Image(Layout.iconName)
                    .cornerRadius(Layout.iconRadius)

                VStack(alignment: .leading, spacing: Layout.regularSpacing) {
                    Text(Localization.newOrder)
                    Text(content.storeName)
                        .bold()
                        .foregroundColor(Color(.text))
                }
                .subheadlineStyle()

                Spacer()

                VStack(alignment: .trailing, spacing: Layout.regularSpacing) {
                    Text(content.date)
                    Text(content.orderNumber)
                        .foregroundColor(Color(.text))
                }
                .subheadlineStyle()
            }
            .padding()

            Divider()

            // Total & Payment/Delivery method
            VStack(spacing: Layout.regularSpacing) {
                Text(content.amount)
                    .bold()
                    .largeTitleStyle()

                if let paymentMethod = content.paymentMethod {
                    Text(Localization.paidWith(method: paymentMethod))
                        .foregroundColor(Color(.textSubtle))
                        .captionStyle()
                }

                if let shippingMethod = content.shippingMethod {
                    Text(shippingMethod)
                        .foregroundColor(Color(.textSubtle))
                        .captionStyle()
                }
            }
            .padding()

            Divider()

            // Order Items
            VStack(alignment: .leading, spacing: Layout.productSpacing) {
                ForEach(content.products, id: \.self) { product in
                    HStack(alignment: .firstTextBaseline) {
                        Text(product.count)
                            .frame(minWidth: Layout.productCountMinLength, alignment: .trailing)
                        Text(product.name)
                            .bold()
                        Spacer()
                    }
                }
            }
            .padding()
            .foregroundColor(Color(.text))
            .subheadlineStyle()
        }
    }
}

private extension OrderNotificationView {
    enum Layout {
        static let iconName = "woo-icon"
        static let iconRadius = CGFloat(9)
        static let regularSpacing = CGFloat(4)
        static let productSpacing = CGFloat(8)
        static let productCountMinLength = CGFloat(30)
    }

    enum Localization {
        static let newOrder = AppLocalizedString("New order for", comment: "Rich order notification text, will read as: New order for MyCustom store")
        static func paidWith(method: String) -> LocalizedString {
            let format = AppLocalizedString("Paid with %@", comment: "Rich order notification text, will read as: Paid with Visa credit card")
            return LocalizedString(format: format, method)
        }
    }
}
