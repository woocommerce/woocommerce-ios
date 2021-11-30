import SwiftUI

struct InPersonPaymentsOnboardingError: View {
    let title: String
    let message: String
    let image: ImageInfo
    let supportLink: Bool
    let learnMore: Bool
    var button: ButtonInfo? = nil

    struct ButtonInfo {
        let text: String
        let action: () -> Void
    }

    struct ImageInfo {
        let image: UIImage
        let height: CGFloat
    }

    var body: some View {
        VStack {
            Spacer()

            MainContent(
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

    struct MainContent: View {
        let title: String
        let message: String
        let image: ImageInfo
        let supportLink: Bool

        @Environment(\.verticalSizeClass) var verticalSizeClass

        var isCompat: Bool {
            get {
                verticalSizeClass == .compact
            }
        }

        var body: some View {
            VStack(alignment: .center) {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, isCompat ? 16 : 32)
                Image(uiImage: image.image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: isCompat ? image.height / 3 : image.height)
                    .padding(.bottom, isCompat ? 16 : 32)
                Text(message)
                    .font(.callout)
                    .padding(.bottom, isCompat ? 12 : 24)
                if supportLink {
                    InPersonPaymentsSupportLink()
                }
            }.multilineTextAlignment(.center)
            .frame(maxWidth: 500)
        }
    }
}
