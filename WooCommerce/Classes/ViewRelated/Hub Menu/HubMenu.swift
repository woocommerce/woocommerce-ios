import SwiftUI
import Kingfisher

/// This view will be embedded inside the `HubMenuViewController`
/// and will be the entry point of the `Menu` Tab.
///
struct HubMenu: View {
    @ObservedObject private var viewModel: HubMenuViewModel
    @State private var showWooCommerceAdmin = false
    @State private var showViewStore = false
    @State private var showReviews = false

    init(siteID: Int64, navigationController: UINavigationController? = nil) {
        viewModel = HubMenuViewModel(siteID: siteID, navigationController: navigationController)
    }

    var body: some View {
        VStack {
            TopBar(avatarURL: viewModel.avatarURL,
                   storeTitle: viewModel.storeTitle,
                   storeURL: viewModel.storeURL.absoluteString) {
                viewModel.presentSwitchStore()
            }

            ScrollView {
                let gridItemLayout = [GridItem(.adaptive(minimum: Constants.itemSize), spacing: Constants.itemSpacing)]

                LazyVGrid(columns: gridItemLayout, spacing: Constants.itemSpacing) {
                    ForEach(viewModel.menuElements, id: \.self) { menu in
                        HubMenuElement(image: menu.icon, text: menu.title)
                            .frame(width: Constants.itemSize, height: Constants.itemSize)
                            .onTapGesture {
                                switch menu {
                                case .woocommerceAdmin:
                                    showWooCommerceAdmin = true
                                case .viewStore:
                                    showViewStore = true
                                case .reviews:
                                    showReviews = true
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
            .safariSheet(isPresented: $showWooCommerceAdmin, url: viewModel.woocommerceAdminURL)
            .safariSheet(isPresented: $showViewStore, url: viewModel.storeURL)
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
        let avatarURL: URL?
        let storeTitle: String
        let storeURL: String?
        var presenSwitchStore: (() -> Void)?

        @State private var showSettings = false
        @ScaledMetric private var settingsSize: CGFloat = 24
        @ScaledMetric private var settingsIconSize: CGFloat = 20

        var body: some View {
            HStack(spacing: Constants.padding) {
                if let avatarURL = avatarURL {
                    KFImage(avatarURL)
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                }

                VStack(alignment: .leading,
                       spacing: Constants.topBarSpacing) {
                    Text(storeTitle).headlineStyle()
                    if let storeURL = storeURL {
                        Text(storeURL)
                            .subheadlineStyle()
                    }
                    Button(Localization.switchStore) {
                        presenSwitchStore?()
                    }
                    .linkStyle()
                }
                Spacer()
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: settingsSize,
                                   height: settingsSize)
                        if let cogImage = UIImage.cogImage.imageWithTintColor(.primary) {
                            Image(uiImage: cogImage)
                                .resizable()
                                .frame(width: settingsIconSize,
                                       height: settingsIconSize)
                        }
                    }
                    .onTapGesture {
                        showSettings = true
                    }
                    Spacer()
                }
                .fixedSize()
            }
            .padding([.top, .leading, .trailing], Constants.padding)

            NavigationLink(destination:
                            SettingsView(),
                           isActive: $showSettings) {
                EmptyView()
            }.hidden()
        }
    }

    private enum Constants {
        static let cornerRadius: CGFloat = 10
        static let itemSpacing: CGFloat = 12
        static let itemSize: CGFloat = 160
        static let padding: CGFloat = 16
        static let topBarSpacing: CGFloat = 2
        static let avatarSize: CGFloat = 40
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
