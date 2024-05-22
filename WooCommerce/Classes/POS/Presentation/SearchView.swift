import SwiftUI

struct SearchView: View {
    // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12762
    var body: some View {
        TextField("Search", text: .constant("Search"))
            .frame(maxWidth: .infinity, idealHeight: 120)
            .font(.title2)
            .foregroundColor(Color.white)
            .background(Color.secondaryBackground)
            .cornerRadius(10)
            .border(Color.white, width: 2)
    }
}

#if DEBUG
#Preview {
    SearchView()
}
#endif
