import SwiftUI

struct UnconfiguredView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))
            .multilineTextAlignment(.center)
            .padding()
    }
}

struct PlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        UnconfiguredView(message: "Not configured view")
    }
}
