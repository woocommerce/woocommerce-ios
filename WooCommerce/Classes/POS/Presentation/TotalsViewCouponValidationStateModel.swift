import Foundation
import Observation

@available(iOS 17.0, *)
@Observable final class TotalsViewCouponValidationStateModel {
    private var delayedOrderState: PointOfSaleOrderState = .idle
    private var debounceTask: Task<Void, Never>?
    private let posModel: PointOfSaleAggregateModelProtocol

    var showsCouponValidation: Bool {
        guard posModel.cart.coupons.isNotEmpty,
              case .syncing = delayedOrderState else {
            return false
        }

        return true
    }

    init?(posModel: PointOfSaleAggregateModelProtocol) {
        self.posModel = posModel
        self.delayedOrderState = posModel.orderState

        guard posModel.cart.isNotEmpty else { return nil }

        debounceOrderStateChanges()
    }

    /// 'Coupon Validation' is an artificial payment state shown when order is loading and coupons added to cart
    /// Visual glitches can happen due to a small delay between syncing state finishing and payment starting
    /// Debouncing orderState changes between syncing to show coupons validation for longer
    ///
    private func debounceOrderStateChanges() {
        withObservationTracking({
            _ = posModel.orderState
        }, onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                debounceTask?.cancel()
                if case .syncing = delayedOrderState,
                   case .loaded = posModel.orderState {
                    debounceTask = Task {
                        try? await Task.sleep(nanoseconds: 200 * NSEC_PER_MSEC)
                        guard !Task.isCancelled else { return }
                        self.delayedOrderState = self.posModel.orderState
                    }
                } else {
                    self.delayedOrderState = self.posModel.orderState
                }
            }
        })
    }
}
