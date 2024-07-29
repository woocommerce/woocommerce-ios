import SwiftUI

struct POSCardPresentPaymentMessageViewModel {
    var imageName: String? = nil
    var showProgress: Bool = false
    let title: String
    var message: String? = nil
    var buttons: [CardPresentPaymentsModalButtonViewModel] = []
}

struct POSCardPresentPaymentMessageViewStyle {
    var titleColor: Color
    var messageColor: Color

    static let dimmed = POSCardPresentPaymentMessageViewStyle(
        titleColor: Color(.neutral(.shade40)),
        messageColor: Color(.neutral(.shade60))
    )

    static let standard = POSCardPresentPaymentMessageViewStyle(
        titleColor: .posPrimaryTexti3,
        messageColor: .posPrimaryTexti3
    )
}

struct POSCardPresentPaymentMessageView: View {
    let viewModel: POSCardPresentPaymentMessageViewModel
    var style: POSCardPresentPaymentMessageViewStyle = .standard

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: Layout.verticalSpacing) {
                if let imageName = viewModel.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: Layout.imageSize, height: Layout.imageSize)
                }

                if viewModel.showProgress {
                    ProgressView()
                        .progressViewStyle(POSProgressViewStyle())
                        .frame(width: Layout.imageSize, height: Layout.imageSize)
                }

                VStack(alignment: .center, spacing: Layout.textSpacing) {
                    Text(viewModel.title)
                        .foregroundStyle(style.titleColor)
                        .font(.posBody)

                    if let message = viewModel.message {
                        Text(message)
                            .font(.posTitle)
                            .foregroundStyle(style.messageColor)
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
        static let imageSize: CGFloat = 156
        static let textSpacing: CGFloat = 4
        static let verticalSpacing: CGFloat = 72
    }
}
