import SwiftUI
import Yosemite

struct InPersonPaymentsOnboardingError: View {
    let title: String
    let message: String
    let image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo
    let supportLink: Bool
    let learnMore: Bool
    var button: ButtonInfo? = nil

    struct ButtonInfo {
        let text: String
        let action: () -> Void
    }

    var body: some View {
        VStack {
            Spacer()

            InPersonPaymentsOnboardingErrorMainContentView(
                title: title,
                message: message,
                image: image,
                supportLink: supportLink
            )

            Spacer()

            if button != nil {
                Button(button!.text, action: button!.action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.bottom, 24.0)
            }
            if learnMore {
                InPersonPaymentsLearnMore()
            }
        }.padding()
    }
}

extension CardPresentPaymentsPlugin {
    public var image: UIImage {
        switch self {
        case .wcPay:
            return .wcPayPlugin
        case .stripe:
            return .stripePlugin
        }
    }
}
