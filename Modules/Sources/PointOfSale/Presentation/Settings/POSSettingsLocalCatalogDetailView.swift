import SwiftUI

struct POSSettingsLocalCatalogDetailView: View {
    private let viewModel: POSSettingsLocalCatalogViewModel

    init(viewModel: POSSettingsLocalCatalogViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            VStack(spacing: POSSpacing.none) {
                POSPageHeaderView(title: Localization.localCatalogTitle)
                    .foregroundColor(.posSurface)
                    .accessibilityAddTraits(.isHeader)

                ScrollView {
                    VStack(spacing: POSSpacing.medium) {
                        catalogStatus
                        if viewModel.deviceHasCellularCapability {
                            managingDataUsage
                        }
                        manualCatalogUpdate
                    }
                    .padding(.horizontal, POSPadding.medium)
                }
            }
            .background(Style.backgroundColor)
        }
        .task {
            await viewModel.loadCatalogData()
        }
        .posModal(item: $viewModel.catalogRefreshError) { error in
            errorView(errorState: error.errorState)
        }
    }
}

private extension POSSettingsLocalCatalogDetailView {
    @ViewBuilder
    var catalogStatus: some View {
        POSInformationCard {
            VStack(spacing: POSSpacing.small) {
                POSInformationCardFieldRow(
                    label: Localization.catalogSize,
                    value: viewModel.catalogSize
                )
                POSInformationCardFieldRow(
                    label: Localization.lastIncrementalSync,
                    value: viewModel.lastIncrementalSyncDate
                )
                POSInformationCardFieldRow(
                    label: Localization.lastFullSync,
                    value: viewModel.lastFullSyncDate,
                    showSeparator: false
                )
            }
        }
        .redacted(reason: viewModel.isLoading ? .placeholder : [])
        .shimmering(active: viewModel.isLoading)
    }

    @ViewBuilder
    var managingDataUsage: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: POSSpacing.none) {
            POSInformationCard {
                POSInformationCardFieldRowWithToggle(
                    label: Localization.managingDataUsage,
                    value: Localization.allowSyncOnCellular,
                    showSeparator: false,
                    isOn: $viewModel.allowFullSyncOnCellular
                )
            }
        }
    }

    @ViewBuilder
    var manualCatalogUpdate: some View {
        VStack(spacing: POSSpacing.none) {
            POSInformationCard {
                POSInformationCardFieldRow(
                    label: Localization.manualCatalogUpdate,
                    value: Localization.manualUpdateInfo,
                    showSeparator: false,
                    labelStyle: .bold,
                    buttonTitle: Localization.updateCatalog,
                    buttonAction: {
                        Task {
                            await viewModel.refreshCatalog()
                        }
                    },
                    buttonStyle: .primary,
                    isLoading: viewModel.isRefreshingCatalog
                )
            }
        }
    }

    @ViewBuilder
    func errorView(errorState: PointOfSaleErrorState) -> some View {
        VStack(spacing: POSSpacing.xxLarge) {
            POSModalCloseButton(accessibilityLabel: Localization.errorCancelButtonTitle) {
                viewModel.catalogRefreshError = nil
            }

            POSErrorView(viewModel: errorViewModel(errorState: errorState))
        }
        .padding(POSPadding.xLarge)
        .frame(maxWidth: Constants.errorModalMaxWidth)
    }

    func errorViewModel(errorState: PointOfSaleErrorState) -> POSErrorViewModel {
        let retryButton = POSErrorButtonViewModel(title: Localization.errorRetryButtonTitle,
                                                  buttonStyle: POSFilledButtonStyle(size: .normal)) {
            Task {
                await viewModel.refreshCatalog()
            }
        }
        let cancelButton = POSErrorButtonViewModel(title: Localization.errorCancelButtonTitle,
                                                   buttonStyle: POSOutlinedButtonStyle(size: .normal)) {
            viewModel.catalogRefreshError = nil
        }
        return POSErrorViewModel(error: errorState, primaryButton: retryButton, secondaryButton: cancelButton)
    }

}

private extension POSSettingsLocalCatalogDetailView {
    enum Style {
        static let backgroundColor = Color.posSurface
    }

    enum Localization {
        static let localCatalogTitle = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.title.1",
            value: "Product catalog",
            comment: "Navigation title for the local catalog details in POS settings."
        )

        static let managingDataUsage = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.managingDataUsage.2",
            value: "Cellular data",
            comment: "Section title for managing data usage in Point of Sale settings."
        )

        static let lastIncrementalSync = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.lastIncrementalSync.1",
            value: "Last incremental sync",
            comment: "Label for last incremental sync field in Point of Sale settings."
        )

        static let lastFullSync = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.lastFullSync.2",
            value: "Last full sync",
            comment: "Label for last full sync field in Point of Sale settings."
        )

        static let catalogSize = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.catalogSize.1",
            value: "Size",
            comment: "Label for catalog size field in Point of Sale settings."
        )

        static let allowSyncOnCellular = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.allowSyncOnCellular.2",
            value: "Allow sync using cellular data",
            comment: "Label for allow sync on cellular data toggle in Point of Sale settings."
        )

        static let manualCatalogUpdate = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.manualCatalogUpdate.1",
            value: "Catalog update",
            comment: "Section title for manual catalog update in Point of Sale settings."
        )

        static let manualUpdateInfo = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.manualUpdateInfo.1",
            value: "Update the catalog manually",
            comment: "Info text explaining the usage of the manual catalog update button."
        )

        static let updateCatalog = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.updateCatalog",
            value: "Update catalog",
            comment: "Button text for updating the catalog manually."
        )

        static let errorRetryButtonTitle = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.catalogRefresh.error.retryButton.title",
            value: "Retry",
            comment: "Button text for retrying a refresh after it fails"
        )

        static let errorCancelButtonTitle = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.catalogRefresh.error.cancelButton.title",
            value: "Cancel",
            comment: "Button text for closing an error after a refresh fails"
        )
    }

    enum Constants {
        static let errorModalMaxWidth: CGFloat = 832
    }
}

#if DEBUG
#Preview {
    let viewModel = POSSettingsLocalCatalogViewModel(
        siteID: 123,
        catalogSettingsService: POSPreviewCatalogSettingsService(),
        catalogSyncCoordinator: POSPreviewCatalogSyncCoordinator()
    )
    POSSettingsLocalCatalogDetailView(viewModel: viewModel)
}
#endif
