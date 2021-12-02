import SwiftUI

/// This view will be embedded inside the `HubMenuViewController`
/// and will be the entry point of the `Menu` Tab.
///
struct HubMenu: View {
    @ObservedObject private var viewModel =  HubMenuViewModel()


    var body: some View {
        VStack {
            TopBar(storeTitle: viewModel.storeTitle,
                   storeURL: viewModel.storeURL)

            ScrollView {
                let gridItemLayout = [GridItem(.adaptive(minimum: Constants.itemSize), spacing: Constants.itemSpacing)]

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
        }
        .navigationBarHidden(true)
        .background(Color(.listBackground).edgesIgnoringSafeArea(.all))

    }

    private struct TopBar: View {
        let storeTitle: String
        let storeURL: String

        var body: some View {
            HStack() {
                VStack(alignment: .leading,
                       spacing: Constants.topBarSpacing) {
                    Text(storeTitle).headlineStyle()
                    Text(storeURL)
                        .subheadlineStyle()
                    Button(Localization.switchStore) {

                    }
                    .linkStyle()
                }
            }
            .padding(Constants.padding)
        }
    }

    private enum Constants {
        static let cornerRadius: CGFloat = 10
        static let itemSpacing: CGFloat = 12
        static let itemSize: CGFloat = 160
        static let padding: CGFloat = 16
        static let topBarSpacing: CGFloat = 2
    }

    private enum Localization {
        static let switchStore = NSLocalizedString("Switch store",
                                                   comment: "Switch store option in the hub menu")
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
