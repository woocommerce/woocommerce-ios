import SwiftUI
import Combine

// Required for making a dummy order
import Yosemite
import Fakes

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
        _ = await cardPresentPayments.collectPayment(
            for: Order.fake(),
            using: .bluetoothScan)
    }

    func cancel() {
        cardPresentPayments.cancelPayment()
    }
}
