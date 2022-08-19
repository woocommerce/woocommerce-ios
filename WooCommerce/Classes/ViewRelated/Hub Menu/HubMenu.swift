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
        VStack {
            TopBar(avatarURL: viewModel.avatarURL,
                   storeTitle: viewModel.storeTitle,
                   storeURL: viewModel.storeURL.absoluteString) {
                viewModel.presentSwitchStore()
            }
                   .padding([.leading, .trailing], Constants.padding)

            ScrollView {
                let gridItemLayout = [GridItem(.adaptive(minimum: Constants.itemSize), spacing: Constants.itemSpacing)]

                LazyVGrid(columns: gridItemLayout, spacing: Constants.itemSpacing) {
                    ForEach(viewModel.menuElements, id: \.id) { menu in
                        // Currently the badge is always zero, because we are not handling push notifications count
                        // correctly due to the first behavior described here p91TBi-66O:
                        // AppDelegate’s `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`
                        // can be called twice for the same push notification when receiving it
                        // and tapping on it to open the app. This means that some push notifications are incrementing the badge number by 2, and some by 1.
                        HubMenuElement(image: menu.icon,
                                       imageColor: menu.iconColor,
                                       text: menu.title,
                                       badge: menu.badge,
                                       isDisabled: $shouldDisableItemTaps,
                                       onTapGesture: {
                            ServiceLocator.analytics.track(.hubMenuOptionTapped,
                                                           withProperties: [
                                                            Constants.trackingOptionKey: menu.trackingOption,
                                                            Constants.trackingBadgeVisibleKey: menu.badge.shouldBeRendered
                                                           ])
                            switch type(of: menu).id {
                            case HubMenuViewModel.Payments.id:
                                viewModel.paymentsScreenWasOpened()
                                showingPayments = true
                            case HubMenuViewModel.WoocommerceAdmin.id:
                                showingWooCommerceAdmin = true
                            case HubMenuViewModel.ViewStore.id:
                                showingViewStore = true
                            case HubMenuViewModel.Inbox.id:
                                showingInbox = true
                            case HubMenuViewModel.Reviews.id:
                                showingReviews = true
                            case HubMenuViewModel.Coupons.id:
                                showingCoupons = true
                            default:
                                break
                            }
                        }).accessibilityIdentifier(menu.accessibilityIdentifier)
                    }
                    .background(Color(.listForeground))
                    .cornerRadius(Constants.cornerRadius)
                    .padding([.bottom], Constants.padding)
                }
                .padding(Constants.padding)
                .background(Color(.listBackground))
            }
            .safariSheet(isPresented: $showingWooCommerceAdmin,
                         url: viewModel.woocommerceAdminURL,
                         onDismiss: enableMenuItemTaps)
            .safariSheet(isPresented: $showingViewStore,
                         url: viewModel.storeURL,
                         onDismiss: enableMenuItemTaps)
            NavigationLink(destination:
                            InPersonPaymentsMenu()
                            .navigationTitle(InPersonPaymentsView.Localization.title),
                           isActive: $showingPayments) {
                EmptyView()
            }.hidden()
            NavigationLink(destination:
                            Inbox(viewModel: .init(siteID: viewModel.siteID)),
                           isActive: $showingInbox) {
                EmptyView()
            }.hidden()
            NavigationLink(destination:
                            ReviewsView(siteID: viewModel.siteID),
                           isActive: $showingReviews) {
                EmptyView()
            }.hidden()
            NavigationLink(destination: CouponListView(siteID: viewModel.siteID), isActive: $showingCoupons) {
                EmptyView()
            }.hidden()
            LazyNavigationLink(destination: viewModel.getReviewDetailDestination(), isActive: $viewModel.showingReviewDetail) {
                EmptyView()
            }
        }
        .enableInjection()
        .navigationBarHidden(true)
        .background(Color(.listBackground).edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.setupMenuElements()
            enableMenuItemTaps()
        }
        .onReceive(timer) { _ in
            // fall back method in case menu disabled state is not reset properly
            enableMenuItemTaps()
        }
    }

    /// Reset state to make the menu items tappable
    private func enableMenuItemTaps() {
        shouldDisableItemTaps = false
    }

    private struct TopBar: View {
        let avatarURL: URL?
        let storeTitle: String
        let storeURL: String?
        var switchStoreHandler: (() -> Void)?

        @State private var showSettings = false
        @ScaledMetric var settingsSize: CGFloat = 28
        @ScaledMetric var settingsIconSize: CGFloat = 20

        var body: some View {
            HStack(spacing: Constants.padding) {
                if let avatarURL = avatarURL {
                    VStack {
                        KFImage(avatarURL)
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                        Spacer()
                    }
                    .fixedSize()
                }

                VStack(alignment: .leading,
                       spacing: Constants.topBarSpacing) {
                    Text(storeTitle)
                        .headlineStyle()
                        .lineLimit(1)
                    if let storeURL = storeURL {
                        Text(storeURL)
                            .subheadlineStyle()
                            .lineLimit(1)
                    }
                    Button(Localization.switchStore) {
                        switchStoreHandler?()
                    }
                    .linkStyle()
                }
                Spacer()
                VStack {
                    Button {
                        ServiceLocator.analytics.track(.hubMenuSettingsTapped)
                        showSettings = true
                    } label: {
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
                    }
                    .accessibilityLabel(Localization.settings)
                    .accessibilityIdentifier("dashboard-settings-button")
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
        static let trackingOptionKey = "option"
        static let trackingBadgeVisibleKey = "badge_visible"
    }

    private enum Localization {
        static let switchStore = NSLocalizedString("Switch store",
                                                   comment: "Switch store option in the hub menu")
        static let settings = NSLocalizedString("Settings", comment: "Settings button in the hub menu")
    }
}

struct HubMenu_Previews: PreviewProvider {
    static var previews: some View {
        HubMenu(viewModel: .init(siteID: 123))
            .environment(\.colorScheme, .light)

        HubMenu(viewModel: .init(siteID: 123))
            .environment(\.colorScheme, .dark)

        HubMenu(viewModel: .init(siteID: 123))
            .previewLayout(.fixed(width: 312, height: 528))
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

        HubMenu(viewModel: .init(siteID: 123))
            .previewLayout(.fixed(width: 1024, height: 768))
    }
}
