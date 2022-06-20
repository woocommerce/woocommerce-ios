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
                    Text("Fullfill your orders with WooCommerce Shipping")
                        .largeTitleStyle()
                        .padding(.top, Constants.topMargin)
                        .multilineTextAlignment(.center)
                    Text("Save time and money")
                        .headlineStyle()
                        .padding(.top, Constants.verticalSpacing)
                }
                .padding([.leading, .trailing], Constants.horizontalMargin)

                VStack (spacing: Constants.verticalSpacing) {
                IconListItem(title: "Title",
                             subtitle: "Subtitle",
                             icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!))

                IconListItem(title: "Title",
                             subtitle: "Subtitle",
                             icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!))

                IconListItem(title: "Title",
                             subtitle: "Subtitle",
                             icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!))
                }
            }
            VStack {
                // Add extension
                Button("Add Extension To Store") {

                }
                .buttonStyle(PrimaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)

                // Dismiss view
                Button("Not now") {

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

}
struct WCShipCTAView_Previews: PreviewProvider {
    static var previews: some View {
        WCShipCTAView()
    }
}
