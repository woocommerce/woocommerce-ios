import SwiftUI

struct WooShippingCustomsItemOriginCountryInfoDialog: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(Layout.backgroundOpacity).edgesIgnoringSafeArea(.all)

                VStack {
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(alignment: .center, spacing: Layout.verticalSpacing) {
                                Text(Localization.title)
                                    .headlineStyle()
                                Text(Localization.bodyParagraph)
                                    .bodyStyle()
                                    .fixedSize(horizontal: false, vertical: true)
                                Button {
                                    dismiss()
                                } label: {
                                    Text(Localization.doneButtonTitle)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            .padding(Layout.outterPadding)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color(.systemBackground))
                            .cornerRadius(Layout.cornerRadius)
                            .frame(width: geometry.size.width)
                            .frame(minHeight: geometry.size.height)
                        }
                }
            }
            .padding(Layout.outterPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
extension WooShippingCustomsItemOriginCountryInfoDialog {
    enum Localization {
        static let title = NSLocalizedString("shipping.customs.originCountryInfoDialogTitle",
                                             value: "Origin Country",
                                             comment: "Title for the custom origin country educational dialog")
        static let bodyParagraph = NSLocalizedString("shipping.customs.originCountryInfoDialogBody",
                                                     value: "Country where the product was manufactured or assembled.",
                                                     comment: "Body for the custom items origin country educational dialog")
        static let doneButtonTitle = NSLocalizedString("shipping.customs.originCountryInfoDialogDoneButton",
                                                       value: "Done",
                                                       comment: "Button title for the done button in the customs description educational dialog")
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
