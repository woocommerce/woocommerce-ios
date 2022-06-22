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

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Text(Localization.viewTitle)
                        .largeTitleStyle()
                        .padding(.top, Constants.topMargin)
                        .multilineTextAlignment(.center)
                    Text(Localization.viewSubtitle)
                        .headlineStyle()
                        .padding(.top, Constants.verticalSpacing)
                }
                .padding([.leading, .trailing], Constants.horizontalMargin)

                VStack (spacing: Constants.verticalSpacing) {
                    IconListItem(title: Localization.firstIconTitle,
                                 subtitle: Localization.firstIconSubtitle,
                                 icon: .base64(.iconCircularTime))

                    IconListItem(title: Localization.secondIconTitle,
                                 subtitle: Localization.secondIconSubtitle,
                                 icon: .base64(.iconCircularDocument))

                    IconListItem(title: Localization.thirdIconTitle,
                                 subtitle: Localization.thirdIconSubtitle,
                                 icon: .base64(.iconCircularRateDiscount))
                }
            }
            VStack {
                // Add extension
                Button(Localization.buttonAddExtension) {

                }
                .buttonStyle(PrimaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)

                // Dismiss view
                Button(Localization.buttonDismiss) {

                }
                .buttonStyle(SecondaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding([.leading, .trailing], Constants.horizontalMargin)
        }
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
    }

    enum Localization {
        static let viewTitle = NSLocalizedString("Fullfill your orders with WooCommerce Shipping", comment: "Title of the CTA view for installing WCShip extension")
        static let viewSubtitle = NSLocalizedString("Save time and money", comment: "Title of the CTA view for installing WCShip extension")
        static let firstIconTitle = NSLocalizedString("Buy postage when you need it", comment: "Title of one of the elements in the CTA View for installing WCShip extension")
        static let firstIconSubtitle = NSLocalizedString("No need to wonder where that stampbook went", comment: "Subtitle of one of the elements in the CTA View for installing WCShip extension")
        static let secondIconTitle = NSLocalizedString("Print from your phone", comment: "Title of one of the elements in the CTA View for installing WCShip extension")
        static let secondIconSubtitle = NSLocalizedString("Pick up an order, then just pay, print, package, and post.", comment: "Subtitle of one of the elements in the CTA View for installing WCShip extension")
        static let thirdIconTitle = NSLocalizedString("Discounted rates", comment: "Title of one of the elements in the CTA View for installing WCShip extension")
        static let thirdIconSubtitle = NSLocalizedString("Access discounted shipping rates. Currently available with DHL and USPS, with more to come soon!", comment: "Subtitle of one of the elements in the CTA View for installing WCShip extension")
        static let buttonAddExtension = NSLocalizedString("Add Extension To Store", comment: "Button in the CTA View for installing WCShip extension")
        static let buttonDismiss = NSLocalizedString("Not now", comment: "Button in the CTA View for installing WCShip extension for dismissing the view")
    }
}
struct WCShipCTAView_Previews: PreviewProvider {
    static var previews: some View {
        WCShipCTAView()
    }
}
