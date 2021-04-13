import SwiftUI

struct ShippingLabelServicePackagesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ListHeaderView(text: "Set up the package you'll be using to ship your products. We'll save it for future orders.", alignment: .left)
                    .background(Color(.listBackground))
            }
        }
    }
}

struct ShippingLabelServicePackagesView_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelServicePackagesView()
    }
}
