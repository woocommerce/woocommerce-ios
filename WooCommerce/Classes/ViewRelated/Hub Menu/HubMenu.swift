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
    @State private var showSettings = false

    init(viewModel: HubMenuViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {

            // Store Section
            Section {
                Button {
                    viewModel.presentSwitchStore()
                } label: {
                    Row(title: viewModel.storeTitle,
                        badge: viewModel.planName,
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

            // Settings Section
            Section(Localization.settings) {
                ForEach(viewModel.settingsElements, id: \.id) { menu in
                    Button {
                        handleTap(menu: menu)
                    } label: {
                        Row(title: menu.title,
                            badge: nil,
                            description: menu.description,
                            icon: .local(menu.icon),
                            chevron: .leading)
                        .foregroundColor(Color(menu.iconColor))
                    }
                    .accessibilityIdentifier(menu.accessibilityIdentifier)
                }
            }

            // General Section
            Section(Localization.general) {
                ForEach(viewModel.generalElements, id: \.id) { menu in
                    Button {
                        handleTap(menu: menu)
                    } label: {
                        Row(title: menu.title,
                            badge: nil,
                            description: menu.description,
                            icon: .local(menu.icon),
                            chevron: .leading)
                        .foregroundColor(Color(menu.iconColor))
                    }
                    .accessibilityIdentifier(menu.accessibilityIdentifier)
                }
            }
        }
        .listStyle(.automatic)
        .navigationBarHidden(true)
        .background(Color(.listBackground).edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.setupMenuElements()
        }
        .sheet(isPresented: $showingWooCommerceAdmin) {
            WebViewSheet(viewModel: WebViewSheetViewModel(url: viewModel.woocommerceAdminURL,
                                                          navigationTitle: HubMenuViewModel.Localization.woocommerceAdmin,
                                                          authenticated: viewModel.shouldAuthenticateAdminPage)) {
                showingWooCommerceAdmin = false
            }
        }
        .sheet(isPresented: $showingViewStore) {
            WebViewSheet(viewModel: WebViewSheetViewModel(url: viewModel.storeURL,
                                                          navigationTitle: HubMenuViewModel.Localization.viewStore,
                                                          authenticated: false)) {
                showingViewStore = false
            }
        }
        NavigationLink(destination: SettingsView(), isActive: $showSettings) {
            EmptyView()
        }.hidden()
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

    /// Handle navigation when tapping a list menu row.
    ///
    private func handleTap(menu: HubMenuItem) {
        ServiceLocator.analytics.track(.hubMenuOptionTapped, withProperties: [
            Constants.trackingOptionKey: menu.trackingOption
        ])

        switch type(of: menu).id {
        case HubMenuViewModel.Settings.id:
            ServiceLocator.analytics.track(.hubMenuSettingsTapped)
            showSettings = true
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
        case HubMenuViewModel.Subscriptions.id, HubMenuViewModel.Upgrades.id:
            viewModel.presentSubscriptions()
        default:
            break
        }
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
            case none
            case down
            case leading

            var asset: UIImage {
                switch self {
                case .none:
                    return UIImage()
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

        /// Optional badge text. Render next to `title`
        ///
        let badge: String?

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
                                .placeholder { Image(uiImage: .gravatarPlaceholderImage).resizable() }
                                .resizable()
                                .frame(width: HubMenu.Constants.avatarSize, height: HubMenu.Constants.avatarSize)
                                .clipShape(Circle())
                        }
                    }
                }


                // Title & Description
                VStack(alignment: .leading, spacing: HubMenu.Constants.topBarSpacing) {

                    AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.badgeSpacing(sizeCategory: sizeCategory)) {
                        Text(title)
                            .headlineStyle()
                            .accessibilityIdentifier(titleAccessibilityID ?? "")

                        if let badge, badge.isNotEmpty {
                            BadgeView(text: badge)
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

        /// Spacing for the badge view in the avatar row.
        ///
        static func badgeSpacing(sizeCategory: ContentSizeCategory) -> CGFloat {
            sizeCategory.isAccessibilityCategory ? .zero : 4
        }
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
