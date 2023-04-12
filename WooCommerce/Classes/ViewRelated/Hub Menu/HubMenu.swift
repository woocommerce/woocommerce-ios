import SwiftUI
import Kingfisher
import Yosemite

/// This view will be embedded inside the `HubMenuViewController`
/// and will be the entry point of the `Menu` Tab.
///
struct HubMenu: View {
    @ObservedObject private var iO = Inject.observer

    @ObservedObject private var viewModel: HubMenuViewModel

    @State private var showingPayments = false
    @State private var showingWooCommerceAdmin = false
    @State private var showingViewStore = false
    @State private var showingInbox = false
    @State private var showingReviews = false
    @State private var showingCoupons = false
    @State private var showingIAPDebug = false

    /// State to disable multiple taps on menu items
    /// Make sure to reset the value to false after dismissing sub-flows
    @State private var shouldDisableItemTaps = false

    /// A timer used as a fallback method for resetting disabled state of the menu
    ///
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(viewModel: HubMenuViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        EmptyView()
//        VStack {
//            TopBar(avatarURL: viewModel.avatarURL,
//                   storeTitle: viewModel.storeTitle,
//                   storeURL: viewModel.storeURL.host,
//                   switchStoreEnabled: viewModel.switchStoreEnabled) {
//                viewModel.presentSwitchStore()
//            }
//
//
//            ScrollView {
//                let gridItemLayout = [GridItem(.adaptive(minimum: Constants.itemSize), spacing: Constants.itemSpacing)]
//
//                LazyVGrid(columns: gridItemLayout, spacing: Constants.itemSpacing) {
//                    ForEach(viewModel.menuElements, id: \.id) { menu in
//                        // Currently the badge is always zero, because we are not handling push notifications count
//                        // correctly due to the first behavior described here p91TBi-66O:
//                        // AppDelegate’s `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`
//                        // can be called twice for the same push notification when receiving it
//                        // and tapping on it to open the app. This means that some push notifications are incrementing the badge number by 2, and some by 1.
//                        HubMenuElement(image: menu.icon,
//                                       imageColor: menu.iconColor,
//                                       text: menu.title,
//                                       badge: menu.badge,
//                                       isDisabled: $shouldDisableItemTaps,
//                                       onTapGesture: {
//                            ServiceLocator.analytics.track(.hubMenuOptionTapped,
//                                                           withProperties: [
//                                                            Constants.trackingOptionKey: menu.trackingOption,
//                                                            Constants.trackingBadgeVisibleKey: menu.badge.shouldBeRendered
//                                                           ])
//                            switch type(of: menu).id {
//                            case HubMenuViewModel.Payments.id:
//                                showingPayments = true
//                            case HubMenuViewModel.WoocommerceAdmin.id:
//                                showingWooCommerceAdmin = true
//                            case HubMenuViewModel.ViewStore.id:
//                                showingViewStore = true
//                            case HubMenuViewModel.Inbox.id:
//                                showingInbox = true
//                            case HubMenuViewModel.Reviews.id:
//                                showingReviews = true
//                            case HubMenuViewModel.Coupons.id:
//                                showingCoupons = true
//                            case HubMenuViewModel.InAppPurchases.id:
//                                showingIAPDebug = true
//                            case HubMenuViewModel.Upgrades.id:
//                                viewModel.presentUpgrades()
//                            default:
//                                break
//                            }
//                        }).accessibilityIdentifier(menu.accessibilityIdentifier)
//                    }
//                    .background(Color(.listForeground(modal: false)))
//                    .cornerRadius(Constants.cornerRadius)
//                    .padding([.bottom], Constants.padding)
//                }
//                .padding(Constants.padding)
//                .background(Color(.listBackground))
//            }
//            .sheet(isPresented: $showingWooCommerceAdmin, onDismiss: enableMenuItemTaps) {
//                WebViewSheet(viewModel: WebViewSheetViewModel(url: viewModel.woocommerceAdminURL,
//                                                              navigationTitle: HubMenuViewModel.Localization.woocommerceAdmin,
//                                                              authenticated: viewModel.shouldAuthenticateAdminPage)) {
//                    showingWooCommerceAdmin = false
//                }
//            }
//            .sheet(isPresented: $showingViewStore, onDismiss: enableMenuItemTaps) {
//                WebViewSheet(viewModel: WebViewSheetViewModel(url: viewModel.storeURL,
//                                                              navigationTitle: HubMenuViewModel.Localization.viewStore,
//                                                              authenticated: false)) {
//                    showingViewStore = false
//                }
//            }
//            NavigationLink(destination:
//                            InPersonPaymentsMenu()
//                            .navigationTitle(InPersonPaymentsView.Localization.title),
//                           isActive: $showingPayments) {
//                EmptyView()
//            }.hidden()
//            NavigationLink(destination:
//                            Inbox(viewModel: .init(siteID: viewModel.siteID)),
//                           isActive: $showingInbox) {
//                EmptyView()
//            }.hidden()
//            NavigationLink(destination:
//                            ReviewsView(siteID: viewModel.siteID),
//                           isActive: $showingReviews) {
//                EmptyView()
//            }.hidden()
//            NavigationLink(destination: CouponListView(siteID: viewModel.siteID), isActive: $showingCoupons) {
//                EmptyView()
//            }.hidden()
//            NavigationLink(destination: InAppPurchasesDebugView(), isActive: $showingIAPDebug) {
//                EmptyView()
//            }.hidden()
//            LazyNavigationLink(destination: viewModel.getReviewDetailDestination(), isActive: $viewModel.showingReviewDetail) {
//                EmptyView()
//            }
//        }
//        .enableInjection()
//        .navigationBarHidden(true)
//        .background(Color(.listBackground).edgesIgnoringSafeArea(.all))
//        .onAppear {
//            viewModel.setupMenuElements()
//            enableMenuItemTaps()
//        }
//        .onReceive(timer) { _ in
//            // fall back method in case menu disabled state is not reset properly
//            enableMenuItemTaps()
//        }
    }

    /// Reset state to make the menu items tappable
    private func enableMenuItemTaps() {
        shouldDisableItemTaps = false
    }
}

// MARK: SubViews
private extension HubMenu {
    struct Row: View {

        enum Icon {
            case local(UIImage)
            case remote(URL)
        }

        enum Chevron {
            case down
            case leading

            var asset: UIImage {
                switch self {
                case .down:
                    return .chevronDownImage
                case .leading:
                    return .chevronImage.imageFlippedForRightToLeftLayoutDirection()
                }
            }
        }

        let title: String
        let description: String
        let icon: Icon
        let chevron: Chevron
        let tapHandler: (() -> Void)?

        let titleAccessibilityID: String?
        let descriptionAccessibilityID: String?

        var body: some View {
            HStack(spacing: HubMenu.Constants.padding) {

                // Icon
                Group {
                    switch icon {
                    case .local(let asset):
                        Image(uiImage: asset)
                            .resizable()
                    case .remote(let url):
                        KFImage(url)
                            .resizable()
                    }
                }
                .clipShape(Circle())
                .frame(width: HubMenu.Constants.avatarSize, height: HubMenu.Constants.avatarSize)

                // Title & Description
                VStack(alignment: .leading, spacing: HubMenu.Constants.topBarSpacing) {
                    Text(title)
                        .headlineStyle()
                        .lineLimit(1)
                        .accessibilityIdentifier(titleAccessibilityID ?? "")

                    Text(description)
                        .subheadlineStyle()
                        .lineLimit(1)
                        .accessibilityIdentifier(descriptionAccessibilityID ?? "")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Tap Indicator
                Image(uiImage: chevron.asset)
                    .resizable()
                    .frame(width: HubMenu.Constants.chevronSize, height: HubMenu.Constants.chevronSize)
                    .foregroundColor(Color(.textSubtle))
                    .renderedIf(tapHandler != nil)

                    // TODO: Migrate settings button & tracks - to list below

                    //                    Button {
                    //                        ServiceLocator.analytics.track(.hubMenuSettingsTapped)
                    //                        showSettings = true
                    //                    } label: {
                    //                        ZStack {
                    //                            Circle()
                    //                                .fill(Color(UIColor(light: .white,
                    //                                                    dark: .secondaryButtonBackground)))
                    //                                .frame(width: settingsSize,
                    //                                       height: settingsSize)
                    //                            if let cogImage = UIImage.cogImage.imageWithTintColor(.accent) {
                    //                                Image(uiImage: cogImage)
                    //                                    .resizable()
                    //                                    .frame(width: settingsIconSize,
                    //                                           height: settingsIconSize)
                    //                            }
                    //                        }
                    //                    }
                    //                    .accessibilityLabel(Localization.settings)
                    //                    .accessibilityIdentifier("dashboard-settings-button")
                    //                    Spacer()
            }
            .padding()
            .background(Color(.listForeground(modal: false)))
            .cornerRadius(HubMenu.Constants.cornerRadius)
            .padding()
            .onTapGesture {
                tapHandler?() // TODO: Check what happens when logged in with store credentials and not wpcom
            }

        }
    }
}

// MARK: Definitions
private extension HubMenu {
    enum Constants {
        static let cornerRadius: CGFloat = 10
        static let itemSpacing: CGFloat = 12
        static let itemSize: CGFloat = 160
        static let padding: CGFloat = 16
        static let topBarSpacing: CGFloat = 2
        static let avatarSize: CGFloat = 40
        static let chevronSize: CGFloat = 20
        static let trackingOptionKey = "option"
        static let trackingBadgeVisibleKey = "badge_visible"
    }

    enum Localization {
        static let settings = NSLocalizedString("Settings", comment: "Settings button in the hub menu")
    }
}

struct HubMenu_Previews: PreviewProvider {
    static var previews: some View {
//        HubMenu(viewModel: .init(siteID: 123))
//            .environment(\.colorScheme, .light)
//
//        HubMenu(viewModel: .init(siteID: 123))
//            .environment(\.colorScheme, .dark)
//
//        HubMenu(viewModel: .init(siteID: 123))
//            .previewLayout(.fixed(width: 312, height: 528))
//            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
//
//        HubMenu(viewModel: .init(siteID: 123))
//            .previewLayout(.fixed(width: 1024, height: 768))

        Group {
            HubMenu.Row(title: "My Store",
                        description: "mystore.wordpress.com",
                        icon: .local(.gearBarButtonItemImage),
                        chevron: .leading,
                        tapHandler: nil,
                        titleAccessibilityID: nil,
                        descriptionAccessibilityID: nil)
            .padding()
        }
        .background(.gray)
        .previewLayout(.sizeThatFits)
    }
}
