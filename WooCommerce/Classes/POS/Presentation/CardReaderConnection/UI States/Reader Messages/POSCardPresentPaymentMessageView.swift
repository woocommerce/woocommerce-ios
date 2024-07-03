import SwiftUI

struct POSCardPresentPaymentMessageViewModel {
    let imageName: String?
    let showProgress: Bool?
    let title: String
    let message: String?
    let buttons: [CardPresentPaymentsModalButtonViewModel]

    init(imageName: String? = nil,
         showProgress: Bool? = nil,
         title: String,
         message: String? = nil,
         buttons: [CardPresentPaymentsModalButtonViewModel] = []) {
        self.imageName = imageName
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
            if let imageName = viewModel.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Layout.imageSize, height: Layout.imageSize)
            }
            if let showProgress = viewModel.showProgress, showProgress == true {
                ProgressView()
                    .progressViewStyle(IndefiniteCircularProgressViewStyle(
                        size: Layout.progressViewSize,
                        lineWidth: Layout.progressViewLineWidth))
            }
            Text(viewModel.title)
                .font(Font.system(size: 48, weight: .bold))
                .foregroundColor(Color(UIColor.wooCommercePurple(.shade80)))
            if let message = viewModel.message {
                Text(message)
                    .font(Font.system(size: 20))
                    .foregroundColor(Color(UIColor.wooCommercePurple(.shade70)))
            }
            if viewModel.buttons.isNotEmpty {
                HStack {
                    ForEach(viewModel.buttons) { buttonModel in
                        Button(buttonModel.title, action: buttonModel.actionHandler)
                    }
                }
                .padding()
            }
        }
        .multilineTextAlignment(.center)
    }
}

private extension POSCardPresentPaymentMessageView {
    enum Layout {
        static let progressViewSize: CGFloat = 80
        static let progressViewLineWidth: CGFloat = 4
        static let imageSize: CGFloat = 104
    }
}
