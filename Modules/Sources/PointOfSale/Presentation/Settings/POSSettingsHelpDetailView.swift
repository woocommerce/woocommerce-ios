import SwiftUI
import struct WooFoundation.SafariView

struct POSSettingsHelpDetailView: View {
    @Environment(\.posExternalViews) private var externalViews

    @State private var showProductRestrictions = false
    @State private var showDocumentation = false
    @State private var showSupport = false

    private var backgroundColor: Color {
        Color.posSurface
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.helpTitle)
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: POSSpacing.small) {
                    POSSettingsCard(
                        title: Localization.productRestrictionsInfo,
                        subtitle: Localization.productRestrictionsInfoSubtitle,
                        action: {
                            showProductRestrictions = true
                        }
                    )

                    POSSettingsCard(
                        title: Localization.documentationTitle,
                        subtitle: Localization.documentationSubtitle,
                        action: {
                            showDocumentation = true
                        }
                    )

                    POSSettingsCard(
                        title: Localization.getSupportTitle,
                        subtitle: Localization.getSupportSubtitle,
                        action: {
                            showSupport = true
                        }
                    )
                }
                .padding(.horizontal, POSPadding.medium)
            }
        }
        .background(backgroundColor)
        .posModal(isPresented: $showProductRestrictions) {
            // TODO: Remove copy on POSFloatingControlView.documentationView
            // WOOMOB-1168
            SimpleProductsOnlyInformation(isPresented: $showProductRestrictions)
        }
        .posFullScreenCover(isPresented: $showDocumentation) {
            // TODO: Remove copy on PointOfSaleDashboardView.documentationView
            // WOOMOB-1168
            SafariView(url: POSConstants.URLs.pointOfSaleDocumentation.asURL())

        }
        .posFullScreenCover(isPresented: $showSupport) {
            // TODO: Remove copy on PointOfSaleDashboardView.supportForm
            // WOOMOB-1168
            supportForm
                .interactiveDismissDisabled(true)
        }
    }
}

private extension POSSettingsHelpDetailView {
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
            externalViews.createSupportFormView(isPresented: $showSupport, sourceTag: Constants.supportTag)
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
    POSSettingsHelpDetailView()
}
#endif
