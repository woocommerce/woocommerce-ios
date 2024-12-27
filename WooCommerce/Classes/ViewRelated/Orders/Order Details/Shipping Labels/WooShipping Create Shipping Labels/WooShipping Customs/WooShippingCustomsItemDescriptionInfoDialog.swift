import SwiftUI

struct WooShippingCustomsItemDescriptionInfoDialog: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @Environment(\.dismiss) var dismiss

    /// Whether the learn more webview is being shown.
    @State private var showLearnMoreWebView: Bool = false

    /// Learn more URL. I preferred to add it here instead of creating a view model just for this.
    let learnMoreURL = URL(string: "https://pe.usps.com/text/imm/immc5_010.htm")


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
                                    showLearnMoreWebView = true
                                } label: {
                                    Label {
                                        Text(Localization.learnMoreButtonTitle)
                                            .font(.body)
                                            .fontWeight(.bold)
                                    } icon: {
                                        Image(systemName: "arrow.up.forward.square")
                                            .resizable()
                                            .frame(width: Layout.externalLinkImageSize * scale, height: Layout.externalLinkImageSize * scale)
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .safariSheet(isPresented: $showLearnMoreWebView, url: learnMoreURL)

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
extension WooShippingCustomsItemDescriptionInfoDialog {
    enum Localization {
        static let title = NSLocalizedString("Description", comment: "Title for the custom description educational dialog")
        static let bodyParagraph = NSLocalizedString("When shipping to countries that follow European Union (EU) customs rules, " +
                                                     "you must provide a clear, specific description on every item. " +
                                                     "For example, if you are sending clothing, you must indicate what type of clothing" +
                                                     " (e.g. men's shirts, girl's vest, boy's jacket) for the description to be acceptable." +
                                                     " Otherwise, shipments may be delayed or interrupted at customs.",
                                                          comment: "Body for the custom items description educational dialog")
        static let learnMoreButtonTitle = NSLocalizedString("Learn more",
                                                                      comment: "Button title for the learn more action in the custom descriptions info dialog")
        static let doneButtonTitle = NSLocalizedString("Done",
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
