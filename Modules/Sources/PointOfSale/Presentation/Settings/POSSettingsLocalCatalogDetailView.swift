import SwiftUI
import enum Yosemite.POSCatalogSyncProgress

struct POSSettingsLocalCatalogDetailView: View {
    @Environment(\.posMetrics) private var metrics
    private let viewModel: POSSettingsLocalCatalogViewModel
    /// Gates an edit action on `editPOSSettings`. Defaults to running it directly (previews / no host gate).
    private let requestEditPermission: POSPermissionRequest

    init(viewModel: POSSettingsLocalCatalogViewModel,
         requestEditPermission: @escaping POSPermissionRequest = { $0() }) {
        self.viewModel = viewModel
        self.requestEditPermission = requestEditPermission
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: metrics.spacing.none) {
            POSPageHeaderView(title: Localization.localCatalogTitle)
                .foregroundColor(.posSurface)

            ScrollView {
                VStack(spacing: metrics.spacing.medium) {
                    catalogStatus
                    if viewModel.deviceHasCellularCapability {
                        managingDataUsage
                    }
                    manualCatalogUpdate
                }
                .posContentPadding(.horizontal, metrics.padding.medium)
            }
        }
        .background(Style.backgroundColor)
        .task {
            await viewModel.loadCatalogData()
        }
        .posDialog(item: $viewModel.catalogRefreshError) { error in
            errorDialog(errorState: error.errorState)
        }
    }
}

private extension POSSettingsLocalCatalogDetailView {
    @ViewBuilder
    var catalogStatus: some View {
        POSInformationCard {
            VStack(spacing: metrics.spacing.small) {
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
        VStack(spacing: metrics.spacing.none) {
            POSInformationCard {
                POSInformationCardFieldRowWithToggle(
                    label: Localization.managingDataUsage,
                    value: Localization.allowSyncOnCellular,
                    showSeparator: false,
                    isOn: cellularSyncBinding
                )
            }
        }
    }

    /// Toggling the cellular-sync setting is an edit, so route changes through `editPOSSettings`:
    /// the value only flips once the operator holds the cap or a manager approves the override.
    private var cellularSyncBinding: Binding<Bool> {
        Binding(
            get: { viewModel.allowFullSyncOnCellular },
            set: { newValue in
                requestEditPermission { viewModel.allowFullSyncOnCellular = newValue }
            }
        )
    }

    @ViewBuilder
    var manualCatalogUpdate: some View {
        VStack(spacing: metrics.spacing.none) {
            POSInformationCard {
                POSInformationCardFieldRow(
                    label: Localization.manualCatalogUpdate,
                    value: Localization.manualUpdateInfo,
                    showSeparator: false,
                    labelStyle: .bold,
                    buttonTitle: updateCatalogButtonTitle,
                    buttonAction: {
                        requestEditPermission {
                            Task {
                                await viewModel.refreshCatalog()
                            }
                        }
                    },
                    buttonStyle: .primary,
                    isButtonEnabled: !viewModel.isRefreshingCatalog
                )
            }
        }
    }

    var updateCatalogButtonTitle: String {
        guard viewModel.isRefreshingCatalog else {
            return Localization.updateCatalog
        }

        guard let progress = viewModel.catalogRefreshProgress else {
            return Localization.updateCatalogPreparing
        }

        switch progress {
        case .preparing:
            return Localization.updateCatalogPreparing
        case .itemCount(let processed, let total):
            let format = total == 1 ? Localization.updateCatalogProgressSingularFormat : Localization.updateCatalogProgressFormat
            return String.localizedStringWithFormat(format, processed, total)
        }
    }

    func errorDialog(errorState: PointOfSaleErrorState) -> POSDialog {
        POSDialog(icon: .errorXMark,
                  title: errorState.title,
                  message: errorState.subtitle,
                  primaryAction: .init(title: Localization.errorRetryButtonTitle, action: {
                      Task {
                          await viewModel.refreshCatalog()
                      }
                  }),
                  secondaryAction: .init(title: Localization.errorCancelButtonTitle, action: {
                      viewModel.catalogRefreshError = nil
                  }),
                  closeAction: .init(accessibilityLabel: Localization.errorCancelButtonTitle, action: {
                      viewModel.catalogRefreshError = nil
                  }))
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

        static let updateCatalogPreparing = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.updateCatalogPreparing",
            value: "Preparing...",
            comment: "Button text shown while a manual POS catalog update is preparing before item counts are available."
        )

        static let updateCatalogProgressFormat = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.updateCatalogProgressFormat",
            value: "%1$ld of %2$ld items",
            comment: "Button text shown during a manual POS catalog update. %1$ld is the number of catalog items processed, " +
                "%2$ld is the total number of catalog items."
        )

        static let updateCatalogProgressSingularFormat = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.updateCatalogProgressFormat.singular",
            value: "%1$ld of %2$ld item",
            comment: "Button text shown during a manual POS catalog update when there is one item. " +
                "%1$ld is the number of catalog items processed, %2$ld is the total number of catalog items."
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
