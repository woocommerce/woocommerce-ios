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

    @State private var animationTime: TimeInterval = 0

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
                    startShaderAnimation()
                }
        }
        .snowEffect()
    }

    /// Handle navigation when tapping a list menu row.
    ///
    private func handleTap(menu: HubMenuItem) {
        viewModel.trackMenuItemTapEvent(menu: menu)

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

    private func startShaderAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
            animationTime += 1/60.0
        }
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
                        chevronAccessibilityID: "switch-store-button",
                        animationTime: animationTime)
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
                chevron: chevron,
                animationTime: animationTime)
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
            case .subscriptions:
                SubscriptionsView(viewModel: .init())
            case .customers:
                CustomersListView(viewModel: .init(siteID: viewModel.siteID))
            case .reviewDetails(let parcel):
                reviewDetailView(parcel: parcel)
            case .blazeCampaignDetails(let campaignID):
                BlazeCampaignListHostingControllerRepresentable(siteID: viewModel.siteID, selectedCampaignID: campaignID)
            case .blazeCampaignCreation:
                BlazeCampaignListHostingControllerRepresentable(siteID: viewModel.siteID, startsCampaignCreationOnAppear: true)
            case .aiSettings:
                AISettingsView()
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

        var animationTime: TimeInterval = 0

        @Environment(\.sizeCategory) private var sizeCategory
        @ScaledMetric private var scale: CGFloat = 1.0

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
                                            .applyAnimatedRecolorShader(newColor: .blue, animationTime: animationTime)
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
                    .aspectRatio(contentMode: .fit)
                    .applyRecolorShader()
                    .frame(width: HubMenu.Constants.chevronSize * scale, height: HubMenu.Constants.chevronSize * scale)
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
            "hubMenu.reviewsList",
            value: "Reviews",
            comment: "Title of the view containing Reviews list"
        )
        static let coupons = NSLocalizedString(
            "hubMenu.couponsList",
            value: "Coupons",
            comment: "Title of the view containing Coupons list"
        )
    }
}

private extension View {
    /// Applies recolor shader effect for testing Metal functionality
    /// Only available on iOS 17+ and gracefully falls back on older versions
    @ViewBuilder
    func applyRecolorShader(newColor: Color = .purple, blendAmount: Float = 0.5) -> some View {
        if #available(iOS 17.0, *) {
            self.colorEffect(
                Shader(
                    function: ShaderFunction(
                        library: .default,
                        name: "recolor"
                    ),
                    arguments: [
                        .color(newColor),
                        .float(blendAmount)
                    ]
                )
            )
        } else {
            self
        }
    }

    /// Applies animated recolor shader effect with pulsing animation
    /// Only available on iOS 17+ and gracefully falls back on older versions
    @ViewBuilder
    func applyAnimatedRecolorShader(newColor: Color = .orange, animationTime: TimeInterval) -> some View {
        if #available(iOS 17.0, *) {
            self.colorEffect(
                Shader(
                    function: ShaderFunction(
                        library: .default,
                        name: "recolorAnimated"
                    ),
                    arguments: [
                        .color(newColor),
                        .float(Float(animationTime))
                    ]
                )
            )
        } else {
            self
        }
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

struct ParticleEffect {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var life: TimeInterval
    var maxLife: TimeInterval
    var size: CGFloat
    var opacity: Double
    var color: Color

    static func snowflake(startX: CGFloat, canvasHeight: CGFloat) -> ParticleEffect {
        return ParticleEffect(
            position: CGPoint(x: startX, y: -10), // Start above screen
            velocity: CGVector(
                dx: Double.random(in: -20...20), // Slight horizontal drift
                dy: Double.random(in: 30...80)   // Falling speed
            ),
            life: 0,
            maxLife: TimeInterval.random(in: 8...15), // 8-15 seconds lifetime
            size: CGFloat.random(in: 3...8),          // Various sizes
            opacity: Double.random(in: 0.3...0.8),   // Semi-transparent
            color: .white
        )
    }

    mutating func update(deltaTime: TimeInterval, canvasSize: CGSize) {
        // Update position based on velocity
        position.x += velocity.dx * deltaTime
        position.y += velocity.dy * deltaTime

        // Add some wind effect (sine wave horizontal movement)
        let windStrength = sin(life * 2.0) * 10.0
        position.x += windStrength * deltaTime

        // Update life
        life += deltaTime

        // Fade out as particle ages
        let lifeRatio = life / maxLife
        opacity = max(0, 1.0 - lifeRatio)
    }

    /// Check if particle is still alive and visible
    var isAlive: Bool {
        return life < maxLife &&
               position.y < 1000 && // Don't let particles fall too far
               opacity > 0.01
    }
}

final class ParticleEffectService: ObservableObject {
    @Published private var particles: [ParticleEffect] = []
    private var lastUpdateTime: TimeInterval = 0
    private var particleSpawnTimer: TimeInterval = 0

    /// Snow effect configuration
    private let snowConfig = SnowConfig(
        spawnRate: 2.0,        // Particles per second
        maxParticles: 150      // Maximum particles on screen
    )

    private struct SnowConfig {
        let spawnRate: Double
        let maxParticles: Int
    }

    func addParticles(_ newParticles: [ParticleEffect]) {
        DispatchQueue.main.async {
            self.particles.append(contentsOf: newParticles)
            
            // Limit total particles (performance)
            if self.particles.count > self.snowConfig.maxParticles {
                self.particles = Array(self.particles.suffix(self.snowConfig.maxParticles))
            }
        }
    }

    func getActiveParticles(currentTime: TimeInterval, canvasSize: CGSize) -> [ParticleEffect] {
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        var updatedParticles = particles

        for i in updatedParticles.indices.reversed() {
            updatedParticles[i].update(deltaTime: deltaTime, canvasSize: canvasSize)
            // Remove expired particles
            if !updatedParticles[i].isAlive {
                updatedParticles.remove(at: i)
            }
        }

        spawnSnowParticles(deltaTime: deltaTime, canvasSize: canvasSize, particles: &updatedParticles)

        // Update the published property asynchronously to avoid view update conflicts
        DispatchQueue.main.async {
            self.particles = updatedParticles
        }

        return updatedParticles
    }

    private func spawnSnowParticles(deltaTime: TimeInterval, canvasSize: CGSize, particles: inout [ParticleEffect]) {
        guard canvasSize.width > 0 && canvasSize.height > 0 else { return }

        particleSpawnTimer += deltaTime

        // Check if it's time to start spawning
        let spawnInterval = 1.0 / snowConfig.spawnRate

        while particleSpawnTimer >= spawnInterval && particles.count < snowConfig.maxParticles {
            let startX = CGFloat.random(in: -50...(canvasSize.width + 50)) // Start slightly outside the view
            let snowflake = ParticleEffect.snowflake(startX: startX, canvasHeight: canvasSize.height)

            particles.append(snowflake)
            particleSpawnTimer -= spawnInterval
        }
    }

    func clearAllParticles() {
        DispatchQueue.main.async {
            self.particles.removeAll()
            self.particleSpawnTimer = 0
            self.lastUpdateTime = 0
        }
    }
    
    var particleCount: Int {
        particles.count
    }
}

struct ParticleOverlayView<Content: View>: View {
    let content: Content
    @StateObject private var particleService = ParticleEffectService()

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .overlay {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let currentTime = timeline.date.timeIntervalSince1970
                        let activeParticles = particleService.getActiveParticles(
                            currentTime: currentTime,
                            canvasSize: size
                        )

                        for particle in activeParticles {
                            drawParticle(particle, in: context)
                        }
                    }
                }
                .allowsHitTesting(false) // So particles don't interfere with UI interactions
            }
    }

    private func drawParticle(_ particle: ParticleEffect, in context: GraphicsContext) {
        let center = particle.position
        let radius = particle.size / 2

        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: particle.size,
            height: particle.size
        )

        var particleContext = context
        particleContext.opacity = particle.opacity
        particleContext.fill(
            Path(ellipseIn: rect),
            with: .color(particle.color)
        )

        if particle.color == .white {
            let glowRect = CGRect(
                x: center.x - radius * 1.5,
                y: center.y - radius * 1.5,
                width: particle.size * 1.5,
                height: particle.size * 1.5
            )
            var glowContext = context
            glowContext.opacity = particle.opacity * 0.3
            glowContext.fill(
                Path(ellipseIn: glowRect),
                with: .color(.white)
            )
        }
    }
}

extension View {
    func snowEffect() -> some View {
        if Self.isHolidaySeason() {
            return AnyView(ParticleOverlayView {
                self
            })
        } else {
            return AnyView(self)
        }
    }

    /// For now set to Dec 25-31 because why not
    private static func isHolidaySeason() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)

        return month == 12 && day >= 25
    }
}
