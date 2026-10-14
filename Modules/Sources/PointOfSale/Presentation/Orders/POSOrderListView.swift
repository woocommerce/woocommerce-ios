import SwiftUI
import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSOrder
import enum Yosemite.OrderPaymentMethod
import enum Yosemite.SearchDebounceStrategy

struct POSOrderListView: View {
    @Binding var isSearching: Bool
    @Binding var searchTerm: String
    let onOrderSelected: (POSOrder) -> Void
    let onClose: () -> Void

    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.siteTimezone) private var siteTimezone
    @StateObject private var infiniteScrollTriggerDeterminer = ThresholdInfiniteScrollTriggerDeterminer()

    private var ordersViewState: POSOrderListState {
        orderListModel.ordersController.ordersViewState
    }

    init(
        isSearching: Binding<Bool>,
        searchTerm: Binding<String>,
        onOrderSelected: @escaping (POSOrder) -> Void = { _ in },
        onClose: @escaping () -> Void
    ) {
        self._isSearching = isSearching
        self._searchTerm = searchTerm
        self.onOrderSelected = onOrderSelected
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                items: isSearching ? [] : [.init(
                    title: Localization.ordersTitle,
                    subtitle: nil,
                    isSelected: true,
                    isLoading: isSearching ? false : {
                        if case .loading(let orders) = ordersViewState {
                            return !orders.isEmpty
                        }
                        return false
                    }()
                )],
                backButtonConfiguration: isSearching ? nil : .init(state: .enabled, action: onClose, buttonIcon: "xmark"),
                trailingContent: {
                    if !isSearching && !ordersViewState.orders.isEmpty {
                        POSPageHeaderActionButton(
                            systemName: "magnifyingglass",
                            backgroundColor: .posSurface,
                            imageColor: .posOnSurface
                        ) {
                            analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListSearchButtonTapped())
                            setSearch(true)
                        }
                        .accessibilityLabel(Localization.searchButtonAccessibilityLabel)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity)
                                .animation(.easeInOut(duration: Constants.animationDuration).delay(Constants.animationDuration)),
                            removal: .opacity.animation(.easeInOut(duration: Constants.animationDuration * 0.5))
                        ))
                    }

                    if isSearching {
                        POSSearchField(
                            searchTerm: $searchTerm,
                            searchable: POSOrderSearchable(ordersController: orderListModel.ordersController),
                            onBack: { setSearch(false) }
                        )
                        .posSearchTextFieldUnfocusedBorderColor(.posOutlineVariant)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing))
                                .animation(.easeInOut(duration: Constants.animationDuration).delay(Constants.animationDuration * 0.5)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                                .animation(.easeInOut(duration: Constants.animationDuration))
                        ))
                        .onChange(of: searchTerm) { _, newValue in
                            if newValue.isEmpty {
                                orderListModel.ordersController.clearSearchOrders()
                            }
                        }
                    }
                }
            )
            .animation(.easeInOut(duration: Constants.animationDuration), value: isSearching)

            switch (ordersViewState, isSearching) {
            case (.empty, true):
                POSListEmptyView(
                    viewModel: POSOrderListEmptyViewModel(isSearching: true)
                ) {
                    Task { @MainActor in
                        await orderListModel.ordersController.loadOrders()
                    }
                }
            case (.error(let errorState), true):
                POSListErrorView(error: errorState, onAction: {
                    Task { @MainActor in
                        await orderListModel.ordersController.loadOrders()
                    }
                })
            default:
                listView
            }
        }
        .animation(.default, value: orderListModel.ordersController.ordersViewState.isEmpty)
        .background(Color.posSurfaceBright)
        .navigationBarHidden(true)
        .refreshable {
            analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListPullToRefresh())
            await orderListModel.ordersController.refreshOrders()
        }
        .posEdgeSwipeBackAction(isEnabled: isSearching, onBack: { setSearch(false) })
    }

    @ViewBuilder
    private var headerRows: some View {
        switch ordersViewState {
        case .inlineError(_, let errorState, .refresh):
            POSListInlineErrorView(errorState: errorState) {
                await orderListModel.ordersController.loadOrders()
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var listView: some View {
        ScrollViewReader { proxy in
            InfiniteScrollView(
                triggerDeterminer: infiniteScrollTriggerDeterminer,
                loadMore: {
                    guard case .loaded(_, let hasMoreItems) = ordersViewState, hasMoreItems else { return }
                    await orderListModel.ordersController.loadNextOrders()
                },
                content: {
                    let dateFormatter = DateFormatter.posDateAndTimeFormatter(timeZone: siteTimezone)
                    LazyVStack(spacing: POSSpacing.medium) {
                        headerRows
                            .id(Constants.scrollTopID)

                        let orders = ordersViewState.orders
                    ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                        Button(action: {
                            analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListRowTapped(
                                orderID: order.id,
                                orderStatus: order.status.rawValue,
                                listPosition: index,
                                orderCreatedDate: order.dateCreated,
                                siteTimezone: siteTimezone
                            ))
                            onOrderSelected(order)
                        }) {
                            POSOrderRowView(
                                order: order,
                                formattedDateCreated: dateFormatter.string(from: order.dateCreated),
                                isSelected: orderListModel.ordersController.selectedOrder?.id == order.id
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .animation(.default, value: orders.first?.id)

                    footerRows
                }
                .padding(.horizontal)
                .padding(.top, POSPadding.xSmall)
                .padding(.bottom, POSPadding.medium)
            }
            )
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: searchTerm) { _, _ in
                withAnimation {
                    proxy.scrollTo(Constants.scrollTopID, anchor: .top)
                }
            }
        }
    }

    @ViewBuilder
    private var footerRows: some View {
        switch ordersViewState {
        case .loading(let orders):
            if orders.isEmpty {
                ForEach(0..<8, id: \.self) { _ in
                    POSGhostOrderRowView()
                }
                .opacity(orders.isEmpty ? 1 : 0)
                .animation(.default, value: orders.isEmpty)
            } else {
                POSGhostOrderRowView()
            }
        case .inlineError(_, let errorState, .pagination):
            POSListInlineErrorView(errorState: errorState) {
                await orderListModel.ordersController.loadNextOrders()
            }
        default:
            EmptyView()
        }
    }
}

private struct POSOrderRowView: View {
    let order: POSOrder
    let formattedDateCreated: String
    let isSelected: Bool

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var minHeight: CGFloat {
        min(Constants.orderCardMinHeight * scale, Constants.maximumOrderCardHeight)
    }

    /// Suppress the selection border on compact widths — there is no adjacent detail pane on phone,
    /// so the border indicates nothing useful and looks like a stray visual artifact.
    private var showsSelectionBorder: Bool {
        isSelected && horizontalSizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            orderHeaderRow
            orderDetailsColumn
            Spacer().frame(height: POSSpacing.xSmall)
            POSOrderBadgeView(order: order)
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : minHeight, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .overlay {
            if showsSelectionBorder {
                RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value)
                    .stroke(Color.posOnSurface, lineWidth: 2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(POSOrderListView.Localization.orderRowAccessibilityHint)
    }

    private var accessibilityLabel: String {
        POSOrderListView.Localization.orderRowAccessibilityLabel(
            orderNumber: order.number,
            total: order.formattedTotal,
            date: formattedDateCreated,
            email: order.customerEmail,
            status: order.status.localizedName
        )
    }

    @ViewBuilder
    private var orderHeaderRow: some View {
        HStack(alignment: .center) {
            Text(POSOrderListView.Localization.orderTitle(order.number))
                .font(.posBodySmallBold())
                .foregroundStyle(Color.posOnSurface)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text(order.formattedTotal)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var orderDetailsColumn: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(formattedDateCreated)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .fixedSize(horizontal: false, vertical: true)

            if let customerEmail = order.customerEmail, customerEmail.isNotEmpty {
                Text(customerEmail)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct POSGhostOrderRowView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var minHeight: CGFloat {
        min(Constants.orderCardMinHeight * scale, Constants.maximumOrderCardHeight)
    }

    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        // Sample lengths keep the order number and amount 1x, the date 3x, and the status 2x.
        // Accessibility sizes use a shorter unit, so the number and amount stay apart.
        let unit = isAccessibilitySize ? 3 : 7
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            HStack {
                POSPlaceholderText(.redactedPlaceholder(length: unit), font: .posBodySmallBold())
                Spacer()
                POSPlaceholderText(.redactedPlaceholder(length: unit), font: .posBodySmallRegular())
            }
            POSPlaceholderText(.redactedPlaceholder(length: unit * 3), font: .posBodySmallRegular())
            // Reserves an email line, so the ghost matches the typical loaded row. Rows without an email are one line shorter.
            POSPlaceholderText(.redactedPlaceholder(length: 1), font: .posBodySmallRegular())
                .hidden()
            Spacer().frame(height: POSSpacing.xSmall)
            // Caption text is narrower, so the status needs a longer sample for 2x width.
            POSPlaceholderText(.redactedPlaceholder(length: unit * 16 / 7), font: .posCaptionRegular)
                .padding(.vertical, POSPadding.xSmall)
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(maxWidth: .infinity, minHeight: isAccessibilitySize ? nil : minHeight, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .geometryGroup()
        .accessibilityHidden(true)
    }
}

// MARK: - Search

private extension POSOrderListView {
    func setSearch(_ isSearchingValue: Bool) {
        if isSearchingValue {
            isSearching = true
        } else {
            searchTerm = ""
            isSearching = false
            // Clear search results and return to default orders
            orderListModel.ordersController.clearSearchOrders()
        }
    }
}

final class POSOrderSearchable: POSSearchable {
    private let ordersController: POSSearchingOrderListControllerProtocol

    init(ordersController: POSSearchingOrderListControllerProtocol) {
        self.ordersController = ordersController
    }

    var searchFieldPlaceholder: String {
        Localization.searchFieldPlaceholder
    }

    var searchHistory: [String] {
        []
    }

    var currentDebounceStrategy: SearchDebounceStrategy {
        // Use smart debouncing for order search to match original behavior:
        // don't debounce first keystroke to show loading immediately,
        // then debounce subsequent keystrokes while search is ongoing
        .smart()
    }

    var searchDebounceStrategy: SearchDebounceStrategy {
        // Orders use the same strategy for both modes
        currentDebounceStrategy
    }

    func performSearch(term: String) async {
        await ordersController.searchOrders(searchTerm: term)
    }

    func clearSearchResults() {
        ordersController.clearSearchOrders()
    }
}

// MARK: - Constants

private enum Constants {
    static let orderCardMinHeight: CGFloat = 112
    static let maximumOrderCardHeight: CGFloat = Constants.orderCardMinHeight * 2
    static let animationDuration: CGFloat = 0.2
    static let scrollTopID = "orderListViewTopID"
}

extension POSOrderListView {
    enum Localization {
        static let ordersTitle = NSLocalizedString(
            "pos.orderListView.ordersTitle",
            value: "Orders",
            comment: "Title at the header for the Orders view.")

        static func orderTitle(_ orderNumber: String) -> String {
            let format = NSLocalizedString(
                "pos.orderListView.orderTitle",
                value: "#%1$@",
                comment: "%1$@ is the order number. # symbol is shown as a prefix to a number."
            )
            return String(format: format, orderNumber)
        }

        static func orderRowAccessibilityLabel(orderNumber: String, total: String, date: String, email: String?, status: String) -> String {
            let baseFormat = NSLocalizedString(
                "pos.orderListView.orderRow.accessibilityLabel",
                value: "Order #%1$@, Total %2$@, %3$@, Status: %4$@",
                comment: "Accessibility label for order row. %1$@ is order number, %2$@ is total amount, %3$@ is date and time, "
                + "%4$@ is order status."
            )
            var label = String(format: baseFormat, orderNumber, total, date, status)

            if let email, email.isNotEmpty {
                let emailFormat = NSLocalizedString(
                    "pos.orderListView.orderRow.accessibilityLabel.email",
                    value: "Email: %1$@",
                    comment: "Email portion of order row accessibility label. %1$@ is customer email address."
                )
                label += ", " + String(format: emailFormat, email)
            }

            return label
        }

        static let orderRowAccessibilityHint = NSLocalizedString(
            "pos.orderListView.orderRow.accessibilityHint",
            value: "Tap to view order details",
            comment: "Accessibility hint for order row indicating the action when tapped."
        )

        static let searchButtonAccessibilityLabel = NSLocalizedString(
            "pos.orderListView.searchButton.accessibilityLabel",
            value: "Search orders",
            comment: "Accessibility label for the search button in orders list."
        )
    }
}

private enum Localization {
    static let searchFieldPlaceholder = NSLocalizedString(
        "pos.orderListView.searchFieldPlaceholder",
        value: "Search orders",
        comment: "Placeholder for a search field in the Orders view."
    )
}

#if DEBUG
#Preview("List") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(isSearching: .constant(false), searchTerm: .constant(""), onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(state: POSPreviewHelpers.loadedState()))
    } detail: {
        Text("Detail View")
    }
    .navigationSplitViewStyle(.balanced)
}

#Preview("Empty State in Search") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(isSearching: .constant(true), searchTerm: .constant(""), onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
    } detail: {
        Text("Detail View")
    }
}

#Preview("Error State in Search") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(isSearching: .constant(true), searchTerm: .constant(""), onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .error(.errorOnLoadingOrders())))
    } detail: {
        Text("Detail View")
    }
}

#Preview("Loading State") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(isSearching: .constant(false), searchTerm: .constant(""), onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .loading([])))
    } detail: {
        Text("Detail View")
    }
}

#Preview("Inline Error - Refresh") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(isSearching: .constant(false), searchTerm: .constant(""), onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(
                state: .inlineError(POSPreviewHelpers.makePreviewOrders(),
                                   error: .errorOnLoadingOrders(),
                                   context: .refresh)
            ))
    } detail: {
        Text("Detail View")
    }
}

#Preview("Inline Error - Pagination") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(isSearching: .constant(false), searchTerm: .constant(""), onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(
                state: .inlineError(POSPreviewHelpers.makePreviewOrders(),
                                   error: .errorOnLoadingOrdersNextPage(),
                                   context: .pagination)
            ))
    } detail: {
        Text("Detail View")
    }
}

#Preview("Search Empty State") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(isSearching: .constant(true), searchTerm: .constant(""), onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
    } detail: {
        Text("Detail View")
    }
}

#endif
