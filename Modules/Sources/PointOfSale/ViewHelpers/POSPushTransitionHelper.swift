import Foundation

/// Decisions behind `POSPushTransitionContainer`, kept apart from the view so they can be tested.
enum POSPushTransitionHelper {
    enum Navigation<Item: Equatable>: Equatable {
        /// A new item: bring the pushed screen in, if it isn't on screen already.
        case push
        /// A back drag already slid the pushed screen out; only the state is left to settle.
        case settleCompletedDrag
        /// Slide the pushed screen out, keeping `retainedItem` on it until it has left.
        case pop(retainedItem: Item?)
        case popWithoutAnimation
    }

    static func navigation<Item: Equatable>(from oldItem: Item?,
                                            to newItem: Item?,
                                            isCompletingDrag: Bool,
                                            animatesPop: Bool) -> Navigation<Item> {
        if newItem != nil {
            return .push
        }
        if isCompletingDrag {
            return .settleCompletedDrag
        }
        return animatesPop ? .pop(retainedItem: oldItem) : .popWithoutAnimation
    }

    /// The item the pushed screen renders. Side by side the pushed screen stays on screen, so a cleared
    /// item has to show its empty state straight away rather than the one being left.
    static func displayedItem<Item>(item: Item?, poppingItem: Item?, isSideBySide: Bool) -> Item? {
        item ?? (isSideBySide ? nil : poppingItem)
    }

    /// Whether a back drag that is still finishing has to be abandoned. Losing eligibility cancels it;
    /// gaining it can't, because no drag starts while back is unavailable.
    static func invalidatesInFlightDrag(couldNavigateBack: Bool, canNavigateBack: Bool) -> Bool {
        couldNavigateBack && !canNavigateBack
    }
}
