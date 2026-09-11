import Foundation
import Observation
import enum Yosemite.OrderRefundEligibilityFailure
import struct Yosemite.POSOrder

@Observable final class POSRefundController {
    private(set) var selectableItems: [POSRefundSelectableItem] = []
    private(set) var hasModifiedSelection = false

    private(set) var order: POSOrder?
    private(set) var preparation: POSRefundPreparation?

    private let refundSubmissionProcessor: POSRefundSubmissionProcessing

    init(refundSubmissionProcessor: POSRefundSubmissionProcessing) {
        self.refundSubmissionProcessor = refundSubmissionProcessor
    }

    @MainActor
    var requiresCardPresentRefund: Bool {
        preparation?.requiresCardPresentRefund ?? false
    }

    // MARK: - Refund Item Selection

    @MainActor
    func preloadRefund(for order: POSOrder) async {
        guard order.refundActionAvailability == .available else {
            return
        }
        await refundSubmissionProcessor.preloadRefund(for: order)
    }

    @MainActor
    func startRefundFlow(for order: POSOrder) async -> StartRefundFlowResult {
        self.order = order

        let preparation: POSRefundPreparation
        do {
            preparation = try await refundSubmissionProcessor.prepareRefund(for: order)
            self.preparation = preparation
        } catch let eligibilityFailure as OrderRefundEligibilityFailure {
            self.preparation = nil
            return .ineligible(eligibilityFailure)
        } catch {
            self.preparation = nil
            return .failed
        }

        selectableItems = preparation.selectableItems
        hasModifiedSelection = false

        return selectableItems.isEmpty ? .nothingToRefund : .hasItemsToRefund
    }

    @MainActor
    var hasLoadedSelectableItems: Bool {
        !selectableItems.isEmpty
    }

    @MainActor
    func refreshRefundableItems() async -> StartRefundFlowResult {
        guard let order else { return .failed }

        let result = await startRefundFlow(for: order)
        guard case .hasItemsToRefund = result else {
            return result
        }

        for index in selectableItems.indices {
            selectableItems[index].isSelected = false
        }
        return result
    }

    @MainActor
    func toggleItemSelection(at index: Int) {
        guard selectableItems.indices.contains(index) else { return }
        selectableItems[index].isSelected.toggle()
        hasModifiedSelection = true
    }

    @MainActor
    func toggleAllItemsSelection() {
        guard !selectableItems.isEmpty else { return }
        let allSelected = selectableItems.allSatisfy { $0.isSelected }
        let newSelectionState = !allSelected
        for index in selectableItems.indices {
            selectableItems[index].isSelected = newSelectionState
        }
        hasModifiedSelection = true
    }

    @MainActor
    func clearSelection() {
        selectableItems = []
        hasModifiedSelection = false
    }

    @MainActor
    func reset() {
        order = nil
        preparation = nil
        clearSelection()
    }
}
