import SwiftUI

struct POSSettingsStoreDetailView: View {
    @State private var isLoading: Bool = false
    @State private var showingWebView: Bool = false

    @Environment(\.posExternalViews) private var externalViews

    let viewModel: POSSettingsStoreViewModel

    init(viewModel: POSSettingsStoreViewModel) {
        self.viewModel = viewModel
    }

    private var backgroundColor: Color {
        Color.posSurface
    }

    private var cardBackgroundColor: Color {
        Color.posSurfaceContainerLowest
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
            }
            .background(backgroundColor)
            .task {
                isLoading = true
                await viewModel.retrievePOSReceiptSettings()
                isLoading = false
            }
        }
    }

    @ViewBuilder
    private var storeInformationView: some View {
        POSInformationCard {
            VStack(spacing: POSSpacing.none) {
                sectionHeaderView(title: Localization.storeInformation)

                VStack(spacing: POSSpacing.medium) {
                    POSInformationCardFieldRow(label: Localization.storeName, value: viewModel.storeName)
                    POSInformationCardFieldRow(label: Localization.address, value: viewModel.storeAddress, showSeparator: false)
                }
            }
        }
    }

    @ViewBuilder
    private var receiptInformationView: some View {
        POSInformationCard {
            VStack(spacing: POSSpacing.none) {
                receiptSectionHeaderView

                VStack(spacing: POSSpacing.medium) {
                    receiptFieldRowView(label: Localization.receiptStoreName, value: viewModel.receiptInformation.storeName)
                    receiptFieldRowView(label: Localization.physicalAddress, value: viewModel.receiptInformation.storeAddress)
                    receiptFieldRowView(label: Localization.phoneNumber, value: viewModel.receiptInformation.phone)
                    receiptFieldRowView(label: Localization.email, value: viewModel.receiptInformation.email)
                    receiptFieldRowView(label: Localization.refundReturnsPolicy,
                                        value: viewModel.receiptInformation.refundReturnsPolicy,
                                        showSeparator: false)
                }
                .padding(.bottom, POSPadding.medium)
            }
        }
        .posFullScreenCover(isPresented: $showingWebView) {
            if let adminURL = viewModel.receiptSettingsAdminURL {
                externalViews.createAuthenticatedWebView(
                    url: adminURL,
                    title: Localization.editReceiptWebViewTitle) {
                        showingWebView = false
                        Task {
                            isLoading = true
                            await viewModel.retrievePOSReceiptSettings()
                            isLoading = false
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var receiptSectionHeaderView: some View {
        ZStack {
            cardBackgroundColor
            HStack {
                Text(Localization.receiptInformation)
                    .font(.posBodyLargeBold)
                    .foregroundColor(.posOnSurface)

                Spacer()

                if viewModel.receiptSettingsAdminURL != nil {
                    Button(Localization.edit) {
                        showingWebView = true
                    }
                    .font(.posBodyMediumRegular())
                    .disabled(isLoading)
                }
            }
            .padding(.vertical, POSPadding.small)
        }
    }

    @ViewBuilder
    private func sectionHeaderView(title: String) -> some View {
        ZStack {
            cardBackgroundColor
            Text(title)
                .font(.posBodyLargeBold)
                .foregroundColor(.posOnSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, POSPadding.small)
        }
    }

    @ViewBuilder
    private func receiptFieldRowView(label: String, value: String?, showSeparator: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: POSPadding.small) {
            Text(label)
                .font(.posBodyMediumRegular())
            settingValueView(for: value)

            if showSeparator {
                Divider()
                    .padding(.top, POSPadding.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            "pointOfSaleSettingsStoreDetailView.general",
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

        static let edit = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.edit",
            value: "Edit",
            comment: "Button to edit receipt information in Point of Sale settings via web view."
        )

        static let editReceiptWebViewTitle = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.editReceiptWebViewTitle",
            value: "Receipt Settings",
            comment: "Navigation title for the web view used to edit POS receipt information."
        )
    }
}

#if DEBUG
#Preview {
    let controller = POSSettingsPreviewController()
    POSSettingsStoreDetailView(viewModel: controller.storeViewModel)
}
#endif
