import SwiftUI
import WooFoundation

struct NewTaxRateSelectorView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @Environment(\.dismiss) var dismiss

    @StateObject var viewModel: NewTaxRateSelectorViewModel
    let taxEducationalDialogViewModel: TaxEducationalDialogViewModel
    let onDismissWpAdminWebView: (() -> Void)

    /// Indicates if the tax educational dialog should be shown or not.
    ///
    @State private var shouldShowTaxEducationalDialog: Bool = false

    /// Whether the WPAdmin webview is being shown.
    ///
    @State private var showingWPAdminWebView: Bool = false
    @State var storeSelectedTaxRate: Bool

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    HStack(alignment: .top, spacing: Layout.explanatoryBoxHorizontalSpacing) {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color(.wooCommercePurple(.shade60)))
                        Text(Localization.infoText)
                    }
                    .padding(Layout.generalPadding)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.explanatoryBoxCornerRadius)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .padding(Layout.generalPadding)

                switch viewModel.syncState {
                    case .results:
                    Text(Localization.taxRatesSectionTitle.uppercased())
                        .footnoteStyle()
                        .multilineTextAlignment(.leading)
                        .padding([.leading, .trailing], Layout.generalPadding)
                        .padding([.top, .bottom], Layout.taxRatesSectionTitleVerticalPadding)

                    Divider()

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.taxRateViewModels.enumerated()), id: \.offset) { index, taxRateViewModel in
                                TaxRateRow(viewModel: taxRateViewModel) {
                                    viewModel.onRowSelected(with: index, storeSelectedTaxRate: storeSelectedTaxRate)
                                    dismiss()
                                }

                                Divider()
                            }
                            .background(Color(.listForeground(modal: false)))

                            resultsListFooter
                                .renderedIf(!viewModel.shouldShowBottomActivityIndicator)

                            InfiniteScrollIndicator(showContent: viewModel.shouldShowBottomActivityIndicator)
                                .padding(.top, Layout.generalPadding)
                                .onAppear {
                                    viewModel.onLoadNextPageAction()
                                }
                        }
                    }

                    storeTaxRateBottomView

                    case .empty:
                    EmptyState(title: Localization.emptyStateTitle,
                                   description: Localization.emptyStateDescription,
                                   image: .emptyTaxRatesImage)
                        .padding(Layout.generalPadding)

                        Button {
                            tapOnWPAdminWebViewButton()
                        } label: {
                            HStack {
                                Text(Localization.editTaxRatesInWpAdminButtonTitle)
                                    .font(.body)
                                    .fontWeight(.bold)

                                Image(systemName: "arrow.up.forward.square")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(Layout.generalPadding)
                        Spacer()
                    case .syncingFirstPage:
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.placeholderRowViewModels, id: \.id) { rowViewModel in
                                    TaxRateRow(viewModel: rowViewModel, onSelect: {})
                                        .redacted(reason: .placeholder)
                                }
                            }
                        }
                        .background(Color(.listForeground(modal: false)))
                }
            }
            .onAppear {
                // Even if we are calling this on appear (it might be called multiple times) the view model will only load the first it's called
                viewModel.onLoadTriggerOnce.send()
            }
            .navigationTitle(Localization.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                dismiss()
            }) {
                Text(Localization.cancelButton)
            }, trailing: Button(action: {
                shouldShowTaxEducationalDialog = true
            }) {
                Image(systemName: "questionmark.circle")
            })
            .fullScreenCover(isPresented: $shouldShowTaxEducationalDialog) {
                TaxEducationalDialogView(viewModel: taxEducationalDialogViewModel,
                                         onDismissWpAdminWebView: {})
                    .background(FullScreenCoverClearBackgroundView())
                }
        }
        .wooNavigationBarStyle()
        .safariSheet(isPresented: $showingWPAdminWebView, url: viewModel.wpAdminTaxSettingsURL, onDismiss: {
            viewModel.onRefreshAction()
            onDismissWpAdminWebView()
            showingWPAdminWebView = false
        })
    }

    private var resultsListFooter: some View {
        Group {
            Text(Localization.listFooterResultsSectionTitle)
                .foregroundColor(Color(.textSubtle))
                .footnoteStyle()
                .padding(.top, Layout.editTaxRatesInWpAdminSectionTopPadding)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding([.leading, .trailing], Layout.generalPadding)
            Button(action: {
                tapOnWPAdminWebViewButton()
            }) {
                HStack {
                    Text(Localization.editTaxRatesInWpAdminButtonTitle)
                        .fontWeight(.semibold)
                        .font(.footnote)
                        .foregroundColor(Color(.wooCommercePurple(.shade60)))

                    Image(systemName: "arrow.up.forward.square")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, Layout.editTaxRatesInWpAdminSectionVerticalSpacing)
        }
    }

    private var storeTaxRateBottomView: some View {
        VStack {
            Divider()

            Toggle(isOn: $storeSelectedTaxRate) {
                VStack(alignment: .leading, spacing: Layout.fixedBottomPanelVerticalSpace) {
                    Text(Localization.fixedBottomPanelBody)
                    Text(Localization.fixedBottomPanelFootnote)
                        .footnoteStyle()
                }
            }
            .padding(Layout.generalPadding)
        }
    }
}

private extension NewTaxRateSelectorView {
    func tapOnWPAdminWebViewButton() {
        viewModel.onShowWebView()
        showingWPAdminWebView = true
    }
}

extension NewTaxRateSelectorView {
    enum Layout {
        static let generalPadding: CGFloat = 16
        static let explanatoryBoxHorizontalSpacing: CGFloat = 11
        static let explanatoryBoxCornerRadius: CGFloat = 8
        static let taxRatesSectionTitleVerticalPadding: CGFloat = 8
        static let editTaxRatesInWpAdminSectionTopPadding: CGFloat = 24
        static let editTaxRatesInWpAdminSectionVerticalSpacing: CGFloat = 8
        static let externalLinkImageSize: CGFloat = 18
        static let fixedBottomPanelVerticalSpace: CGFloat = 4
    }
    enum Localization {
        static let navigationTitle = NSLocalizedString("Set Tax Rate", comment: "Navigation title for the tax rate selector")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title for the tax rate selector")
        static let infoText = NSLocalizedString("This will change the customer’s address to the location of the tax rate you select.",
                                                comment: "Explanatory text for the tax rate selector")
        static let taxRatesSectionTitle = NSLocalizedString("Select a tax rate", comment: "Title for the tax rate selector section")
        static let editTaxRatesInWpAdminButtonTitle = NSLocalizedString("Edit tax rates in admin",
                                                                         comment: "Title of the button that prompts the user to edit tax rates in the web")
        static let emptyStateTitle = NSLocalizedString("We couldn’t find any tax rates", comment: "Title for the empty state on the Tax Rates selector screen")
        static let emptyStateDescription = NSLocalizedString("Add tax rates in admin. Only tax rates with location information will be shown here.",
                                                             comment: "Description for the empty state on the Tax Rates selector screen")
        static let listFooterResultsSectionTitle = NSLocalizedString("Can’t find the rate you’re looking for?",
                                                                         comment: "Text to prompt the user to edit tax rates in the web")
        static let fixedBottomPanelBody = NSLocalizedString("Add this rate to all created orders", comment: "Body for the action to store selected tax rate")
        static let fixedBottomPanelFootnote = NSLocalizedString("This will not affect online orders",
                                                                comment: "Footnote for the action to store selected tax rate")
    }
}
