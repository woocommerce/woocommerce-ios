import SwiftUI
import ParcelFittingCheck

struct WooShippingPackageAndRatePlaceholder: View {
    /// Action to perform when a package is selected.
    let onSelectPackage: (WooShippingPackageDataRepresentable,
                          ParcelDimensions?,
                          [ParcelPresetCarrier],
                          Set<String>,
                          UnitLength) -> Void

    @State private var showAddPackage: Bool = false

    var body: some View {
        VStack(spacing: .zero) {
            Button {
                showAddPackage.toggle()
            } label: {
                Text(Localization.addPackage)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, Layout.padding)

            VStack(spacing: Layout.textSpacing) {
                Text(Localization.placeholderTitle)
                    .font(.subheadline)
                    .bold()
                Text(Localization.placeholderMessage)
                    .subheadlineStyle()
            }
        }
        .multilineTextAlignment(.center)
        .padding(Layout.padding)
        .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.border), lineWidth: Layout.borderLineWidth, dashed: true)
        .sheet(isPresented: $showAddPackage) {
            WooShippingAddPackageView { packageData, measurement, carriers, starred, unit in
                onSelectPackage(packageData, measurement, carriers, starred, unit)
                showAddPackage = false
            }
        }
    }
}

private extension WooShippingPackageAndRatePlaceholder {
    enum Layout {
        static let textSpacing: CGFloat = 8
        static let borderCornerRadius: CGFloat = 8
        static let borderLineWidth: CGFloat = 1
        static let padding: CGFloat = 32
    }

    enum Localization {
        static let addPackage = NSLocalizedString("wooShipping.createLabel.addPackage.button",
                                                  value: "Select a Package",
                                                  comment: "Button to select a package to use for a shipment in the shipping label creation flow.")
        static let placeholderTitle = NSLocalizedString(
            "wooShipping.createLabel.shippingRate.placeholderTitle",
            value: "Select a package to get shipping rates",
            comment: "Call to action in the shipping rate section during shipping label creation, when there is no selected package."
        )
        static let placeholderMessage = NSLocalizedString(
            "wooShipping.createLabel.shippingRate.placeholderMessage",
            value: "Enter your package's dimensions or pick a carrier package option to see the available shipping rates.",
            comment: "Message in the shipping rate section during shipping label creation, when there is no selected package."
        )
    }
}

#if DEBUG

import struct Yosemite.Order

#Preview {
    WooShippingPackageAndRatePlaceholder(onSelectPackage: { _, _, _, _, _ in })
        .padding()
}

// MARK: - Sample Data

extension Order {
    static let sampleOrder = Order(siteID: 0,
                                   orderID: 0,
                                   parentID: 0,
                                   customerID: 0,
                                   orderKey: "1",
                                   isEditable: false,
                                   needsPayment: true,
                                   needsProcessing: true,
                                   number: "1",
                                   status: .pending,
                                   currency: "USD",
                                   currencySymbol: "$",
                                   customerNote: "note",
                                   dateCreated: Date(),
                                   dateModified: Date(),
                                   datePaid: nil,
                                   discountTotal: "",
                                   discountTax: "",
                                   shippingTotal: "",
                                   shippingTax: "",
                                   total: "1.00",
                                   totalTax: "",
                                   paymentMethodID: "stripe",
                                   paymentMethodTitle: "Credit Card (Stripe)",
                                   paymentURL: nil,
                                   chargeID: nil,
                                   items: [],
                                   billingAddress: nil,
                                   shippingAddress: nil,
                                   shippingLines: [],
                                   coupons: [],
                                   refunds: [],
                                   fees: [],
                                   taxes: [],
                                   customFields: [],
                                   renewalSubscriptionID: nil,
                                   appliedGiftCards: [],
                                   attributionInfo: nil,
                                   shippingLabels: [],
                                   createdVia: "rest-api")
}
#endif
