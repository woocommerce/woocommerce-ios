import SwiftUI

struct PointOfSaleSettingsStoreDetailView: View {
    @State private var isLoading: Bool = false

    let viewModel: POSSettingsStoreViewModel

    init(viewModel: POSSettingsStoreViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.storeName)
                            .font(.posBodyMediumRegular())
                        Text(viewModel.storeName)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.address)
                            .font(.posBodyMediumRegular())
                        Text(viewModel.storeAddress)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(Localization.storeInformation)
                        .font(.posBodyLargeRegular())
                        .textCase(nil)
                }

                Section {
                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.receiptStoreName)
                            .font(.posBodyMediumRegular())
                        settingValueView(for: viewModel.receiptInformation.storeName)
                    }

                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.physicalAddress)
                            .font(.posBodyMediumRegular())
                        settingValueView(for: viewModel.receiptInformation.storeAddress)
                    }

                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.phoneNumber)
                            .font(.posBodyMediumRegular())
                        settingValueView(for: viewModel.receiptInformation.phone)
                    }

                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.email)
                            .font(.posBodyMediumRegular())
                        settingValueView(for: viewModel.receiptInformation.email)
                    }

                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.refundReturnsPolicy)
                            .font(.posBodyMediumRegular())
                        settingValueView(for: viewModel.receiptInformation.refundReturnsPolicy)
                    }
                } header: {
                    Text(Localization.receiptInformation)
                        .font(.posBodyLargeRegular())
                        .textCase(nil)
                }
                .renderedIf(viewModel.shouldShowReceiptInformation)
            }
            .task {
                isLoading = true
                await viewModel.retrievePOSReceiptSettings()
                isLoading = false
            }
        }
    }

    @ViewBuilder
    private func settingValueView(for value: String?) -> some View {
        if isLoading {
            GhostSettingRowView()
        } else {
            Text(value ?? Localization.notSet)
                .font(.posBodyMediumRegular())
                .foregroundStyle(.secondary)
        }
    }
}

// Temporary: Simplified copy from PointOfSaleOrderListView.GhostOrderRowView
private struct GhostSettingRowView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var minHeight: CGFloat {
        min(Constants.orderCardMinHeight * scale, Constants.maximumOrderCardHeight)
    }

    var body: some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: 70, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()

                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: 160, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()
            }
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : minHeight, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .geometryGroup()
    }

    private enum Constants {
        static let orderCardMinHeight: CGFloat = 90
        static let maximumOrderCardHeight: CGFloat = Constants.orderCardMinHeight * 2
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

#if DEBUG
#Preview {
    let controller = PointOfSaleSettingsPreviewController()
    PointOfSaleSettingsStoreDetailView(viewModel: controller.storeViewModel)
}
#endif
