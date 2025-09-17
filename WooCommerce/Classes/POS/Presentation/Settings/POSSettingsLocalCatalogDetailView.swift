import SwiftUI

struct POSSettingsLocalCatalogDetailView: View {
    // TODO: WOOMOB-1335 - implement full sync cellular data setting functionality
    @State private var allowFullSyncOnCellular: Bool = true

    private var backgroundColor: Color {
        Color.posOnSecondaryContainer
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
                }
                .background(backgroundColor)
            }
        }
    }
}

private extension POSSettingsLocalCatalogDetailView {
    @ViewBuilder
    var catalogStatus: some View {
        VStack(spacing: POSSpacing.none) {
            sectionHeaderView(title: Localization.catalogStatus)

            VStack(spacing: POSSpacing.medium) {
                // TODO: WOOMOB-1100 - replace with catalog data
                fieldRowView(label: Localization.catalogSize, value: "1,250 products, 3,420 variations")
                fieldRowView(label: Localization.lastIncrementalUpdate, value: "5 minutes ago")
                fieldRowView(label: Localization.lastFullSync, value: "Today at 2:34 PM")
            }
            .padding(.bottom, POSPadding.medium)
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
                    // Handle refresh catalog action
                }) {
                    Text(Localization.refreshCatalog)
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
            }
            .padding(.horizontal, POSPadding.medium)
            .padding(.bottom, POSPadding.medium)
        }
    }

    @ViewBuilder
    func sectionHeaderView(title: String) -> some View {
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
            "posSettingsLocalCatalogDetailView.managingDataUsage",
            value: "Managing data usage",
            comment: "Section title for managing data usage in Point of Sale settings."
        )

        static let lastIncrementalUpdate = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.lastIncrementalUpdate",
            value: "Last incremental update",
            comment: "Label for last incremental update field in Point of Sale settings."
        )

        static let lastFullSync = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.lastFullSync",
            value: "Last full sync",
            comment: "Label for last full sync field in Point of Sale settings."
        )

        static let catalogSize = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.catalogSize",
            value: "Catalog size",
            comment: "Label for catalog size field in Point of Sale settings."
        )


        static let allowFullSyncOnCellular = NSLocalizedString(
            "posSettingsLocalCatalogDetailView.allowFullSyncOnCellular",
            value: "Allow full sync on cellular data",
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
    POSSettingsLocalCatalogDetailView()
}
#endif
