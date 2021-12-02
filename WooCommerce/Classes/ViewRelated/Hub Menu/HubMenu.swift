import SwiftUI

/// This view will be embedded inside the `HubMenuViewController`
/// and will be the entry point of the `Menu` Tab.
///
struct HubMenu: View {
    @ObservedObject private var viewModel: HubMenuViewModel
    @State private var showReviews = false

    init(siteID: Int64) {
        viewModel = HubMenuViewModel(siteID: siteID)
    }

    var body: some View {
        VStack {
            TopBar(storeTitle: viewModel.storeTitle,
                   storeURL: viewModel.storeURL)

            ScrollView {
                let gridItemLayout = [GridItem(.adaptive(minimum: Constants.itemSize), spacing: Constants.itemSpacing)]

                LazyVGrid(columns: gridItemLayout) {
                    ForEach(viewModel.menuElements, id: \.self) { menu in
                        HubMenuElement(image: menu.icon, text: menu.title)
                            .frame(width: Constants.itemSize, height: Constants.itemSize)
                            .onTapGesture {
                                switch menu {
                                case .reviews:
                                    showReviews = true
                                default:
                                    // TODO-5509: handle the remaining cases
                                    break
                                }
                            }
                    }
                    .background(Color.white)
                    .cornerRadius(Constants.cornerRadius)
                    .padding([.bottom], Constants.padding)
                }
                .padding(Constants.padding)
                .background(Color(.listBackground))
            }
            NavigationLink(destination:
                            ReviewsView(siteID: viewModel.siteID),
                           isActive: $showReviews) {
                EmptyView()
            }.hidden()
        }
        .navigationBarHidden(true)
        .background(Color(.listBackground).edgesIgnoringSafeArea(.all))

    }

    private struct TopBar: View {
        let storeTitle: String
        let storeURL: String?

        var body: some View {
            HStack() {
                VStack(alignment: .leading,
                       spacing: Constants.topBarSpacing) {
                    Text(storeTitle).headlineStyle()
                    if let storeURL = storeURL {
                        Text(storeURL)
                            .subheadlineStyle()
                    }
                    Button(Localization.switchStore) {

                    }
                    .linkStyle()
                }
                Spacer()
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: Constants.settingsSize,
                                   height: Constants.settingsSize)
                        if let gearImage = UIImage.gearImage.imageWithTintColor(.primary) {
                            Image(uiImage: gearImage)
                        }
                    }
                    .onTapGesture {
                        // TODO-5509: implement tap
                    }
                    Spacer()
                }
                .fixedSize()
            }
            .padding([.top, .leading, .trailing], Constants.padding)
        }
    }

    private enum Constants {
        static let cornerRadius: CGFloat = 10
        static let itemSpacing: CGFloat = 12
        static let itemSize: CGFloat = 160
        static let padding: CGFloat = 16
        static let topBarSpacing: CGFloat = 2
        static let settingsSize: CGFloat = 24
    }

    private enum Localization {
        static let switchStore = NSLocalizedString("Switch store",
                                                   comment: "Switch store option in the hub menu")
    }
}

struct HubMenu_Previews: PreviewProvider {
    static var previews: some View {
        HubMenu(siteID: 123)
            .environment(\.colorScheme, .light)

        HubMenu(siteID: 123)
            .environment(\.colorScheme, .dark)

        HubMenu(siteID: 123)
            .previewLayout(.fixed(width: 312, height: 528))
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

        HubMenu(siteID: 123)
            .previewLayout(.fixed(width: 1024, height: 768))
    }
}
