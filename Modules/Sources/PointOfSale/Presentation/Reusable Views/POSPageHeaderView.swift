import SwiftUI

/// Configuration for the back button in the header.
struct POSPageHeaderBackButtonConfiguration {
    enum State {
        case enabled
        case shimmering
        case disabled
    }

    let state: State
    let action: () -> Void
    let buttonIcon: String?
    let accessibilityIdentifier: String?

    init(state: State, action: @escaping () -> Void, buttonIcon: String? = nil, accessibilityIdentifier: String? = nil) {
        self.state = state
        self.action = action
        self.buttonIcon = buttonIcon
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

struct POSPageHeaderItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let isLoading: Bool
    let action: (() -> Void)?

    init(title: String, subtitle: String? = nil, isSelected: Bool, isLoading: Bool = false, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.isLoading = isLoading
        self.action = action
    }
}

/// A header view for POS pages.
/// Compact headers keep the back button, title, and actions in one navigation row.
/// Use `subtitle` or `bottomContent` for information below that row; callers need no row-height adjustments.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-450_24951
struct POSPageHeaderView<LeadingContent: View, TrailingContent: View, BottomContent: View>: View {
    private let items: [POSPageHeaderItem]
    private let backButtonConfiguration: POSPageHeaderBackButtonConfiguration?
    private let leadingContent: LeadingContent
    private let trailingContent: TrailingContent
    private let bottomContent: BottomContent
    @Environment(\.posHeaderBackButtonConfiguration) private var environmentBackButtonConfiguration
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posHeaderTopPadding) private var topPadding

    private var effectiveBackButtonConfiguration: POSPageHeaderBackButtonConfiguration? {
        environmentBackButtonConfiguration ?? backButtonConfiguration
    }

    private var hStackAlignment: VerticalAlignment {
        if horizontalSizeClass == .compact {
            return .top
        }
        return items.first?.subtitle == nil ? .center: .firstTextBaseline
    }

    private var showsBackButton: Bool {
        effectiveBackButtonConfiguration != nil
    }

    /// Whether the header has selectable titles, such as Products and Coupons.
    private var hasSelectableTitles: Bool {
        items.count > 1
    }

    private var navigationRowMinHeight: CGFloat? {
        horizontalSizeClass == .compact ? POSHeaderLayoutConstants.minHeight : nil
    }

    init(
        title: String,
        subtitle: String? = nil,
        isLoading: Bool = false,
        backButtonConfiguration: POSPageHeaderBackButtonConfiguration? = nil,
        @ViewBuilder leadingContent: () -> LeadingContent = { EmptyView() },
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() },
        @ViewBuilder bottomContent: () -> BottomContent = { EmptyView() }
    ) {
        self.items = [.init(title: title, subtitle: subtitle, isSelected: true, isLoading: isLoading)]
        self.backButtonConfiguration = backButtonConfiguration
        self.leadingContent = leadingContent()
        self.trailingContent = trailingContent()
        self.bottomContent = bottomContent()
    }

    init(
        items: [POSPageHeaderItem],
        backButtonConfiguration: POSPageHeaderBackButtonConfiguration? = nil,
        @ViewBuilder leadingContent: () -> LeadingContent = { EmptyView() },
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() },
        @ViewBuilder bottomContent: () -> BottomContent = { EmptyView() }
    ) {
        self.items = items
        self.backButtonConfiguration = backButtonConfiguration
        self.leadingContent = leadingContent()
        self.trailingContent = trailingContent()
        self.bottomContent = bottomContent()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: hStackAlignment, spacing: Constants.horizontalSpacing) {
                leadingContent

                if shouldShowItemsContent {
                    itemsContent
                }

                if items.isNotEmpty {
                    Spacer(minLength: 0)
                }

                trailingContent
                    .frame(minHeight: navigationRowMinHeight)
            }

            bottomContent
        }
        .frame(minHeight: POSHeaderLayoutConstants.minHeight)
        .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
        .padding(.top, topPadding ?? (horizontalSizeClass == .compact ? POSPadding.medium : POSHeaderLayoutConstants.sectionVerticalPadding))
        .padding(.bottom, POSHeaderLayoutConstants.sectionVerticalPadding)
    }

    /// Several selectable titles (Products / Coupons) keep the horizontal scroll fallback, so a
    /// long translation can never hide the title the merchant needs to tap. A single title does
    /// not scroll: scrolling a heading is undiscoverable, and the scroll view clips it with no
    /// ellipsis. It scales modestly instead — see `titleText`.
    @ViewBuilder
    private var itemsContent: some View {
        if hasSelectableTitles {
            ViewThatFits(in: .horizontal) {
                itemsRow

                ScrollView(.horizontal, showsIndicators: false) {
                    itemsRow
                }
            }
        } else {
            itemsRow
        }
    }

    private var itemsRow: some View {
        VStack(alignment: .leading, spacing: Constants.titleSubtitleSpacing) {
            HStack(alignment: hStackAlignment, spacing: Constants.horizontalSpacing) {
                if showsBackButton {
                    backButton
                        .frame(minHeight: navigationRowMinHeight)
                }
                ForEach(0..<items.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: Constants.titleSubtitleSpacing) {
                        HStack(spacing: POSSpacing.small) {
                            if items[index].title.isNotEmpty {
                                Button(action: {
                                    items[index].action?()
                                }) {
                                    titleText(items[index].title, isSelected: items[index].isSelected)
                                }
                                .disabled(items[index].isSelected)
                                .accessibilityElement()
                                .accessibilityAddTraits(items.count == 1 ? .isHeader : [.isHeader, .isButton])
                                .accessibilityLabel(items[index].title)
                            }

                            if items[index].isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.7)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        // Keep subtitles below the navigation row instead of moving its title and back button.
                        .frame(minHeight: navigationRowMinHeight)

                        if let subtitle = items[index].subtitle {
                            subtitleText(subtitle)
                        }
                    }
                }
            }
        }
    }

    private func titleText(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.posHeadingBold)
            // Keep words intact. Single titles can shrink by up to 20%; selectable
            // titles keep their natural width for the horizontal scroll fallback.
            .lineLimit(1)
            .minimumScaleFactor(hasSelectableTitles ? 1 : 0.8)
            .allowsTightening(!hasSelectableTitles)
            .fixedSize(horizontal: hasSelectableTitles, vertical: false)
            .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
            .foregroundColor(isSelected ? .posOnSurface : .posOnSurfaceVariantLowest)
    }

    private func subtitleText(_ subtitle: String) -> some View {
        Text(subtitle)
            .font(.posBodyLargeRegular())
            // Follows the title: without the scroll fallback a single-title header would
            // otherwise clip a long subtitle, such as the date and email on order details.
            .lineLimit(hasSelectableTitles ? 1 : Constants.singleTitleLineLimit)
            .fixedSize(horizontal: hasSelectableTitles, vertical: false)
            .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
            .foregroundColor(.posOnSurface)
    }

    private var shouldShowItemsContent: Bool {
        items.isNotEmpty || showsBackButton
    }

    @ViewBuilder
    private var backButton: some View {
        if let configuration = effectiveBackButtonConfiguration {
            POSPageHeaderBackButton(configuration: configuration)
        }
    }
}

private enum Constants {
    static let horizontalSpacing: CGFloat = POSSpacing.medium
    static let titleSubtitleSpacing: CGFloat = POSSpacing.xSmall
    /// Two lines hold the longest translated POS headings on a phone without the header
    /// taking over the screen.
    static let singleTitleLineLimit: Int = 2
}

struct POSHeaderBackButtonConfigurationKey: EnvironmentKey {
    static var defaultValue: POSPageHeaderBackButtonConfiguration? { nil }
}

struct POSHeaderBackButtonIconKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

struct POSHeaderBackButtonPaddingKey: EnvironmentKey {
    /// Icon container is 48x48, chevron icon width is 24px. Therefore, adding a horizontal padding (48-24)/2 = 12.
    static let defaultValue: CGFloat = POSPadding.large / 2
}

extension EnvironmentValues {
    var posHeaderBackButtonConfiguration: POSPageHeaderBackButtonConfiguration? {
        get { self[POSHeaderBackButtonConfigurationKey.self] }
        set { self[POSHeaderBackButtonConfigurationKey.self] = newValue }
    }

    var posHeaderBackButtonIcon: String? {
        get { self[POSHeaderBackButtonIconKey.self] }
        set { self[POSHeaderBackButtonIconKey.self] = newValue }
    }

    var posHeaderBackButtonPadding: CGFloat {
        get { self[POSHeaderBackButtonPaddingKey.self] }
        set { self[POSHeaderBackButtonPaddingKey.self] = newValue }
    }
}

// MARK: - View Extensions for Easy Usage

extension View {
    /// Sets the back button icon for all POSPageHeaderView instances in the view hierarchy.
    /// - Parameter systemName: The system name for the back button icon (e.g., "xmark")
    /// - Returns: A view with the icon environment value set
    func posHeaderBackButtonIcon(systemName: String) -> some View {
        environment(\.posHeaderBackButtonIcon, systemName)
    }

    /// Sets the back button horizontal padding for all POSPageHeaderView instances in the view hierarchy.
    /// - Parameter padding: The horizontal padding value
    /// - Returns: A view with the padding environment value set
    func posHeaderBackButtonPadding(_ padding: CGFloat) -> some View {
        environment(\.posHeaderBackButtonPadding, padding)
    }
}

// MARK: - Previews

#Preview {
    @Previewable @State var isProductsSelected: Bool = true

    VStack(spacing: 20) {
        // Header without back button.
        POSPageHeaderView(
            title: "Products",
            trailingContent: {
                Button(action: {}) {
                    Text(Image(systemName: "info.circle"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurface)
            })

        // Basic header with back button.
        POSPageHeaderView(
            title: "Variation",
            backButtonConfiguration: .init(state: .enabled, action: {})
        )

        // Header with shimmering back button.
        POSPageHeaderView(
            title: "Cart",
            backButtonConfiguration: .init(state: .shimmering, action: {})
        )

        // Header with trailing content.
        POSPageHeaderView(
            title: "Products",
            backButtonConfiguration: .init(state: .enabled, action: {}),
            trailingContent: {
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Text(Image(systemName: "info.circle"))
                            .font(.posButtonSymbolLarge)
                    }
                    .foregroundColor(.posOnSurface)

                    Button(action: {}) {
                        Text(Image(systemName: "trash"))
                            .font(.posButtonSymbolLarge)
                    }
                    .foregroundColor(.posOnSurface)
                }
            })

        // Header with subtitle.
        POSPageHeaderView(
            title: "Cash payment",
            subtitle: "Total: $100.00",
            backButtonConfiguration: .init(state: .enabled, action: {})
        )

        // Header with loading indicator.
        POSPageHeaderView(
            title: "Orders",
            isLoading: true,
            backButtonConfiguration: .init(state: .enabled, action: {})
        )

        // Header with subtitle and disabled back button.
        POSPageHeaderView(
            title: "Cash payment",
            subtitle: "Total: $100.00",
            backButtonConfiguration: .init(state: .disabled, action: {})
        )

        // Header with everything.
        POSPageHeaderView(
            title: "Title",
            subtitle: "Subtitle",
            backButtonConfiguration: .init(state: .enabled, action: {}),
            trailingContent: {
                Button(action: {}) {
                    Text(Image(systemName: "info.circle"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurface)
            },
            bottomContent: {
                Text("Bottom content")
            })

        // Header with two items and trailing content.
        POSPageHeaderView(
            items: [
                .init(title: "Products", isSelected: isProductsSelected) { isProductsSelected.toggle() },
                .init(title: "Coupons", isSelected: !isProductsSelected) { isProductsSelected.toggle() }
            ],
            trailingContent: {
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Text(Image(systemName: "plus"))
                            .font(.posButtonSymbolLarge)
                    }
                    .foregroundColor(.posOnSurface)

                    Button(action: {}) {
                        Text(Image(systemName: "magnifyingglass"))
                            .font(.posButtonSymbolLarge)
                    }
                    .foregroundColor(.posOnSurface)
                }
            })

        // Header with bottom content.
        POSPageHeaderView(
            title: "Order Details",
            subtitle: "Created: 2024-01-01 • customer@example.com",
            backButtonConfiguration: .init(state: .enabled, action: {}),
            trailingContent: {
                Text("Completed")
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posSuccess)
                    .padding(.horizontal, POSPadding.small)
                    .padding(.vertical, POSPadding.xSmall)
                    .background(Color.posSuccess.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            },
            bottomContent: {
                HStack {
                    Button("Print Receipt") {}
                        .buttonStyle(.bordered)
                    Spacer()
                    Button("Refund") {}
                        .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
                .padding(.top, POSSpacing.medium)
            }
        )
    }
    .background(Color.posSurface)
}

private struct POSHeaderTopPaddingKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    var posHeaderTopPadding: CGFloat? {
        get { self[POSHeaderTopPaddingKey.self] }
        set { self[POSHeaderTopPaddingKey.self] = newValue }
    }
}
