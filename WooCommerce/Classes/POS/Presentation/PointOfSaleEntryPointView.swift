import SwiftUI
import protocol Yosemite.POSSearchHistoryProviding
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol

@available(iOS 17.0, *)
struct PointOfSaleEntryPointView: View {
    @State private var posModel: PointOfSaleAggregateModel?
    @StateObject private var posModalManager = POSModalManager()
    @StateObject private var posSheetManager = POSSheetManager()
    @StateObject private var posFullscreenOverlayManager = POSFullscreenOverlayManager()
    @State private var posEntryPointController: POSEntryPointController
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)
    private let itemsController: PointOfSaleItemsControllerProtocol
    private let purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let couponsController: PointOfSaleCouponsControllerProtocol
    private let couponsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderController: PointOfSaleOrderControllerProtocol
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    private let searchHistoryService: POSSearchHistoryProviding
    private let popularPurchasableItemsController: PointOfSaleItemsControllerProtocol
    private let barcodeScanService: PointOfSaleBarcodeScanServiceProtocol

    init(itemsController: PointOfSaleItemsControllerProtocol,
         purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         couponsController: PointOfSaleCouponsControllerProtocol,
         couponsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         searchHistoryService: POSSearchHistoryProviding,
         popularPurchasableItemsController: PointOfSaleItemsControllerProtocol,
         barcodeScanService: PointOfSaleBarcodeScanServiceProtocol,
         posEligibilityChecker: POSEntryPointEligibilityCheckerProtocol) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        self.itemsController = itemsController
        self.purchasableItemsSearchController = purchasableItemsSearchController
        self.couponsController = couponsController
        self.couponsSearchController = couponsSearchController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderController = orderController
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.searchHistoryService = searchHistoryService
        self.popularPurchasableItemsController = popularPurchasableItemsController
        self.barcodeScanService = barcodeScanService
        self.posEntryPointController = POSEntryPointController(eligibilityChecker: posEligibilityChecker)
    }

    var body: some View {
        Group {
            if let posModel {
                PointOfSaleDashboardView()
                    .environment(posModel)
            } else {
                PointOfSaleLoadingView()
            }
        }
        .task {
            // We create the posModel in a task, not init, to avoid creating multiple copies during the view's lifecycle.
            // Confusingly, init can be called more than once, but `task` matches the lifecycle.
            // See https://developer.apple.com/documentation/swiftui/state#Store-observable-objects for details.
            posModel = PointOfSaleAggregateModel(
                entryPointController: posEntryPointController,
                itemsController: itemsController,
                purchasableItemsSearchController: purchasableItemsSearchController,
                couponsController: couponsController,
                couponsSearchController: couponsSearchController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
                searchHistoryService: searchHistoryService,
                popularPurchasableItemsController: popularPurchasableItemsController,
                barcodeScanService: barcodeScanService)
        }
        .environmentObject(posModalManager)
        .environmentObject(posSheetManager)
        .environmentObject(posFullscreenOverlayManager)
        .injectKeyboardObserver()
        .onAppear {
            onPointOfSaleModeActiveStateChange(true)
        }
        .onDisappear {
            onPointOfSaleModeActiveStateChange(false)
            posModalManager.onDisappear()
            posModel?.pointOfSaleClosed()
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    PointOfSaleEntryPointView(itemsController: PointOfSalePreviewItemsController(),
                              purchasableItemsSearchController: PointOfSalePreviewItemsController(),
                              couponsController: PointOfSalePreviewCouponsController(),
                              couponsSearchController: PointOfSalePreviewCouponsController(),
                              onPointOfSaleModeActiveStateChange: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderController: PointOfSalePreviewOrderController(),
                              collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentPreviewAnalytics(),
                              searchHistoryService: PointOfSalePreviewHistoryService(),
                              popularPurchasableItemsController: PointOfSalePreviewItemsController(),
                              barcodeScanService: PointOfSalePreviewBarcodeScanService(),
                              posEligibilityChecker: POSTabEligibilityChecker(siteID: 0))
}

#endif

//
// POSFullscreenOverlay - Wraps SwiftUI .fullScreenCover() with modal coordination across presentation boundaries.
//
// Usage: Replace .fullScreenCover() with .posFullscreenOverlay() and inject POSFullscreenOverlayManager at the POS root.
// Modal coordination allows fullscreen content to present modals via the parent's modal system.
//

// MARK: - Fullscreen Overlay Coordination Infrastructure

final class POSFullscreenOverlayManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    private var presentedOverlays: Set<String> = []
    
    // Modal coordination - track parent modal manager for bridging
    private(set) var parentModalManager: POSModalManager?
    
    func registerOverlayPresented(id: String, modalManager: POSModalManager) {
        presentedOverlays.insert(id)
        parentModalManager = modalManager
        updateState()
    }
    
    func registerOverlayDismissed(id: String) {
        presentedOverlays.remove(id)
        if presentedOverlays.isEmpty {
            parentModalManager = nil
        }
        updateState()
    }
    
    private func updateState() {
        isPresented = !presentedOverlays.isEmpty
    }
}

// MARK: - Environment Key for Parent Modal Manager Bridging

struct ParentModalManagerKey: EnvironmentKey {
    static let defaultValue: POSModalManager? = nil
}

extension EnvironmentValues {
    var parentModalManager: POSModalManager? {
        get { self[ParentModalManagerKey.self] }
        set { self[ParentModalManagerKey.self] = newValue }
    }
}

// MARK: - Fullscreen Overlay Modifiers
@available(iOS 17.0, *)
struct POSFullscreenOverlayViewModifier<OverlayContent: View>: ViewModifier {
    @EnvironmentObject var overlayManager: POSFullscreenOverlayManager
    @EnvironmentObject var modalManager: POSModalManager
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let overlayContent: () -> OverlayContent
    
    @State private var overlayId = UUID().uuidString
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss) {
                overlayContent()
                    // Bridge parent modal system to fullscreen content
                    .environmentObject(modalManager)
                    .environment(\.parentModalManager, modalManager)
            }
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    overlayManager.registerOverlayPresented(id: overlayId, modalManager: modalManager)
                } else {
                    overlayManager.registerOverlayDismissed(id: overlayId)
                }
            }
    }
}
@available(iOS 17.0, *)
struct POSFullscreenOverlayViewModifierForItem<Item: Identifiable & Equatable, OverlayContent: View>: ViewModifier {
    @EnvironmentObject var overlayManager: POSFullscreenOverlayManager
    @EnvironmentObject var modalManager: POSModalManager
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    let overlayContent: (Item) -> OverlayContent
    
    @State private var overlayId = UUID().uuidString
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $item, onDismiss: onDismiss) { item in
                overlayContent(item)
                    // Bridge parent modal system to fullscreen content
                    .environmentObject(modalManager)
                    .environment(\.parentModalManager, modalManager)
            }
            .onChange(of: item) { _, newItem in
                let newValue = newItem != nil
                if newValue {
                    overlayManager.registerOverlayPresented(id: overlayId, modalManager: modalManager)
                } else {
                    overlayManager.registerOverlayDismissed(id: overlayId)
                }
            }
    }
}

// MARK: - View Extensions
@available(iOS 17.0, *)
extension View {
    /// Shows a fullscreen overlay with automatic modal coordination.
    ///
    /// This works exactly like the native .fullScreenCover() modifier but automatically
    /// bridges the parent's modal system to the fullscreen content, enabling modals
    /// to be presented above the fullscreen cover.
    ///
    /// This will only work in a view hierarchy containing both `POSFullscreenOverlayManager`
    /// and `POSModalManager` environment objects.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control when the fullscreen overlay is shown.
    ///   - onDismiss: Optional closure executed when the overlay is dismissed.
    ///   - content: Content to show in the fullscreen overlay
    /// - Returns: a modified view which can show the fullscreen overlay content, with modal coordination.
    func posFullscreenOverlay<OverlayContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> OverlayContent
    ) -> some View {
        self.modifier(
            POSFullscreenOverlayViewModifier(
                isPresented: isPresented,
                onDismiss: onDismiss,
                overlayContent: content
            )
        )
    }
    
    /// Shows a fullscreen overlay with automatic modal coordination.
    ///
    /// This works exactly like the native .fullScreenCover(item:) modifier but automatically
    /// bridges the parent's modal system to the fullscreen content.
    ///
    /// This will only work in a view hierarchy containing both `POSFullscreenOverlayManager`
    /// and `POSModalManager` environment objects.
    ///
    /// - Parameters:
    ///   - item: Binding to control when the overlay is shown. When non-nil, the item is used to build the content.
    ///   - onDismiss: Optional closure executed when the overlay is dismissed.
    ///   - content: Content to show in the fullscreen overlay
    /// - Returns: a modified view which can show the fullscreen overlay content, with modal coordination.
    func posFullscreenOverlay<Item: Identifiable & Equatable, OverlayContent: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> OverlayContent
    ) -> some View {
        self.modifier(
            POSFullscreenOverlayViewModifierForItem(
                item: item,
                onDismiss: onDismiss,
                overlayContent: content
            )
        )
    }
}
