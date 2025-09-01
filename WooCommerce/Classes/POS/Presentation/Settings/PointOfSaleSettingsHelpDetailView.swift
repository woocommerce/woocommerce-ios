import SwiftUI

struct PointOfSaleSettingsHelpDetailView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var showProductRestrictions = false
    @State private var showDocumentation = false
    @State private var showSupport = false

    private var backgroundColor: Color {
        Color.posOnSecondaryContainer
    }

    var body: some View {
        NavigationStack {
            POSPageHeaderView(title: Localization.helpTitle)
            .foregroundColor(.posSurface)
            .accessibilityAddTraits(.isHeader)
            List {
                Button {
                    showProductRestrictions = true
                } label: {
                    DynamicHStack(horizontalAlignment: .leading, spacing: POSSpacing.medium) {
                        Image(systemName: "magnifyingglass")
                            .font(.posBodyLargeRegular())
                            .accessibilityHidden(true)
                            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
                        VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                            Text(Localization.productRestrictionsInfo)
                                .font(.posBodyLargeRegular())
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                            Text(Localization.productRestrictionsInfoSubtitle)
                                .font(.posBodyMediumRegular())
                                .foregroundStyle(.secondary)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        }
                        Spacer()
                    }
                }
                .accessibilityAddTraits(.isButton)
                .listRowSeparator(.hidden)
                .buttonStyle(.plain)

                Button {
                    showDocumentation = true
                } label: {
                    DynamicHStack(horizontalAlignment: .leading, spacing: POSSpacing.medium) {
                        Image(systemName: "doc.text")
                            .font(.posBodyLargeRegular())
                            .accessibilityHidden(true)
                            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
                        VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                            Text(Localization.documentationTitle)
                                .font(.posBodyLargeRegular())
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                            Text(Localization.documentationSubtitle)
                                .font(.posBodyMediumRegular())
                                .foregroundStyle(.secondary)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        }
                        Spacer()
                    }
                }
                .accessibilityAddTraits(.isButton)
                .listRowSeparator(.hidden)
                .buttonStyle(.plain)

                Button {
                    showSupport = true
                } label: {
                    DynamicHStack(horizontalAlignment: .leading, spacing: POSSpacing.medium) {
                        Image(systemName: "questionmark")
                            .font(.posBodyLargeRegular())
                            .accessibilityHidden(true)
                            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
                        VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                            Text(Localization.getSupportTitle)
                                .font(.posBodyLargeRegular())
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                            Text(Localization.getSupportSubtitle)
                                .font(.posBodyMediumRegular())
                                .foregroundStyle(.secondary)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        }
                        Spacer()
                    }
                }
                .accessibilityAddTraits(.isButton)
                .listRowSeparator(.hidden)
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(backgroundColor)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .posModal(isPresented: $showProductRestrictions) {
            // TODO: Remove copy on POSFloatingControlView.documentationView
            // WOOMOB-1168
            SimpleProductsOnlyInformation(isPresented: $showProductRestrictions)
        }
        .posFullScreenCover(isPresented: $showDocumentation) {
            // TODO: Remove copy on PointOfSaleDashboardView.documentationView
            // WOOMOB-1168
            SafariView(url: WooConstants.URLs.pointOfSaleDocumentation.asURL())

        }
        .posFullScreenCover(isPresented: $showSupport) {
            // TODO: Remove copy on PointOfSaleDashboardView.supportForm
            // WOOMOB-1168
            supportForm
                .interactiveDismissDisabled(true)
        }
    }
}

private extension PointOfSaleSettingsHelpDetailView {
    enum Constants {
        static let supportTag = "origin:point-of-sale"
    }

    enum Localization {
        static let helpTitle = NSLocalizedString(
            "PointOfSaleSettingsHelpDetailView.help.title",
            value: "Help",
            comment: "Navigation title for the help settings list."
        )

        static let productRestrictionsInfo = NSLocalizedString(
            "PointOfSaleSettingsHelpDetailView.help.productRestrictionsInfo.button.title",
            value: "Where are my products?",
            comment: "The title of the menu button to view product restrictions info, shown in settings. " +
            "We only show simple and variable products in POS, this shows a modal to help explain that limitation."
        )

        static let productRestrictionsInfoSubtitle = NSLocalizedString(
            "PointOfSaleSettingsHelpDetailView.help.productRestrictionsInfo.button.subtitle",
            value: "Learn about which products are supported in POS",
            comment: "The subtitle of the menu button to view product restrictions info, shown in settings. " +
            "We only show simple and variable products in POS, this shows a modal to help explain that limitation."
        )

        static let documentationTitle = NSLocalizedString(
            "PointOfSaleSettingsHelpDetailView.help.documentation.button.subtitle",
            value: "Documentation",
            comment: "The title of the menu button to view documentation, shown in settings."
        )

        static let documentationSubtitle = NSLocalizedString(
            "PointOfSaleSettingsHelpDetailView.help.documentation.button.subtitle",
            value: "View guides and tutorials",
            comment: "The subtitle of the menu button to view documentation, shown in settings."
        )

        static let getSupportTitle = NSLocalizedString(
            "PointOfSaleSettingsHelpDetailView.help.getSupport.button.subtitle",
            value: "Get Support",
            comment: "The title of the menu button to contact support, shown in settings."
        )

        static let getSupportSubtitle = NSLocalizedString(
            "PointOfSaleSettingsHelpDetailView.help.getSupport.button.subtitle",
            value: "Contact our support team",
            comment: "The subtitle of the menu button to contact support, shown in settings."
        )

        static let supportCancel = NSLocalizedString(
            "PointOfSaleSettingsHelpDetailView.help.support.cancel",
            value: "Cancel",
            comment: "Button to dismiss the support form from the POS settings."
        )
    }

    var supportForm: some View {
        NavigationView {
            SupportForm(isPresented: $showSupport,
                        viewModel: SupportFormViewModel(sourceTag: Constants.supportTag,
                                                        defaultSite: ServiceLocator.stores.sessionManager.defaultSite))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.supportCancel) {
                        showSupport = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

#if DEBUG
#Preview {
    PointOfSaleSettingsHelpDetailView()
}
#endif
