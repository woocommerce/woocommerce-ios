import SwiftUI

struct PointOfSaleSettingsStoreDetailView: View {
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
                }
                .background(backgroundColor)
            }
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
            ZStack {
                backgroundColor
                Text(Localization.storeInformation)
                    .font(.posBodyLargeBold)
                    .foregroundColor(.posOnSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, POSPadding.medium)
                    .padding(.vertical, POSPadding.small)
            }

            VStack(spacing: POSSpacing.medium) {
                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(Localization.storeName)
                        .font(.posBodyMediumRegular())
                    Text(viewModel.storeName)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, POSPadding.medium)

                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(Localization.address)
                        .font(.posBodyMediumRegular())
                    Text(viewModel.storeAddress)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, POSPadding.medium)
            }
            .padding(.bottom, POSPadding.medium)
        }
    }

    @ViewBuilder
    private var receiptInformationView: some View {
        VStack(spacing: POSSpacing.none) {
            ZStack {
                backgroundColor
                Text(Localization.receiptInformation)
                    .font(.posBodyLargeBold)
                    .foregroundColor(.posOnSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, POSPadding.medium)
                    .padding(.vertical, POSPadding.small)
            }

            VStack(spacing: POSSpacing.medium) {
                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(Localization.receiptStoreName)
                        .font(.posBodyMediumRegular())
                    settingValueView(for: viewModel.receiptInformation.storeName)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, POSPadding.medium)

                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(Localization.physicalAddress)
                        .font(.posBodyMediumRegular())
                    settingValueView(for: viewModel.receiptInformation.storeAddress)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, POSPadding.medium)

                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(Localization.phoneNumber)
                        .font(.posBodyMediumRegular())
                    settingValueView(for: viewModel.receiptInformation.phone)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, POSPadding.medium)

                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(Localization.email)
                        .font(.posBodyMediumRegular())
                    settingValueView(for: viewModel.receiptInformation.email)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, POSPadding.medium)

                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(Localization.refundReturnsPolicy)
                        .font(.posBodyMediumRegular())
                    settingValueView(for: viewModel.receiptInformation.refundReturnsPolicy)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, POSPadding.medium)
            }
            .padding(.bottom, POSPadding.medium)
        }
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


private extension PointOfSaleSettingsStoreDetailView {
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
