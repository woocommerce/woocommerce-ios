import SwiftUI

struct TaxEducationalDialogView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @Environment(\.dismiss) var dismiss

    /// Whether the WPAdmin webview is being shown.
    @State private var showingWPAdminWebview: Bool = false

    let viewModel: TaxEducationalDialogViewModel
    let onDismissWpAdminWebView: (() -> Void)

    var body: some View {
        ZStack {
            Color.black.opacity(Layout.backgroundOpacity).edgesIgnoringSafeArea(.all)

                VStack {
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(alignment: .center, spacing: Layout.verticalSpacing) {
                                Text(Localization.title)
                                    .headlineStyle()
                                Text(Localization.bodyFirstParagraph)
                                    .bodyStyle()
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(Localization.bodySecondParagraph)
                                    .bodyStyle()


                                VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                                    Divider()
                                        .frame(height: Layout.dividerHeight)
                                        .foregroundColor(Color(.opaqueSeparator))
                                    if let taxBasedOnSettingExplanatoryText = viewModel.taxBasedOnSettingExplanatoryText {
                                        Text(taxBasedOnSettingExplanatoryText)
                                            .bodyStyle()
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    ForEach(viewModel.taxLines, id: \.title) { taxLine in
                                        HStack {
                                            AdaptiveStack(horizontalAlignment: .leading, spacing: Layout.taxLinesInnerSpacing) {
                                                Text(taxLine.title)
                                                    .font(.body)
                                                    .fontWeight(.semibold)
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .leading)

                                                Text(taxLine.value)
                                                    .font(.body)
                                                    .fontWeight(.semibold)
                                                    .multilineTextAlignment(.trailing)
                                                    .frame(width: nil, alignment: .trailing)
                                            }
                                        }
                                    }
                                    Divider()
                                        .frame(height: Layout.dividerHeight)
                                        .foregroundColor(Color(.opaqueSeparator))
                                }.renderedIf(viewModel.taxLines.isNotEmpty)

                                Button {
                                    viewModel.onGoToWpAdminButtonTapped()
                                    showingWPAdminWebview = true
                                } label: {
                                    Label {
                                        Text(Localization.editTaxRatesInAdminButtonTitle)
                                            .font(.body)
                                            .fontWeight(.bold)
                                    } icon: {
                                        Image(systemName: "arrow.up.forward.square")
                                            .resizable()
                                            .frame(width: Layout.externalLinkImageSize * scale, height: Layout.externalLinkImageSize * scale)
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .safariSheet(isPresented: $showingWPAdminWebview, url: viewModel.wpAdminTaxSettingsURL, onDismiss: {
                                    onDismissWpAdminWebView()
                                    showingWPAdminWebview = false
                                })

                                Button {
                                    dismiss()
                                } label: {
                                    Text(Localization.doneButtonTitle)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                            .padding(Layout.outterPadding)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color(.systemBackground))
                            .cornerRadius(Layout.cornerRadius)
                            .frame(width: geometry.size.width)      // Make the scroll view full-width
                            .frame(minHeight: geometry.size.height)
                        }
                }
            }
            .padding(Layout.outterPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
extension TaxEducationalDialogView {
    enum Localization {
        static let title = NSLocalizedString("Taxes & Tax Rates", comment: "Title for the tax educational dialog")
        static let bodyFirstParagraph = NSLocalizedString("Taxes are calculated by matching your customer’s billing " +
                                                          "or shipping address, or your shop address to a tax rate location.",
                                                          comment: "First paragraph of the body for the tax educational dialog")
        static let bodySecondParagraph = NSLocalizedString("Tax rates for different locations can be managed in your store’s admin.",
                                                          comment: "Second paragraph of the body for the tax educational dialog")
        static let taxRatesExplanatoryText = NSLocalizedString("Your tax rate is currently calculated based on your shop address:",
                                                          comment: "Explanatory text for the tax rates in the tax educational dialog")
        static let editTaxRatesInAdminButtonTitle = NSLocalizedString("Edit Tax Rates in Admin",
                                                                      comment: "Button title for the edit tax rates button in the tax educational dialog")
        static let doneButtonTitle = NSLocalizedString("Done",
                                                       comment: "Button title for the done button in the tax educational dialog")
    }
    enum Layout {
        static let backgroundOpacity: CGFloat = 0.5
        static let externalLinkImageSize: CGFloat = 18
        static let verticalSpacing: CGFloat = 16
        static let outterPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 8
        static let dividerHeight: CGFloat = 1
        static let taxLinesInnerSpacing: CGFloat = 4
    }
}
