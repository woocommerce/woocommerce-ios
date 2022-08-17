import SwiftUI

struct InPersonPaymentsOnboardingErrorMainContentView: View {
    let title: String
    let message: String
    let image: ImageInfo
    let supportLink: Bool

    struct ImageInfo {
        let image: UIImage
        let height: CGFloat
    }

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isCompact: Bool {
        get {
            verticalSizeClass == .compact
        }
    }

    var body: some View {
        VStack(alignment: .center) {
            Text(title)
                .font(.headline)
                .padding(.bottom, isCompact ? 16 : 32)
            Image(uiImage: image.image)
                .resizable()
                .scaledToFit()
                .frame(height: isCompact ? image.height / 3 : image.height)
                .padding(.bottom, isCompact ? 16 : 32)
            Text(message)
                .font(.callout)
                .padding(.bottom, isCompact ? 12 : 24)
            if supportLink {
                InPersonPaymentsSupportLink()
            }
        }.multilineTextAlignment(.center)
        .frame(maxWidth: 500)
    }
}

struct InPersonPaymentsOnboardingErrorMainContentView_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsOnboardingErrorMainContentView(title: "Title",
                                                       message: "Lorem ipsum dolor sit amet",
                                                       image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                                                        image: .paymentErrorImage,
                                                        height: 180),
                                                       supportLink: true)
    }
}
