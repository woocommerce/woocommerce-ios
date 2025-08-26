import SwiftUI

struct PointOfSaleSettingsHelpDetailView: View {
    @State private var showProductRestrictions = false
    @State private var showDocumentation = false
    @State private var showSupport = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Help Settings")
                    .font(.posBodyMediumRegular())
                List {
                    Button {
                        showProductRestrictions = true
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "magnifyingglass")
                                .font(.posBodyLargeRegular())
                            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                                Text("Where are my products?")
                                    .font(.posBodyLargeRegular())
                                Text("Where are my products subtitle")
                                    .font(.posBodyMediumRegular())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    Button {
                        showDocumentation = true
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "doc.text")
                                .font(.posBodyLargeRegular())
                            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                                Text("Documentation")
                                    .font(.posBodyLargeRegular())
                                Text("Documentation subtitle")
                                    .font(.posBodyMediumRegular())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        showSupport = true
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "questionmark")
                                .font(.posBodyLargeRegular())
                            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                                Text("Get Support")
                                    .font(.posBodyLargeRegular())
                                Text("Support subtitle")
                                    .font(.posBodyMediumRegular())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .posModal(isPresented: $showProductRestrictions) {
            // TODO: Remove copy on POSFloatingControlView.documentationView
            // WOOMOB-1168
            SimpleProductsOnlyInformation(isPresented: $showProductRestrictions)
        }
        .posSheet(isPresented: $showDocumentation) {
            // TODO: Remove copy on PointOfSaleDashboardView.documentationView
            // WOOMOB-1168
            SafariView(url: WooConstants.URLs.pointOfSaleDocumentation.asURL())

        }
        .posSheet(isPresented: $showSupport) {
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
        static let supportCancel = NSLocalizedString(
            "PointOfSaleSettingsHelpDetailView.support.cancel",
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
