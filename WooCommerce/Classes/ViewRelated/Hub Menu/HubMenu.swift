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
                ForEach(viewModel.menuElements, id: \.self) { menu in
                    HubMenuElement(image: menu.icon, text: menu.title)
                }
                .frame(width: Constants.itemSize, height: Constants.itemSize)
                .background(Color.white)
                .cornerRadius(Constants.cornerRadius)
                .padding([.bottom], Constants.padding)
                .onTapGesture {
                    // TODO-5509: implement tap
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
        static let itemSize: CGFloat = 160
        static let padding: CGFloat = 16
    }
}

struct HubMenu_Previews: PreviewProvider {
    static var previews: some View {
        HubMenu()
            .environment(\.colorScheme, .light)

        HubMenu()
            .environment(\.colorScheme, .dark)

        HubMenu()
            .previewLayout(.fixed(width: 312, height: 528))
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

        HubMenu()
            .previewLayout(.fixed(width: 1024, height: 768))
    }
}
