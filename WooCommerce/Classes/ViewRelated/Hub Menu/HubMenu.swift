import SwiftUI
import Kingfisher
import Yosemite

/// This view will be embedded inside the `HubMenuViewController`
/// and will be the entry point of the `Menu` Tab.
///
struct HubMenu: View {
    /// Set from the hosting controller to handle switching store.
    var switchStoreHandler: () -> Void = {}

    /// Set from the hosting controller to open Google Ads campaigns.
    var googleAdsCampaignHandler: () -> Void = {}

    @ObservedObject private var iO = Inject.observer

    @ObservedObject private var viewModel: HubMenuViewModel

    init(viewModel: HubMenuViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            /// TODO: switch to `navigationDestination(item:destination)`
            /// when we drop support for iOS 16.
            menuList
                .navigationDestination(for: HubMenuNavigationDestination.self) { destination in
                    detailView(destination: destination)
                }
                .onAppear {
                    viewModel.setupMenuElements()
                }
        }
    }

    /// Handle navigation when tapping a list menu row.
    ///
    private func handleTap(menu: HubMenuItem) {
        ServiceLocator.analytics.track(.hubMenuOptionTapped, withProperties: [
            Constants.trackingOptionKey: menu.trackingOption
        ])

        switch menu.id {
        case HubMenuViewModel.GoogleAds.id:
            googleAdsCampaignHandler()
        case HubMenuViewModel.Settings.id:
            ServiceLocator.analytics.track(.hubMenuSettingsTapped)
        case HubMenuViewModel.Blaze.id:
            ServiceLocator.analytics.track(event: .Blaze.blazeCampaignListEntryPointSelected(source: .menu))
        default:
            break
        }

        viewModel.navigateToDestination(menu.navigationDestination)
    }
}

// MARK: SubViews
private extension HubMenu {

    var menuList: some View {
        List {
            // Store Section
            Section {
                Button {
                    ServiceLocator.analytics.track(.hubMenuSwitchStoreTapped)
                    switchStoreHandler()
                } label: {
                    Row(title: viewModel.storeTitle,
                        titleBadge: viewModel.planName,
                        iconBadge: nil,
                        description: viewModel.storeURL.host ?? viewModel.storeURL.absoluteString,
                        icon: .remote(viewModel.avatarURL),
                        chevron: viewModel.switchStoreEnabled ? .down : .none,
                        titleAccessibilityID: "store-title",
                        descriptionAccessibilityID: "store-url",
                        chevronAccessibilityID: "switch-store-button")
                    .lineLimit(1)
                }
                .disabled(!viewModel.switchStoreEnabled)
            }

            // Point of Sale
            if let menu = viewModel.posElement {
                Section {
                    menuItemView(menu: menu, chevron: .enteringMode)
                }
            }

            // Settings Section
            Section(Localization.settings) {
                ForEach(viewModel.settingsElements, id: \.id) { menu in
                    menuItemView(menu: menu)
                }
            }

            // General Section
            Section(Localization.general) {
                ForEach(viewModel.generalElements, id: \.id) { menu in
                    menuItemView(menu: menu)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color(.listBackground))
        .accentColor(Color(.listSelectedBackground))
    }

    @ViewBuilder
    func menuItemView(menu: HubMenuItem, chevron: Row.Chevron = .leading) -> some View {
        Button {
            handleTap(menu: menu)
        } label: {
            Row(title: menu.title,
                titleBadge: nil,
                iconBadge: menu.iconBadge,
                description: menu.description,
                icon: .local(menu.icon),
                chevron: chevron)
            .foregroundColor(Color(menu.iconColor))
        }
        .accessibilityIdentifier(menu.accessibilityIdentifier)
    }

    @ViewBuilder
    func detailView(destination: HubMenuNavigationDestination) -> some View {
        Group {
            switch destination {
            case .settings:
                ViewControllerContainer(SettingsViewController())
                    .navigationTitle(HubMenuViewModel.Localization.settings)
            case .payments:
                paymentsView
            case .blaze:
                BlazeCampaignListHostingControllerRepresentable(siteID: viewModel.siteID)
            case .wooCommerceAdmin:
                webView(url: viewModel.woocommerceAdminURL,
                        title: HubMenuViewModel.Localization.woocommerceAdmin,
                        shouldAuthenticate: viewModel.shouldAuthenticateAdminPage)
            case .viewStore:
                webView(url: viewModel.storeURL,
                        title: HubMenuViewModel.Localization.viewStore,
                        shouldAuthenticate: false)
            case .inbox:
                Inbox(viewModel: viewModel.inboxViewModel)
            case .reviews:
                ReviewsView(siteID: viewModel.siteID)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle(Localization.reviews)
            case .coupons:
                couponListView
            case .inAppPurchase:
                InAppPurchasesDebugView()
            case .subscriptions:
                SubscriptionsView(viewModel: .init())
            case .customers:
                CustomersListView(viewModel: .init(siteID: viewModel.siteID))
            case .pointOfSales:
                if let cardPresentPaymentService = viewModel.cardPresentPaymentService,
                   let orderService = POSOrderService(siteID: viewModel.siteID,
                                                      credentials: viewModel.credentials) {
                    PointOfSaleEntryPointView(
                        itemProvider: viewModel.posItemProvider,
                        onPointOfSaleModeActiveStateChange: { isEnabled in
                            viewModel.updateDefaultConfigurationForPointOfSale(isEnabled)
                        },
                        cardPresentPaymentService: cardPresentPaymentService,
                        orderService: orderService,
                        currencyFormatter: .init(currencySettings: ServiceLocator.currencySettings),
                        analytics: ServiceLocator.analytics)
                } else {
                    // TODO: When we have a singleton for the card payment service, this should not be required.
                    Text("Error creating card payment service")
                }
            case .reviewDetails(let parcel):
                reviewDetailView(parcel: parcel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    func webView(url: URL,
                 title: String,
                 shouldAuthenticate: Bool,
                 urlToTriggerExit: String? = nil,
                 redirectHandler: ((URL) -> Void)? = nil) -> some View {
        Group {
            if shouldAuthenticate {
                AuthenticatedWebView(isPresented: .constant(true),
                                     url: url,
                                     urlToTriggerExit: urlToTriggerExit,
                                     redirectHandler: redirectHandler)
            } else {
                WebView(isPresented: .constant(true),
                        url: url,
                        urlToTriggerExit: urlToTriggerExit,
                        redirectHandler: redirectHandler)
            }
        }
        .navigationTitle(title)
    }

    @ViewBuilder
    func reviewDetailView(parcel: ProductReviewFromNoteParcel) -> some View {
        ViewControllerContainer(ReviewDetailsViewController(productReview: parcel.review, product: parcel.product, notification: parcel.note))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.productReview)
    }

    var paymentsView: some View {
        InPersonPaymentsMenu(viewModel: viewModel.inPersonPaymentsMenuViewModel)
            .navigationBarTitleDisplayMode(.inline)
    }

    var couponListView: some View {
        EnhancedCouponListView(siteID: viewModel.siteID)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.coupons)
    }

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
            case none
            case down
            case leading
            case enteringMode

            var asset: UIImage {
                switch self {
                case .none:
                    return UIImage()
                case .down:
                    return .chevronDownImage
                case .leading:
                    return .chevronImage
                case .enteringMode:
                    return .switchingModeImage
                        .withTintColor(.secondaryLabel, renderingMode: .alwaysTemplate)
                }
            }
        }

        /// Row Title
        ///
        let title: String

        /// Text badge displayed adjacent to the title
        ///
        let titleBadge: String?

        /// Badge displayed on the icon.
        ///
        let iconBadge: HubMenuBadgeType?

        /// Row Description
        ///
        let description: String

        /// Row Icon
        ///
        let icon: Icon

        /// Row chevron indicator
        ///
        let chevron: Chevron

        var titleAccessibilityID: String?
        var descriptionAccessibilityID: String?
        var chevronAccessibilityID: String?

        @Environment(\.sizeCategory) private var sizeCategory

        var body: some View {
            HStack(spacing: HubMenu.Constants.padding) {

                HStack(spacing: .zero) {
                    ZStack {
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
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: HubMenu.Constants.iconSize, height: HubMenu.Constants.iconSize)
                                    }

                            case .remote(let url):
                                KFImage(url)
                                    .placeholder { Image(uiImage: .gravatarPlaceholderImage).resizable() }
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: HubMenu.Constants.avatarSize, height: HubMenu.Constants.avatarSize)
                                    .clipShape(Circle())
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            // Badge
                            if case .dot = iconBadge {
                                Circle()
                                    .fill(Color(.accent))
                                    .frame(width: HubMenu.Constants.dotBadgeSize)
                                    .padding(HubMenu.Constants.dotBadgePadding)
                            }
                        }
                    }
                }
                // Adjusts the list row separator to align with the leading edge of this view.
                .alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] }


                // Title & Description
                VStack(alignment: .leading, spacing: HubMenu.Constants.topBarSpacing) {

                    AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.badgeSpacing(sizeCategory: sizeCategory)) {
                        Text(title)
                            .headlineStyle()
                            .accessibilityIdentifier(titleAccessibilityID ?? "")

                        if let titleBadge, titleBadge.isNotEmpty {
                            BadgeView(text: titleBadge)
                        }
                    }

                    Text(description)
                        .subheadlineStyle()
                        .accessibilityIdentifier(descriptionAccessibilityID ?? "")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Tap Indicator
                Image(uiImage: chevron.asset)
                    .resizable()
                    .frame(width: HubMenu.Constants.chevronSize, height: HubMenu.Constants.chevronSize)
                    .flipsForRightToLeftLayoutDirection(true)
                    .foregroundColor(Color(.textSubtle))
                    .accessibilityIdentifier(chevronAccessibilityID ?? "")
                    .renderedIf(chevron != .none)
            }
            .padding(.vertical, Constants.rowVerticalPadding)
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
        static let dotBadgePadding = EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 2)
        static let dotBadgeSize: CGFloat = 6

        /// Spacing for the badge view in the avatar row.
        ///
        static func badgeSpacing(sizeCategory: ContentSizeCategory) -> CGFloat {
            sizeCategory.isAccessibilityCategory ? .zero : 4
        }
    }

    enum Localization {
        static let settings = NSLocalizedString("Settings", comment: "Settings button in the hub menu")
        static let general = NSLocalizedString("General", comment: "General section title in the hub menu")
        static let productReview = NSLocalizedString(
            "hubMenu.productReview",
            value: "Product Review",
            comment: "Title of the view containing a single Product Review"
        )
        static let reviews = NSLocalizedString(
            "hubMenu.coupons",
            value: "Reviews",
            comment: "Title of the view containing Reviews list"
        )
        static let coupons = NSLocalizedString(
            "hubMenu.coupons",
            value: "Coupons",
            comment: "Title of the view containing Coupons list"
        )
    }
}

struct HubMenu_Previews: PreviewProvider {
    static var previews: some View {
        HubMenu(viewModel: .init(siteID: 123, tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker()))
            .environment(\.colorScheme, .light)

        HubMenu(viewModel: .init(siteID: 123, tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker()))
            .environment(\.colorScheme, .dark)

        HubMenu(viewModel: .init(siteID: 123, tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker()))
            .previewLayout(.fixed(width: 312, height: 528))
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

        HubMenu(viewModel: .init(siteID: 123, tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker()))
            .previewLayout(.fixed(width: 1024, height: 768))
    }
}
