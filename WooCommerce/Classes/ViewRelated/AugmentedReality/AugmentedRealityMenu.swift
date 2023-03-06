import SwiftUI

struct AugmentedRealityMenu: View {
    var body: some View {
        List {
            Text("Capture images")
            if #available(macCatalyst 16.0, *) {
                NavigationLink(destination: AugmentedRealityCreateUSDZ()) {
                    Text("Create USDZ files")
                }
            }
        }
    }
}

struct Previews_AugmentedRealityMenu_Previews: PreviewProvider {
    static var previews: some View {
        AugmentedRealityMenu()
    }
}
