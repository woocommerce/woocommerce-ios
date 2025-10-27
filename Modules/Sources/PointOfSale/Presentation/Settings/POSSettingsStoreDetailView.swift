import SwiftUI

struct POSSettingsStoreDetailView: View {
    @State private var isLoading: Bool = false

    let viewModel: POSSettingsStoreViewModel

    init(viewModel: POSSettingsStoreViewModel) {
        self.viewModel = viewModel
    }

    private var backgroundColor: Color {
        Color.posOnSecondaryContainer
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: POSSpacing.none) {
                POSPageHeaderView(title: Localization.storeTitle)
                    .foregroundColor(.posSurface)
                    .accessibilityAddTraits(.isHeader)

                ScrollView {
                    VStack(spacing: POSSpacing.medium) {
                        storeInformationView

                        receiptInformationView
                            .renderedIf(viewModel.shouldShowReceiptInformation)
                    }
                    .padding(.horizontal, POSPadding.medium)
                }
                .background(Color.posSurface)
            }
            .background(Color.posSurface)
            .task {
                isLoading = true
                await viewModel.retrievePOSReceiptSettings()
                isLoading = false
            }
        }
    }

    @ViewBuilder
    private var storeInformationView: some View {
        VStack(spacing: POSSpacing.none) {
            sectionHeaderView(title: Localization.storeInformation)

            VStack(spacing: POSSpacing.medium) {
                fieldRowView(label: Localization.storeName, value: viewModel.storeName)
                fieldRowView(label: Localization.address, value: viewModel.storeAddress)
            }
            .padding(.bottom, POSPadding.medium)
        }
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private var receiptInformationView: some View {
        VStack(spacing: POSSpacing.none) {
            sectionHeaderView(title: Localization.receiptInformation)

            VStack(spacing: POSSpacing.medium) {
                receiptFieldRowView(label: Localization.receiptStoreName, value: viewModel.receiptInformation.storeName)
                receiptFieldRowView(label: Localization.physicalAddress, value: viewModel.receiptInformation.storeAddress)
                receiptFieldRowView(label: Localization.phoneNumber, value: viewModel.receiptInformation.phone)
                receiptFieldRowView(label: Localization.email, value: viewModel.receiptInformation.email)
                receiptFieldRowView(label: Localization.refundReturnsPolicy, value: viewModel.receiptInformation.refundReturnsPolicy)
            }
            .padding(.bottom, POSPadding.medium)
        }
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private func sectionHeaderView(title: String) -> some View {
        ZStack {
            backgroundColor
            Text(title)
                .font(.posBodyLargeBold)
                .foregroundColor(.posOnSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, POSPadding.medium)
                .padding(.vertical, POSPadding.small)
        }
    }

    @ViewBuilder
    private func fieldRowView(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: POSPadding.small) {
            Text(label)
                .font(.posBodyMediumRegular())
            Text(value)
                .font(.posBodyMediumRegular())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, POSPadding.medium)
    }

    @ViewBuilder
    private func receiptFieldRowView(label: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: POSPadding.small) {
            Text(label)
                .font(.posBodyMediumRegular())
            settingValueView(for: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, POSPadding.medium)
    }

    @ViewBuilder
    private func settingValueView(for value: String?) -> some View {
        if isLoading {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.shimmeringTextWidth, height: Constants.shimmeringTextHeight)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        } else {
            Text(value ?? Localization.notSet)
                .font(.posBodyMediumRegular())
                .foregroundStyle(.secondary)
        }
    }
}


private extension POSSettingsStoreDetailView {
    enum Constants {
        static let shimmeringTextWidth: CGFloat = 70
        static let shimmeringTextHeight: CGFloat = 16
    }

    enum Localization {
        static let storeTitle = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.storeTitle",
            value: "Store",
            comment: "Navigation title for the store details in POS settings."
        )

        static let notSet = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.notSet",
            value: "Not set",
            comment: "Text displayed on Point of Sale settings when any setting has not been provided."
        )

        static let storeInformation = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.generalInformation",
            value: "General",
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
    POSSettingsStoreDetailView(viewModel: controller.storeViewModel)
}
#endif
