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

    /// Returns `nil` if `viewModel.switchStoreEnabled` is false.
    /// Otherwise returns a closure calls `viewModel.presentSwitchStore()` when invoked.
    ///
    private var storeSwitchTapHandler: (() -> ())? {
        guard viewModel.switchStoreEnabled else { return nil }
        return {
            viewModel.presentSwitchStore()
        }
    }

    init(viewModel: HubMenuViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {

            // Store Section
            Section {
                Row(title: viewModel.storeTitle,
                    description: viewModel.storeURL.host ?? viewModel.storeURL.absoluteString,
                    icon: .remote(viewModel.avatarURL),
                    chevron: .down,
                    tapHandler: storeSwitchTapHandler,
                    titleAccessibilityID: "store-title",
                    descriptionAccessibilityID: "store-url",
                    chevronAccessibilityID: "switch-store-button")
            }

            // Settings Section
            Section(Localization.settings) {
                ForEach(viewModel.settingsElements, id: \.id) { menu in
                    Row(title: menu.title,
                        description: "",
                        icon: .local(menu.icon),
                        chevron: .leading,
                        tapHandler: {
                    })
                    .foregroundColor(Color(menu.iconColor))
                    .accessibilityIdentifier(menu.accessibilityIdentifier)
                }
            }

            // General Section
            Section(Localization.general) {
                ForEach(viewModel.generalElements, id: \.id) { menu in
                    Row(title: menu.title,
                        description: "",
                        icon: .local(menu.icon),
                        chevron: .leading,
                        tapHandler: {

                        // TODO: This should be done in the View Model
                        ServiceLocator.analytics.track(.hubMenuOptionTapped, withProperties: [
                            Constants.trackingOptionKey: menu.trackingOption,
                            Constants.trackingBadgeVisibleKey: menu.badge.shouldBeRendered
                        ])

                        switch type(of: menu).id {
                        case HubMenuViewModel.Payments.id:
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
                        case HubMenuViewModel.InAppPurchases.id:
                            showingIAPDebug = true
                        case HubMenuViewModel.Upgrades.id:
                            viewModel.presentUpgrades()
                        default:
                            break
                        }

                    })
                    .foregroundColor(Color(menu.iconColor))
                    .accessibilityIdentifier(menu.accessibilityIdentifier)
                }
            }
        }
        .listStyle(.automatic)
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
        .sheet(isPresented: $showingWooCommerceAdmin, onDismiss: enableMenuItemTaps) {
            WebViewSheet(viewModel: WebViewSheetViewModel(url: viewModel.woocommerceAdminURL,
                                                          navigationTitle: HubMenuViewModel.Localization.woocommerceAdmin,
                                                          authenticated: viewModel.shouldAuthenticateAdminPage)) {
                showingWooCommerceAdmin = false
            }
        }
        .sheet(isPresented: $showingViewStore, onDismiss: enableMenuItemTaps) {
            WebViewSheet(viewModel: WebViewSheetViewModel(url: viewModel.storeURL,
                                                          navigationTitle: HubMenuViewModel.Localization.viewStore,
                                                          authenticated: false)) {
                showingViewStore = false
            }
        }
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
        NavigationLink(destination: InAppPurchasesDebugView(), isActive: $showingIAPDebug) {
            EmptyView()
        }.hidden()
        LazyNavigationLink(destination: viewModel.getReviewDetailDestination(), isActive: $viewModel.showingReviewDetail) {
            EmptyView()
        }
    }

    /// Reset state to make the menu items tappable
    private func enableMenuItemTaps() {
        shouldDisableItemTaps = false // TODO: test this
    }
}

// MARK: SubViews
private extension HubMenu {

    /// Reusable List row for the hub menu
    ///
    struct Row: View {

        /// Image source for the icon/avatar.
        ///
        enum Icon {
            case local(UIImage)
            case remote(URL?)
        }

        /// Style for the chevron indicator.
        ///
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

        /// Row Title
        ///
        let title: String

        /// Row Description
        ///
        let description: String

        /// Row Icon
        ///
        let icon: Icon

        /// Row chevron indicator
        ///
        let chevron: Chevron

        /// Closure invoked when the row is tapped.
        ///
        let tapHandler: (() -> Void)?

        var titleAccessibilityID: String?
        var descriptionAccessibilityID: String?
        var chevronAccessibilityID: String?

        var body: some View {
            HStack(spacing: HubMenu.Constants.padding) {

                HStack(spacing: .zero) {
                    /// iOS 16, aligns the list dividers to the first text position.
                    /// This tricks the system by rendering an empty text and forcing the list lo align the divider to it.
                    /// Without this, the divider will be rendered from the title and will not cover the icon.
                    /// Ideally we would want to use the `alignmentGuide` modifier but that is only available on iOS 16.
                    ///
                    Text("")

                    // Icon
                    Group {
                        switch icon {
                        case .local(let asset):
                            Circle()
                                .fill(Color(.init(light: .listBackground, dark: .secondaryButtonBackground)))
                                .frame(width: HubMenu.Constants.avatarSize, height: HubMenu.Constants.avatarSize)
                                .overlay {
                                    Image(uiImage: asset)
                                        .resizable()
                                        .frame(width: HubMenu.Constants.iconSize, height: HubMenu.Constants.iconSize)
                                }

                        case .remote(let url):
                            KFImage(url)
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: HubMenu.Constants.avatarSize, height: HubMenu.Constants.avatarSize)
                        }
                    }
                }


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
                    .renderedIf(tapHandler != nil) // TODO: Check if this is needed
                    .accessibilityIdentifier(chevronAccessibilityID ?? "")

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
            .padding(.vertical, Constants.rowVerticalPadding)
            .background(Color(.listForeground(modal: false)))
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
        static let padding: CGFloat = 16
        static let rowVerticalPadding: CGFloat = 8
        static let topBarSpacing: CGFloat = 2
        static let avatarSize: CGFloat = 40
        static let chevronSize: CGFloat = 20
        static let iconSize: CGFloat = 20
        static let trackingOptionKey = "option"
        static let trackingBadgeVisibleKey = "badge_visible"
    }

    enum Localization {
        static let settings = NSLocalizedString("Settings", comment: "Settings button in the hub menu")
        static let general = NSLocalizedString("General", comment: "General section title in the hub menu")
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
