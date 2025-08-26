import SwiftUI

struct PointOfSaleSettingsStoreDetailView: View {
    let settingsController: PointOfSaleSettingsController

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Group {
                    Text(Localization.storeInformation)
                        .font(.posBodyLargeRegular())

                    Text(Localization.storeName)
                    Text(settingsController.storeName)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)

                    Text(Localization.address)
                    Text(settingsController.storeAddress)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }

                Group {
                    Spacer()
                    Text(Localization.receiptInformation)
                        .font(.posBodyLargeRegular())
                    Text(Localization.receiptStoreName)
                    settingValueView(for: settingsController.receiptStoreName)

                    Text(Localization.physicalAddress)
                    settingValueView(for: settingsController.receiptStoreAddress)

                    Text(Localization.phoneNumber)
                    settingValueView(for: settingsController.receiptStorePhone)

                    Text(Localization.email)
                    settingValueView(for: settingsController.receiptStoreEmail)

                    Text(Localization.refundReturnsPolicy)
                    settingValueView(for: settingsController.receiptRefundReturnsPolicy)

                }
                .renderedIf(settingsController.shouldShowReceiptInformation)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func settingValueView(for value: String?) -> some View {
        if settingsController.isLoading {
            ProgressView()
                .font(.posBodyLargeRegular())
        } else {
            Text(value ?? Localization.notSet)
                .font(.posBodyMediumRegular())
                .foregroundStyle(.secondary)
        }
    }
}

private extension PointOfSaleSettingsStoreDetailView {
    enum Localization {
        static let notSet = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.notSet",
            value: "Not set",
            comment: "Text displayed on Point of Sale settings when any setting has not been provided."
        )

        static let storeInformation = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.storeInformation",
            value: "Store Information",
            comment: "Section title for store information in Point of Sale settings."
        )

        static let storeName = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.storeName",
            value: "Store name",
            comment: "Label for store name field in Point of Sale settings."
        )

        static let address = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.address",
            value: "Address",
            comment: "Label for address field in Point of Sale settings."
        )

        static let receiptInformation = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.receiptInformation",
            value: "Receipt Information",
            comment: "Section title for receipt information in Point of Sale settings."
        )

        static let receiptStoreName = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.receiptStoreName",
            value: "Store name",
            comment: "Label for receipt store name field in Point of Sale settings."
        )

        static let physicalAddress = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.physicalAddress",
            value: "Physical address",
            comment: "Label for physical address field in Point of Sale settings."
        )

        static let phoneNumber = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.phoneNumber",
            value: "Phone number",
            comment: "Label for phone number field in Point of Sale settings."
        )

        static let email = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.email",
            value: "Email",
            comment: "Label for email field in Point of Sale settings."
        )

        static let refundReturnsPolicy = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.refundReturnsPolicy",
            value: "Refund & Returns Policy",
            comment: "Label for refund and returns policy field in Point of Sale settings."
        )
    }
}

//#Preview {
//    PointOfSaleSettingsStoreDetailView(posSettingsService: PointOfSaleSettingsController())
//}
