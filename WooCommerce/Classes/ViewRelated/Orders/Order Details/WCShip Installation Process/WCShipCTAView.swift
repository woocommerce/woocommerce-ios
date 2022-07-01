import SwiftUI

final class WCShipCTAHostingController: UIHostingController<WCShipCTAView> {

    init() {
        super.init(rootView: WCShipCTAView())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}


struct WCShipCTAView: View {
    @ObservedObject private var iO = Inject.observer
    @Environment(\.presentationMode) var presentationMode
    @State private var tappedWhatIsWCShip = false

    var body: some View {
        VStack {
            ScrollView {
                VStack (spacing: 0) {
                    Text(Localization.viewTitle)
                        .titleStyle()
                        .multilineTextAlignment(.center)
                        .padding(.top, Constants.topMargin)

                    Text(Localization.viewSubtitle)
                        .secondaryTitleStyle()
                        .padding(.top, Constants.verticalSpacing)
                }
                .padding(.bottom, Constants.topMargin)
                .padding([.leading, .trailing], Constants.horizontalMargin)

                VStack (spacing: Constants.verticalSpacing) {
                    IconListItem(title: Localization.firstIconTitle,
                                 subtitle: Localization.firstIconSubtitle,
                                 icon: .base64(.circularTimeIcon))

                    IconListItem(title: Localization.secondIconTitle,
                                 subtitle: Localization.secondIconSubtitle,
                                 icon: .base64(.circularDocumentIcon))

                    IconListItem(title: Localization.thirdIconTitle,
                                 subtitle: Localization.thirdIconSubtitle,
                                 icon: .base64(.circularRateDiscountIcon))
                }

                Button(Localization.buttonWhatIsWCShip) {
                    tappedWhatIsWCShip = true
                }
                .buttonStyle(LinkButtonStyle())
                .padding(.bottom, Constants.topMargin)
            }
            VStack {
                // Add extension
                Button(Localization.buttonAddExtension) {

                }
                .buttonStyle(PrimaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)

                // Dismiss view
                Button(Localization.buttonDismiss) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding([.leading, .trailing], Constants.horizontalMargin)
        }
        .sheet(isPresented: $tappedWhatIsWCShip, content: {
            SafariSheetView(url: Constants.whatIsWCShipURL)
        })
        .enableInjection()
    }

}

// MARK: - Constants
//
private extension WCShipCTAView {

    enum Constants {
        static let topMargin: CGFloat = 64
        static let horizontalMargin: CGFloat = 32
        static let verticalSpacing: CGFloat = 16
        static let whatIsWCShipURL: URL = URL(string: "https://woocommerce.com/document/woocommerce-shipping-and-tax/")!
    }

    enum Localization {
        static let viewTitle = NSLocalizedString("Fullfill your orders with WooCommerce Shipping",
                                                 comment: "Title of the CTA view for installing WCShip extension")
        static let viewSubtitle = NSLocalizedString("Save time and money",
                                                    comment: "Title of the CTA view for installing WCShip extension")
        static let firstIconTitle = NSLocalizedString("Buy postage when you need it",
                                                      comment: "Title of one of the elements in the CTA View for installing WCShip extension")
        static let firstIconSubtitle = NSLocalizedString("No need to wonder where that stampbook went",
                                                         comment: "Subtitle of one of the elements in the CTA View for installing WCShip extension")
        static let secondIconTitle = NSLocalizedString("Print from your phone",
                                                       comment: "Title of one of the elements in the CTA View for installing WCShip extension")
        static let secondIconSubtitle = NSLocalizedString("Pick up an order, then just pay, print, package, and post.",
                                                          comment: "Subtitle of one of the elements in the CTA View for installing WCShip extension")
        static let thirdIconTitle = NSLocalizedString("Discounted rates",
                                                      comment: "Title of one of the elements in the CTA View for installing WCShip extension")
        static let thirdIconSubtitle = NSLocalizedString("Access discounted shipping rates. Currently available with DHL and USPS, with more to come soon!",
                                                         comment: "Subtitle of one of the elements in the CTA View for installing WCShip extension")
        static let buttonWhatIsWCShip = NSLocalizedString("What is WooCommerce Shipping?",
                                                          comment: "Button in the CTA View about what is the WCShip extension")
        static let buttonAddExtension = NSLocalizedString("Add Extension To Store",
                                                          comment: "Button in the CTA View for installing WCShip extension")
        static let buttonDismiss = NSLocalizedString("Not now",
                                                     comment: "Button in the CTA View for installing WCShip extension for dismissing the view")
    }
}
struct WCShipCTAView_Previews: PreviewProvider {
    static var previews: some View {
        WCShipCTAView()
    }
}
