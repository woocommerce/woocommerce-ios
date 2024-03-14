import SwiftUI
import Kingfisher
import Yosemite

/// This view will be embedded inside the `HubMenuViewController`
/// and will be the entry point of the `Menu` Tab.
///
struct HubMenu: View {
    /// Set from the hosting controller to handle switching store.
    var switchStoreHandler: () -> Void = {}

    @ObservedObject private var iO = Inject.observer

    @ObservedObject private var viewModel: HubMenuViewModel
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init(viewModel: HubMenuViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility, sidebar: {
            sideBar
        }, detail: {
            NavigationStack {
                Group {
                    if let id = viewModel.selectedMenuID {
                        detailView(menuID: id)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        })
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            viewModel.setupMenuElements()
            if horizontalSizeClass == .regular {
                viewModel.selectedMenuID = HubMenuViewModel.Settings.id
            }
        }
    }
}

// MARK: SubViews
private extension HubMenu {
    var sideBar: some View {
        List(selection: $viewModel.selectedMenuID) {
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

            // Settings Section
            Section(Localization.settings) {
                ForEach(viewModel.settingsElements, id: \.id) { menu in
                    Button(action: {
                        viewModel.trackSelection(menu: menu)
                    }, label: {
                        Row(title: menu.title,
                            titleBadge: nil,
                            iconBadge: menu.iconBadge,
                            description: menu.description,
                            icon: .local(menu.icon),
                            chevron: .leading)
                        .foregroundColor(Color(menu.iconColor))
                    })
                    .accessibilityIdentifier(menu.accessibilityIdentifier)
                    .overlay {
                        NavigationLink(value: menu.id) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                }
            }

            // General Section
            Section(Localization.general) {
                ForEach(viewModel.generalElements, id: \.id) { menu in
                    Button(action: {
                        viewModel.trackSelection(menu: menu)
                    }, label: {
                        Row(title: menu.title,
                            titleBadge: nil,
                            iconBadge: menu.iconBadge,
                            description: menu.description,
                            icon: .local(menu.icon),
                            chevron: .leading)
                        .foregroundColor(Color(menu.iconColor))
                    })
                    .accessibilityIdentifier(menu.accessibilityIdentifier)
                    .overlay {
                        NavigationLink(value: menu.id) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color(.listBackground))
        .toolbar(.hidden, for: .navigationBar)
        .accentColor(Color(.listSelectedBackground))
    }

    @ViewBuilder
    func detailView(menuID: String) -> some View {
        switch menuID {
        case HubMenuViewModel.Settings.id:
            SettingsView(showingPrivacySettings: $viewModel.showingPrivacySettings)
        case HubMenuViewModel.Payments.id:
            InPersonPaymentsMenu(viewModel: viewModel.inPersonPaymentsMenuViewModel)
        case HubMenuViewModel.Blaze.id:
            BlazeCampaignListView(viewModel: .init(siteID: viewModel.siteID))
        case HubMenuViewModel.WoocommerceAdmin.id:
            webView(url: viewModel.woocommerceAdminURL,
                    title: HubMenuViewModel.Localization.woocommerceAdmin,
                    shouldAuthenticate: viewModel.shouldAuthenticateAdminPage)
        case HubMenuViewModel.ViewStore.id:
            webView(url: viewModel.storeURL,
                    title: HubMenuViewModel.Localization.viewStore,
                    shouldAuthenticate: false)
        case HubMenuViewModel.Inbox.id:
            Inbox(viewModel: .init(siteID: viewModel.siteID))
        case HubMenuViewModel.Reviews.id:
            ReviewsView(siteID: viewModel.siteID,
                        productReviewFromNoteParcel: viewModel.productReviewFromNoteParcel,
                        showingReviewDetail: $viewModel.showingReviewDetail)
        case HubMenuViewModel.Coupons.id:
            EnhancedCouponListView(siteID: viewModel.siteID,
                                   viewModel: CouponListViewModel(siteID: viewModel.siteID))
        case HubMenuViewModel.InAppPurchases.id:
            InAppPurchasesDebugView()
        case HubMenuViewModel.Subscriptions.id:
            SubscriptionsView(viewModel: .init())
        default:
            fatalError("🚨 Unsupported menu item")
        }
    }

    @ViewBuilder
    func webView(url: URL, title: String, shouldAuthenticate: Bool) -> some View {
        Group {
            if shouldAuthenticate {
                AuthenticatedWebView(isPresented: .constant(true),
                                     url: url)
            } else {
                WebView(isPresented: .constant(true),
                        url: url)
            }
        }
        .navigationTitle(title)
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

            var asset: UIImage {
                switch self {
                case .none:
                    return UIImage()
                case .down:
                    return .chevronDownImage
                case .leading:
                    return .chevronImage
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
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                /// In iOS 16, List row separator insets automatically and aligns to the text.
                /// Returning 0 makes the separator start from the leading edge.
                return 0
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
