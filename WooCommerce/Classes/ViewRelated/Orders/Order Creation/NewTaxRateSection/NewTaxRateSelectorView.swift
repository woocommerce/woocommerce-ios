import SwiftUI
import WooFoundation

struct NewTaxRateSelectorView: View {
    @Environment(\.dismiss) var dismiss

    let viewModel: NewTaxRateSelectorViewModel
    let taxEducationalDialogViewModel: TaxEducationalDialogViewModel
    let onDismissWpAdminWebView: (() -> Void)

    /// Indicates if the tax educational dialog should be shown or not.
    ///
    @State private var shouldShowTaxEducationalDialog: Bool = false

    /// Whether the WPAdmin webview is being shown.
    ///
    @State private var showingWPAdminWebview: Bool = false

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

                Text(Localization.taxRatesSectionTitle.uppercased())
                    .footnoteStyle()
                    .multilineTextAlignment(.leading)
                    .padding([.leading, .trailing], Layout.generalPadding)
                    .padding(.bottom, Layout.taxRatesSectionTitleBottomPadding)

                Divider()

                ForEach(viewModel.demoTaxRates, id: \.title) { taxRate in
                    HStack {
                        Button(action: { }) {
                            AdaptiveStack(horizontalAlignment: .leading, spacing: Layout.generalPadding) {
                                Text(taxRate.title)
                                    .foregroundColor(Color(.text))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(taxRate.value)
                                    .foregroundColor(Color(.text))
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: nil, alignment: .trailing)

                                Image(systemName: "chevron.right")
                                    .font(.body)
                                    .font(Font.title.weight(.semibold))
                                    .foregroundColor(Color(.textTertiary))
                                    .padding(.leading, Layout.generalPadding)
                            }
                            .padding(Layout.generalPadding)
                        }
                    }

                    Divider()
                }

                Text(Localization.editTaxRatesInWpAdminSectionTitle)
                    .foregroundColor(Color(.textSubtle))
                    .footnoteStyle()
                    .padding(.top, Layout.editTaxRatesInWpAdminSectionTopPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding([.leading, .trailing], Layout.generalPadding)

                Button(action: {
                    showingWPAdminWebview = true
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
                .safariSheet(isPresented: $showingWPAdminWebview, url: viewModel.wpAdminTaxSettingsURL, onDismiss: {
                    onDismissWpAdminWebView()
                    showingWPAdminWebview = false
                })

                Spacer()

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
    }
}

extension NewTaxRateSelectorView {
    enum Layout {
        static let generalPadding: CGFloat = 16
        static let explanatoryBoxHorizontalSpacing: CGFloat = 11
        static let explanatoryBoxCornerRadius: CGFloat = 8
        static let taxRatesSectionTitleBottomPadding: CGFloat = 8
        static let editTaxRatesInWpAdminSectionTopPadding: CGFloat = 24
        static let editTaxRatesInWpAdminSectionVerticalSpacing: CGFloat = 8
    }
    enum Localization {
        static let navigationTitle = NSLocalizedString("Set Tax Rate", comment: "Navigation title for the tax rate selector")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title for the tax rate selector")
        static let infoText = NSLocalizedString("This will change the customer’s address to the location of the tax rate you select.",
                                                comment: "Explanatory text for the tax rate selector")
        static let taxRatesSectionTitle = NSLocalizedString("Select a tax rate", comment: "Title for the tax rate selector section")
        static let editTaxRatesInWpAdminSectionTitle = NSLocalizedString("Can’t find the rate you’re looking for?",
                                                                         comment: "Text to prompt the user to edit tax rates in the web")
        static let editTaxRatesInWpAdminButtonTitle = NSLocalizedString("Edit tax rates in admin",
                                                                         comment: "Title of the button that prompts the user to edit tax rates in the web")
    }
}
