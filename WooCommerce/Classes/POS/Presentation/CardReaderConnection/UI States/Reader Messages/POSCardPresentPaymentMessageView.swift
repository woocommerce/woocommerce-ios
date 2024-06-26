import SwiftUI

struct POSCardPresentPaymentMessageViewModel {
    let showProgress: Bool?
    let title: String?
    let message: String?
    let buttons: [CardPresentPaymentsModalButtonViewModel]

    init(showProgress: Bool? = nil, title: String? = nil, message: String? = nil, buttons: [CardPresentPaymentsModalButtonViewModel] = []) {
        self.showProgress = showProgress
        self.title = title
        self.message = message
        self.buttons = buttons
    }
}

struct POSCardPresentPaymentMessageView: View {
    let viewModel: POSCardPresentPaymentMessageViewModel

    var body: some View {
        VStack {
            if let showProgress = viewModel.showProgress, showProgress == true {
                ProgressView()
                    .progressViewStyle(IndefiniteCircularProgressViewStyle(
                        size: Layout.progressViewSize,
                        lineWidth: Layout.progressViewLineWidth))
            }
            if let title = viewModel.title {
                Text(title)
                    .font(Font.system(size: 48, weight: .bold))
                    .foregroundColor(Color(UIColor.wooCommercePurple(.shade80)))
            }
            if let message = viewModel.message {
                Text(message)
                    .font(Font.system(size: 20))
                    .foregroundColor(Color(UIColor.wooCommercePurple(.shade70)))
            }
            ForEach(viewModel.buttons) { buttonModel in
                Button(buttonModel.title, action: buttonModel.actionHandler)
            }
        }
        .multilineTextAlignment(.center)
    }
}

private extension POSCardPresentPaymentMessageView {
    enum Layout {
        static let progressViewSize: CGFloat = 24
        static let progressViewLineWidth: CGFloat = 4
    }
}
