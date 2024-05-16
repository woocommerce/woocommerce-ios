import SwiftUI
import Combine

// Required for making a dummy order
import Yosemite
import Fakes

class PointOfSalePaymentsTestViewModel: ObservableObject {
    let cardPresentPayments: CardPresentPayments
    var cancellables = Set<AnyCancellable>()

    @Published var onboardingViewModels: InPersonPaymentsViewModel?

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
    }

    func cancel() {
        cardPresentPayments.cancelPayment()
    }
}

struct PointOfSalePaymentsTestView: View {
    @ObservedObject var viewModel: PointOfSalePaymentsTestViewModel

    init(viewModel: PointOfSalePaymentsTestViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(
        action: {
            Task {
                await viewModel.cardPresentPayments.collectPayment(for: Order.fake(), using: .bluetoothScan)
            }
        }, label: {
            Text("Start payment")
        })
            .sheet(item: $viewModel.onboardingViewModels) { onboardingViewModel in
                NavigationStack {
                    InPersonPaymentsView(viewModel: onboardingViewModel)
                        .navigationTitle(Text(""))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            Button(action: viewModel.cancel) {
                                Text("Cancel")
                            }
                        }
                }
            }
    }
}

#Preview {
    PointOfSalePaymentsTestView(viewModel: PointOfSalePaymentsTestViewModel(siteID: 123))
}
