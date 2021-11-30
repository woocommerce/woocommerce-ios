import SwiftUI

/// This view will be embedded inside the `HubMenuViewController`
/// and will be the entry point of the `Menu` Tab.
///
struct HubMenu: View {
    @ObservedObject private var viewModel =  HubMenuViewModel()

    var body: some View {
        Text("Work in progress")
    }
}

struct HubMenu_Previews: PreviewProvider {
    static var previews: some View {
        HubMenu()
    }
}
