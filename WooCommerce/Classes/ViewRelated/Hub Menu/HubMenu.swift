import SwiftUI

/// This view will be embedded inside the `HubMenuViewController`
/// and will be the entry point of the `Menu` Tab.
///
struct HubMenu: View {
    @ObservedObject private var viewModel: HubMenuViewModel
    @State private var showViewStore = false
    @State private var showReviews = false
    @State private var showingCoupons = false

    init(siteID: Int64) {
        viewModel = HubMenuViewModel(siteID: siteID)
    }

    var body: some View {
        VStack {
            TopBar(storeTitle: viewModel.storeTitle,
                   storeURL: viewModel.storeURL.absoluteString)

            ScrollView {
                let gridItemLayout = [GridItem(.adaptive(minimum: Constants.itemSize), spacing: Constants.itemSpacing)]

                LazyVGrid(columns: gridItemLayout, spacing: Constants.itemSpacing) {
                    ForEach(viewModel.menuElements, id: \.self) { menu in
                        HubMenuElement(image: menu.icon, text: menu.title)
                            .frame(width: Constants.itemSize, height: Constants.itemSize)
                            .onTapGesture {
                                switch menu {
                                case .viewStore:
                                    showViewStore = true
                                case .reviews:
                                    showReviews = true
                                case .coupons:
                                    showingCoupons = true
                                default:
                                    // TODO-5509: handle the remaining cases
                                    break
                                }
                            }
                    }
                    .background(Color(.listForeground))
                    .cornerRadius(Constants.cornerRadius)
                    .padding([.bottom], Constants.padding)
                }
                .padding(Constants.padding)
                .background(Color(.listBackground))
            }
            .safariSheet(isPresented: $showViewStore, url: viewModel.storeURL)
            NavigationLink(destination:
                            ReviewsView(siteID: viewModel.siteID),
                           isActive: $showReviews) {
                EmptyView()
            }.hidden()
            NavigationLink(destination: CouponListView(siteID: viewModel.siteID), isActive: $showingCoupons) {
                EmptyView()
            }.hidden()
        }
        .navigationBarHidden(true)
        .background(Color(.listBackground).edgesIgnoringSafeArea(.all))
    }

    private struct TopBar: View {
        let storeTitle: String
        let storeURL: String?

        @ScaledMetric var settingsSize: CGFloat = 28
        @ScaledMetric var settingsIconSize: CGFloat = 20

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
                            .fill(Color(UIColor(light: .white,
                                                dark: .secondaryButtonBackground)))
                            .frame(width: settingsSize,
                                   height: settingsSize)
                        if let cogImage = UIImage.cogImage.imageWithTintColor(.accent) {
                            Image(uiImage: cogImage)
                                .resizable()
                                .frame(width: settingsIconSize,
                                       height: settingsIconSize)
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
