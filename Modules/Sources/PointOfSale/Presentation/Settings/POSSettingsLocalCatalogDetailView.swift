import SwiftUI

struct POSSettingsLocalCatalogDetailView: View {
    // TODO: WOOMOB-1335 - implement full sync cellular data setting functionality
    @State private var allowFullSyncOnCellular: Bool = true
    private let viewModel: POSSettingsLocalCatalogViewModel

    init(viewModel: POSSettingsLocalCatalogViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: POSSpacing.none) {
                POSPageHeaderView(title: Localization.localCatalogTitle)
                    .foregroundColor(.posSurface)
                    .accessibilityAddTraits(.isHeader)

                ScrollView {
                    VStack(spacing: POSSpacing.medium) {
                        catalogStatus
                        managingDataUsage
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
    }
}

private extension POSSettingsLocalCatalogDetailView {
    @ViewBuilder
    var catalogStatus: some View {
        VStack(spacing: POSSpacing.none) {
            sectionHeaderView(title: Localization.catalogStatus)

            VStack(spacing: POSSpacing.medium) {
                fieldRowView(label: Localization.catalogSize, value: viewModel.catalogSize)
                fieldRowView(label: Localization.lastIncrementalUpdate, value: viewModel.lastIncrementalSyncDate)
                fieldRowView(label: Localization.lastFullSync, value: viewModel.lastFullSyncDate)
            }
            .padding(.bottom, POSPadding.medium)
            .redacted(reason: viewModel.isLoading ? .placeholder : [])
            .shimmering(active: viewModel.isLoading)
        }
    }

    @ViewBuilder
    var managingDataUsage: some View {
        VStack(spacing: POSSpacing.none) {
            sectionHeaderView(title: Localization.managingDataUsage)

            VStack(spacing: POSSpacing.medium) {
                toggleRowView(label: Localization.allowFullSyncOnCellular, isOn: $allowFullSyncOnCellular)
            }
            .padding(.bottom, POSPadding.medium)
        }
    }

    @ViewBuilder
    var manualCatalogUpdate: some View {
        VStack(spacing: POSSpacing.none) {
            sectionHeaderView(title: Localization.manualCatalogUpdate)

            VStack(spacing: POSSpacing.medium) {
                Text(Localization.manualUpdateInfo)
                    .font(.posCaptionRegular)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: {
                    Task {
                        await viewModel.refreshCatalog()
                    }
                }) {
                    Text(Localization.refreshCatalog)
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: viewModel.isRefreshingCatalog))
            }
            .padding(.horizontal, POSPadding.medium)
            .padding(.bottom, POSPadding.medium)
        }
    }

    @ViewBuilder
    func sectionHeaderView(title: String) -> some View {
        ZStack {
            Style.backgroundColor
            Text(title)
                .font(.posBodyLargeBold)
                .foregroundColor(.posOnSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, POSPadding.medium)
                .padding(.vertical, POSPadding.small)
        }
    }

    @ViewBuilder
    func fieldRowView(label: String, value: String) -> some View {
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
    func toggleRowView(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.posBodyMediumRegular())
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, POSPadding.medium)
    }
}

private extension POSSettingsLocalCatalogDetailView {
    enum Style {
        static let backgroundColor = Color.posSurface
    }

    enum Localization {
        static let localCatalogTitle = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.title",
            value: "Catalog Settings",
            comment: "Navigation title for the local catalog details in POS settings."
        )

        static let catalogStatus = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.catalogStatus",
            value: "Catalog Status",
            comment: "Section title for catalog status in Point of Sale settings."
        )

        static let managingDataUsage = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.managingDataUsage.1",
            value: "Managing Data Usage",
            comment: "Section title for managing data usage in Point of Sale settings."
        )

        static let lastIncrementalUpdate = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.lastIncrementalSync",
            value: "Last update",
            comment: "Label for last incremental update field in Point of Sale settings."
        )

        static let lastFullSync = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.lastFullSync.1",
            value: "Last full update",
            comment: "Label for last full sync field in Point of Sale settings."
        )

        static let catalogSize = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.catalogSize",
            value: "Catalog size",
            comment: "Label for catalog size field in Point of Sale settings."
        )


        static let allowFullSyncOnCellular = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.allowFullSyncOnCellular.1",
            value: "Allow full update on cellular data",
            comment: "Label for allow full sync on cellular data toggle in Point of Sale settings."
        )


        static let manualCatalogUpdate = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.manualCatalogUpdate",
            value: "Manual Catalog Update",
            comment: "Section title for manual catalog update in Point of Sale settings."
        )

        static let manualUpdateInfo = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.manualUpdateInfo",
            value: "Use this refresh only when something seems off - POS keeps data current automatically.",
            comment: "Info text explaining when to use manual catalog update."
        )

        static let refreshCatalog = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.refreshCatalog",
            value: "Refresh catalog",
            comment: "Button text for refreshing the catalog manually."
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
