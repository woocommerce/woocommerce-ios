import SwiftUI

struct PrintCustomsFormsView: View {
    let invoiceURLs: [String]

    var body: some View {
        VStack(spacing: 24) {
            Text("Customs form")
                .bodyStyle()
            VStack(spacing: 24) {
                Image("woo-shipping-label-printing-instructions")
                Text("A customs form must be printed and included on this international shipment")
                    .bodyStyle()
                    .multilineTextAlignment(.center)
            }
            .frame(width: 235)
        }
    }
}

struct PrintCustomsFormsView_Previews: PreviewProvider {
    static var previews: some View {
        PrintCustomsFormsView(invoiceURLs: ["http://woocommerce.com"])
    }
}
