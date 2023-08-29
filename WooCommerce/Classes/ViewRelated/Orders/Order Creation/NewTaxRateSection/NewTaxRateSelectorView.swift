import SwiftUI
import WooFoundation

struct NewTaxRateSelectorView: View {
    // Demo values. To be removed once we fetch the tax rates remotely
    private struct DemoTaxRate {
        let title: String
        let value: String
    }

    private let demoTaxRates: [DemoTaxRate] = [DemoTaxRate(title: "Government Sales Tax · US CA 94016 San Francisco", value: "10%"),
                                       DemoTaxRate(title: "GST · US CA", value: "10%"),
                                       DemoTaxRate(title: "GST · AU", value: "10%")]

    @Environment(\.dismiss) var dismiss

    let taxEducationalDialogViewModel: TaxEducationalDialogViewModel

    /// Indicates if the tax educational dialog should be shown or not.
    ///
    @State private var shouldShowTaxEducationalDialog: Bool = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color(.wooCommercePurple(.shade90)))
                        Text(Localization.infoText)
                    }
                    .padding(16)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .padding(16)

                Text("SELECT A TAX RATE")
                    .footnoteStyle()
                    .multilineTextAlignment(.leading)
                    .padding([.leading, .trailing], 16)
                    .padding(.bottom, 8)

                Divider()

                ForEach(demoTaxRates, id: \.title) { taxRate in
                    HStack {
                        Button(action: { debugPrint("tap tap") }) {
                            AdaptiveStack(horizontalAlignment: .leading, spacing: 16) {
                                Text(taxRate.title)
                                    .foregroundColor(Color(.text))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(taxRate.value)
                                    .foregroundColor(Color(.text))
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: nil, alignment: .trailing)

                                Image(systemName: "chevron.right")
                                    .font(Font.title.weight(.semibold))
                                    .foregroundColor(Color(.textTertiary))
                            }
                            .padding(16)
                        }
                    }

                    Divider()
                }

                Text("Can’t find the rate you’re looking for?")
                    .foregroundColor(Color(.textSubtle))
                    .footnoteStyle()
                    .padding(.top, 24)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding([.leading, .trailing], 16)

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
    enum Localization {
        static let navigationTitle = NSLocalizedString("Set Tax Rate", comment: "Navigation title for the tax rate selector")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title for the tax rate selector")
        static let infoText = NSLocalizedString("This will change the customer’s address to the location of the tax rate you select.",
                                                comment: "Explanatory text for the tax rate selector")
    }
}
