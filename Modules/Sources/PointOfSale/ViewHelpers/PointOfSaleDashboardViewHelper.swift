import Foundation

struct PointOfSaleDashboardViewHelper {
    static func determineViewState(
        eligibilityState: POSEligibilityState?,
        itemsContainerState: ItemsContainerState
    ) -> PointOfSaleDashboardView.ViewState {

        guard let eligibilityState else {
            return .loading(catalogSyncState: itemsContainerState.catalogSyncState)
        }

        switch eligibilityState {
        case .eligible:
            // Check items container state
            switch itemsContainerState {
            case let .loading(catalogSyncState):
                return .loading(catalogSyncState: catalogSyncState)
            case .error(let error):
                return .error(error)
            case .content:
                return .content
            }
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }
    }

    /// Whether the compact-layout cart button should be shown below the item list.
    ///
    /// The dashboard does not move up for a full keyboard, so the button would sit under it
    /// and show through the translucent keyboard.
    static func showsCompactCartButton(cartIsEmpty: Bool, floatingControlSuppressed: Bool, isFullSizeKeyboardVisible: Bool) -> Bool {
        !cartIsEmpty && !floatingControlSuppressed && !isFullSizeKeyboardVisible
    }

    /// Whether a barcode scan should auto-open the compact-layout cart sheet.
    ///
    /// On compact layout (ie Phone POS) the cart is a sheet, so a scan's outcome (loading row,
    /// resolved product, or error row) is invisible until the sheet opens. On regular layout
    /// the cart pane is always visible.
    static func shouldAutoOpenCartOnScan(isPhoneLayout: Bool, orderStage: PointOfSaleOrderStage) -> Bool {
        isPhoneLayout && orderStage == .building
    }

    /// Whether the compact-layout cart sheet should close after a cart change.
    ///
    /// On phone the products sit behind the cart sheet, so an empty cart left open would make the
    /// merchant close it by hand before adding anything. The regular layout keeps its empty cart pane.
    static func shouldDismissCompactCartSheet(isPhoneLayout: Bool, cartIsEmpty: Bool) -> Bool {
        isPhoneLayout && cartIsEmpty
    }

    enum ExitDecision: Equatable {
        case showConfirmation
        case leave(tracksConfirmation: Bool)
    }

    /// The approval prompt already confirms the exit, so an approved exit leaves POS without the confirmation.
    static func exitDecision(confirmingFirst: Bool, approved: Bool) -> ExitDecision {
        guard confirmingFirst else {
            return .leave(tracksConfirmation: false)
        }
        return approved ? .leave(tracksConfirmation: true) : .showConfirmation
    }
}

extension PointOfSaleDashboardView.ViewState {
    var showsFloatingControl: Bool {
        switch self {
        case .content:
            return true
        case .error(let error):
            // Hide floating controls for initial catalog sync errors
            // TODO: WOOMOB-1692 remove specialisation of errors if possible
            return error.errorType != .initialCatalogSyncError
        case .loading, .ineligible:
            return false
        }
    }
}
