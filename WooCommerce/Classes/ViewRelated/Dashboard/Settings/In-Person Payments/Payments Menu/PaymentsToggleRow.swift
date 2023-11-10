import SwiftUI

struct PaymentsToggleRow: View {
    private let image: Image
    private let title: String
    @ObservedObject private var toggleRowViewModel: InPersonPaymentsCashOnDeliveryToggleRowViewModel
    @Binding private var toggleState: Bool

    init(image: Image,
         title: String,
         toggleRowViewModel: InPersonPaymentsCashOnDeliveryToggleRowViewModel) {
        self.image = image
        self.title = title
        self.toggleRowViewModel = toggleRowViewModel
        self._toggleState = Binding(
            get: {
                toggleRowViewModel.cashOnDeliveryEnabledState
            },
            set: {
                toggleRowViewModel.updateCashOnDeliverySetting(enabled: $0)
            })
    }

    var body: some View {
        Toggle(isOn: $toggleState) {
            HStack(alignment: .top) {
                image
                VStack(alignment: .leading, spacing: Layout.narrowSpacing) {
                    Text(title)
                    InPersonPaymentsLearnMore(viewModel: toggleRowViewModel.learnMoreViewModel,
                                              showInfoIcon: false)
                }
            }
        }
    }

    private enum Layout {
        static let narrowSpacing: CGFloat = 8.0
    }
}

struct PaymentsToggleRow_Previews: PreviewProvider {
    static var previews: some View {
        PaymentsToggleRow(image: Image(uiImage: .creditCardIcon),
                          title: "Pay in Person",
                          toggleRowViewModel: InPersonPaymentsCashOnDeliveryToggleRowViewModel())
        .previewLayout(.sizeThatFits)
    }
}
