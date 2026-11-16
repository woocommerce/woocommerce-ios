import SwiftUI

struct POSSettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: SidebarNavigation?
    @State private var overrideHandler = POSManagerOverrideHandler()

    let settingsController: POSSettingsControllerProtocol

    var body: some View {
        POSNavigationSplitView(selection: $selection) { selection in
            POSSettingsListView(selection: selection, settingsController: settingsController)
        } detail: { selection, navigationPath in
            detailView(for: selection, navigationPath: navigationPath)
                .environment(\.posHeaderBackButtonConfiguration,
                             horizontalSizeClass == .compact ?
                                .init(state: .enabled, action: { self.selection = nil }) : nil)
        } detailPlaceholderView: {
            POSSettingsStoreDetailView(viewModel: settingsController.storeViewModel,
                                       requestEditPermission: requestEditPermission)
        } setDefaultValue: {
            if selection == nil {
                selection = .store
            }
        }
        // No `.posRootModal()` here — `.posFullScreenCover` already provides one for this content, and a
        // second bound to the same `POSModalManager` would render the override modal twice.
        .posManagerOverrideModal(handler: overrideHandler)
        .onChange(of: settingsController.securityController?.isVisible) { _, isVisible in
            if isVisible != true && selection == .security { selection = .store }
        }
    }

    /// Gates an edit to POS settings on `.manageStoreSettings`. When the operator holds it the edit runs
    /// immediately; otherwise the manager-override modal is presented and the edit runs once an
    /// authorized staff member approves.
    func requestEditPermission(_ perform: @escaping () -> Void) {
        overrideHandler.gate(.manageStoreSettings, reason: Localization.editOverrideDescription, perform: { _ in perform() })
    }
}

extension POSSettingsView {
    private struct POSSettingsListView: View {
        @Environment(\.posMetrics) private var metrics
        @Environment(\.dismiss) private var dismiss
        @Environment(\.posAnalytics) private var analytics
        @Binding var selection: SidebarNavigation?

        let settingsController: POSSettingsControllerProtocol

        var body: some View {
            VStack(alignment: .leading, spacing: metrics.spacing.none) {
                POSPageHeaderView(
                    title: Localization.navigationTitle,
                    backButtonConfiguration: .init(state: .enabled,
                                                   action: {
                                                       analytics.track(.pointOfSaleSettingsCloseButtonTapped)
                                                       dismiss()
                                                   },
                                                   accessibilityIdentifier: "pos-settings-close-button"))
                .posHeaderBackButtonIcon(systemName: "xmark")
                .foregroundColor(.posSurface)

                VStack(spacing: metrics.spacing.small) {
                    categoryCard(.store)
                    categoryCard(.hardware)
                    categoryCard(.payments)
                    if settingsController.securityController?.isVisible == true {
                        categoryCard(.security)
                    }
                    if settingsController.isLocalCatalogEligible {
                        categoryCard(.localCatalog)
                    }
                    Spacer()

                    helpView
                }
                .padding(.horizontal, metrics.padding.medium)
            }
            .background(Color.posSurfaceBright.ignoresSafeArea())
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("pos-settings-view")
        }

        private func categoryCard(_ category: SidebarNavigation) -> some View {
            POSSettingsCard(title: category.title,
                            subtitle: category.subtitle,
                            isSelected: selection == category,
                            action: {
                category.trackSelection(with: analytics)
                selection = category
            })
        }

        @ViewBuilder
        private var helpView: some View {
            Button {
                SidebarNavigation.help.trackSelection(with: analytics)
                selection = .help
            } label: {
                HStack(spacing: metrics.spacing.small) {
                    if let icon = SidebarNavigation.help.icon {
                        Image(systemName: icon)
                            .font(.posBodyMediumBold)
                            .foregroundStyle(Color.posOnSurface)
                    }
                    Text(SidebarNavigation.help.title)
                        .font(.posBodyMediumBold)
                        .foregroundStyle(Color.posOnSurface)
                }
                .posPadding(\.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(SidebarNavigation.help.title)
        }
    }

    @ViewBuilder
    private func detailView(for selection: SidebarNavigation, navigationPath: Binding<NavigationPath>) -> some View {
        switch selection {
        case .store:
            POSSettingsStoreDetailView(viewModel: settingsController.storeViewModel,
                                       requestEditPermission: requestEditPermission)
        case .hardware:
            POSSettingsHardwareDetailView(settingsController: settingsController, navigationPath: navigationPath)
        case .payments:
            POSSettingsPaymentsDetailView(viewModel: settingsController.paymentsViewModel,
                                          requestEditPermission: requestEditPermission)
        case .localCatalog:
            if let viewModel = settingsController.localCatalogViewModel {
                POSSettingsLocalCatalogDetailView(viewModel: viewModel,
                                                  requestEditPermission: requestEditPermission)
            } else {
                EmptyView()
            }
        case .security:
            if let controller = settingsController.securityController, controller.isVisible {
                POSSecuritySettingsView(controller: controller)
            }
        case .help:
            POSSettingsHelpDetailView()
        }
    }
}

extension POSSettingsView {
    enum SidebarNavigation: String, CaseIterable, Identifiable {
        case store
        case hardware
        case payments
        case localCatalog
        case help
        case security

        var id: Self { self }

        var title: String {
            switch self {
            case .store: return Localization.sidebarNavigationStoreTitle
            case .hardware: return Localization.sidebarNavigationHardwareTitle
            case .payments: return Localization.sidebarNavigationPaymentsTitle
            case .localCatalog: return Localization.sidebarNavigationLocalCatalogTitle
            case .security: return POSSecuritySettingsView.Localization.title
            case .help: return Localization.sidebarNavigationHelpTitle
            }
        }

        var subtitle: String {
            switch self {
            case .store: return Localization.sidebarNavigationStoreSubtitle
            case .hardware: return Localization.sidebarNavigationHardwareSubtitle
            case .payments: return Localization.sidebarNavigationPaymentsSubtitle
            case .localCatalog: return Localization.sidebarNavigationLocalCatalogSubtitle
            case .security: return POSSecuritySettingsView.Localization.subtitle
            case .help: return Localization.sidebarNavigationHelpSubtitle
            }
        }

        var icon: String? {
            switch self {
            case .store, .hardware, .payments, .localCatalog, .security:
                return nil
            case .help:
                return "questionmark.circle"
            }
        }

        func trackSelection(with analytics: POSAnalyticsProviding) {
            switch self {
            case .store: analytics.track(.pointOfSaleSettingsStoreDetailsTapped)
            case .hardware: analytics.track(.pointOfSaleSettingsHardwareTapped)
            case .payments: analytics.track(.pointOfSaleSettingsPaymentsTapped)
            case .help: analytics.track(.pointOfSaleSettingsHelpTapped)
            case .localCatalog, .security: break
            }
        }
    }

    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "pointOfSaleSettingsView.navigationTitle",
            value: "Settings",
            comment: "Title of the Point of Sale settings view."
        )

        static let editOverrideDescription = NSLocalizedString(
            "pointOfSaleSettingsView.editOverrideReason",
            value: "Changing settings requires approval",
            comment: "Message shown in the manager-override PIN prompt when a staff member without the "
                + "edit-settings permission tries to change a Point of Sale setting."
        )

        static let sidebarNavigationStoreTitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationStoreTitle",
            value: "Store",
            comment: "Title of the Store section within Point of Sale settings."
        )

        static let sidebarNavigationHardwareTitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationHardwareTitle",
            value: "Hardware",
            comment: "Title of the Hardware section within Point of Sale settings."
        )

        static let sidebarNavigationHelpTitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationHelpTitle.1",
            value: "Get help and support",
            comment: "Title of the Help section within Point of Sale settings."
        )

        static let sidebarNavigationStoreSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationStoreSubtitle",
            value: "Store configuration and settings",
            comment: "Description of the settings to be found within the Store section."
        )

        static let sidebarNavigationHardwareSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationHardwareSubtitle",
            value: "Manage hardware connections",
            comment: "Description of the settings to be found within the Hardware section."
        )

        static let sidebarNavigationPaymentsTitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationPaymentsTitle",
            value: "Payments",
            comment: "Title of the Payments section within Point of Sale settings."
        )

        static let sidebarNavigationPaymentsSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationPaymentsSubtitle",
            value: "Manage payment settings",
            comment: "Description of the settings to be found within the Payments section."
        )

        static let sidebarNavigationLocalCatalogTitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationLocalCatalogTitle.2",
            value: "Product catalog",
            comment: "Title of the Local catalog section within Point of Sale settings."
        )

        static let sidebarNavigationLocalCatalogSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationLocalCatalogSubtitle",
            value: "Manage catalog settings",
            comment: "Description of the settings to be found within the Local catalog section."
        )

        static let sidebarNavigationHelpSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationHelpSubtitle",
            value: "Get help and support",
            comment: "Description of the Help section in Point of Sale settings."
        )
    }
}

#if DEBUG
#Preview {
    // Production supplies these via `.posFullScreenCover`; the standalone preview provides its own root
    // modal and managers so the override modal has somewhere to render.
    POSSettingsView(settingsController: POSSettingsPreviewController())
        .posRootModal()
        .environmentObject(POSModalManager())
        .environmentObject(POSFullScreenCoverManager())
}
#endif
