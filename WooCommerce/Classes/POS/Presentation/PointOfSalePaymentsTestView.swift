import SwiftUI
import Combine

// Required for making a dummy order
import Yosemite

class PointOfSalePaymentsTestViewModel: ObservableObject {
    let cardPresentPayments: CardPresentPayments
    var cancellables = Set<AnyCancellable>()

    @Published var onboardingViewModels: InPersonPaymentsViewModel?

    @Published var paymentModalViewModel:
    WrappedCardPresentPaymentsModalViewModel?

    init(siteID: Int64) {
        self.cardPresentPayments = CardPresentPaymentsAdaptor(siteID: siteID)
        cardPresentPayments.paymentScreenEventPublisher
            .print("🅿️ payment event")
            .map { event -> InPersonPaymentsViewModel? in
            switch event {
            case .showOnboarding(let onboardingViewModel):
                return onboardingViewModel
            default:
                return nil
            }
        }
        .assign(to: &$onboardingViewModels)

        cardPresentPayments.paymentScreenEventPublisher
            .map { event -> WrappedCardPresentPaymentsModalViewModel? in
            switch event {
            case .presentAlert(let content):
                return WrappedCardPresentPaymentsModalViewModel(from: content)
            default:
                return nil
            }
        }
        .assign(to: &$paymentModalViewModel)
    }

    func startTestPayment() async {
        do {
            let order = try await cardPresentPayments.createTestOrder()
            _ = await cardPresentPayments.collectPayment(
                for: order,
                using: .bluetoothScan)
        } catch {
            DDLogError("Error with test payment \(error)")
        }
    }

    func cancel() {
        cardPresentPayments.cancelPayment()
    }
}
