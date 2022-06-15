import SwiftUI

struct UnconfiguredView: View {

    var body: some View {
        Text(unconfiguredMessage)
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))
            .multilineTextAlignment(.center)
            .padding()
    }

    var unconfiguredMessage: String {
        "Log in to WooCommerce to see today's stats."
    }
}

struct PlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        UnconfiguredView()
    }
}
