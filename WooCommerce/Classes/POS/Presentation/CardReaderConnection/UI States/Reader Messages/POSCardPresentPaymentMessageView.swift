import SwiftUI

struct POSCardPresentPaymentMessageViewModel {
    var imageName: String? = nil
    var showProgress: Bool = false
    let title: String
    var message: String? = nil
    var buttons: [CardPresentPaymentsModalButtonViewModel] = []
}

struct POSCardPresentPaymentMessageView: View {
    let viewModel: POSCardPresentPaymentMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: Layout.verticalSpacing) {
                if let imageName = viewModel.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Layout.imageSize, height: Layout.imageSize)
                }

                if viewModel.showProgress {
                    ProgressView()
                        .progressViewStyle(POSProgressViewStyle())
                }

                VStack(alignment: .center, spacing: Layout.textSpacing) {
                    Text(viewModel.title)
                        .foregroundStyle(Color(.neutral(.shade40)))
                        .font(.posBody)

                    if let message = viewModel.message {
                        Text(message)
                            .font(.posTitle)
                            .foregroundStyle(Color(.neutral(.shade60)))
                            .bold()
                    }
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
            Spacer()
        }
    }
}

private extension POSCardPresentPaymentMessageView {
    enum Layout {
        static let imageSize: CGFloat = 104
        static let textSpacing: CGFloat = 4
        static let verticalSpacing: CGFloat = 72
    }
}
