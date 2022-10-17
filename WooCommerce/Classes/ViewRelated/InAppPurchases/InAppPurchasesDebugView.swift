import SwiftUI
import StoreKit

struct InAppPurchasesDebugView: View {
    var body: some View {
        Group {
            Text("No products available")
        }
        .navigationTitle("IAP Debug")
    }
}

struct InAppPurchasesDebugView_Previews: PreviewProvider {
    static var previews: some View {
        InAppPurchasesDebugView()
    }
}
