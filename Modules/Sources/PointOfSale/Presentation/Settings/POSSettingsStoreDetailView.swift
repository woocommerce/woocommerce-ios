import SwiftUI

struct POSSettingsStoreDetailView: View {
    @State private var isLoading: Bool = false

    @ObservedObject var viewModel: POSSettingsStoreViewModel

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

                if viewModel.isEditing {
                    editableReceiptFieldsView
                } else {
                    readOnlyReceiptFieldsView
                }

                if let error = viewModel.saveError {
                    Text(error)
                        .font(.posBodySmallRegular())
                        .foregroundColor(.posError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, POSPadding.small)
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

                if viewModel.isEditing {
                    HStack(spacing: POSSpacing.small) {
                        Button(Localization.cancel) {
                            viewModel.cancelEditing()
                        }
                        .font(.posBodyMediumRegular())

                        Button {
                            Task {
                                await viewModel.saveReceiptInformation()
                            }
                        } label: {
                            if viewModel.isSaving {
                                ProgressView()
                            } else {
                                Text(Localization.save)
                            }
                        }
                        .font(.posBodyMediumBold)
                        .disabled(!viewModel.hasChanges || viewModel.isSaving)
                    }
                } else if !isLoading {
                    Button(Localization.edit) {
                        viewModel.startEditing()
                    }
                    .font(.posBodyMediumRegular())
                }
            }
            .padding(.vertical, POSPadding.small)
        }
    }

    @ViewBuilder
    private var readOnlyReceiptFieldsView: some View {
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

    @ViewBuilder
    private var editableReceiptFieldsView: some View {
        VStack(spacing: POSSpacing.medium) {
            editableFieldView(label: Localization.receiptStoreName, text: $viewModel.editableStoreName)
            editableFieldView(label: Localization.physicalAddress, text: $viewModel.editableStoreAddress)
            editableFieldView(label: Localization.phoneNumber, text: $viewModel.editablePhone)
            editableFieldView(label: Localization.email, text: $viewModel.editableEmail)
            editableFieldView(label: Localization.refundReturnsPolicy,
                              text: $viewModel.editableRefundReturnsPolicy,
                              isMultiline: true,
                              showSeparator: false)
        }
        .padding(.bottom, POSPadding.medium)
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
    private func editableFieldView(label: String,
                                   text: Binding<String>,
                                   isMultiline: Bool = false,
                                   showSeparator: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: POSPadding.small) {
            Text(label)
                .font(.posBodyMediumRegular())

            if isMultiline {
                TextEditor(text: text)
                    .font(.posBodyMediumRegular())
                    .frame(minHeight: Constants.multilineFieldMinHeight)
                    .scrollContentBackground(.hidden)
                    .background(Color.posSurfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            } else {
                TextField(Localization.notSet, text: text)
                    .font(.posBodyMediumRegular())
                    .textFieldStyle(.roundedBorder)
            }

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
        static let multilineFieldMinHeight: CGFloat = 80
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
            comment: "Button to start editing receipt information in Point of Sale settings."
        )

        static let save = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.save",
            value: "Save",
            comment: "Button to save receipt information changes in Point of Sale settings."
        )

        static let cancel = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.cancel",
            value: "Cancel",
            comment: "Button to cancel editing receipt information in Point of Sale settings."
        )
    }
}

#if DEBUG
#Preview {
    let controller = POSSettingsPreviewController()
    POSSettingsStoreDetailView(viewModel: controller.storeViewModel)
}
#endif
