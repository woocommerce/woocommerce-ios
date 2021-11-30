import SwiftUI

/// This view will be embedded inside the `HubMenuViewController`
/// and will be the entry point of the `Menu` Tab.
///
struct HubMenu: View {
    @ObservedObject private var viewModel =  HubMenuViewModel()


    var body: some View {
        let gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 0), count: viewModel.menuElements.count)

        ScrollView {
            LazyVGrid(columns: gridItemLayout) {
                ForEach(0...viewModel.menuElements.count, id: \.self) { _ in
                    Color.orange.frame(width: 100, height: 100)
                }
            }
        }
    }
}

struct HubMenu_Previews: PreviewProvider {
    static var previews: some View {
        HubMenu()
    }
}
