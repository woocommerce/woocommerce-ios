import SwiftUI

/// This view will be embedded inside the `HubMenuViewController`
/// and will be the entry point of the `Menu` Tab.
///
struct HubMenu: View {
    @ObservedObject private var viewModel =  HubMenuViewModel()


    var body: some View {
        let gridItemLayout = [GridItem(.adaptive(minimum: Constants.itemSize), spacing: Constants.itemSpacing)]

        ScrollView {
            LazyVGrid(columns: gridItemLayout) {
                ForEach(0...viewModel.menuElements.count, id: \.self) { _ in
                    HubMenuElement(image: UIImage(named: "icon-hub-menu")!, text: "Test")
                        .background(Color.white)
                        .cornerRadius(Constants.cornerRadius)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(Constants.padding)
            .background(Color(.listBackground))
        }
        .background(Color(.listBackground))
    }

    enum Constants {
        static let cornerRadius: CGFloat = 10
        static let itemSpacing: CGFloat = 12
        static let itemSize: CGFloat = 250
        static let padding: CGFloat = 16
    }
}

struct HubMenu_Previews: PreviewProvider {
    static var previews: some View {
        HubMenu()
    }
}
