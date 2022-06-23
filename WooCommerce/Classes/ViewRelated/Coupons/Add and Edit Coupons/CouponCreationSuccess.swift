import SwiftUI

/// A view to be displayed when a coupon is created successfully.
///
struct CouponCreationSuccess: View {
    let couponCode: String
    let shareMessage: String
    let onDismiss: () -> Void

    @State private var showingShareSheet: Bool = false
    @State private var imageScale = Constants.initialImageScale
    @State private var imageBottomSpace = Constants.initialImageBottomSpacing
    @State private var textOpacity = Constants.initialTextOpacity
    @State private var buttonsVerticalOffset = Constants.initialButtonsVerticalOffset

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Image(uiImage: UIImage.checkSuccessImage)
                    .padding(.bottom, imageBottomSpace)
                    .scaleEffect(imageScale)
                Text(Localization.successMessage)
                    .font(.largeTitle)
                    .bold()
                    .opacity(textOpacity)
                Text(couponCode)
                    .font(.largeTitle)
                    .opacity(textOpacity)
            }
            .padding(Constants.contentPadding)

            Spacer()

            VStack(alignment: .center, spacing: Constants.contentPadding) {
                Button(Localization.shareCoupon) {
                    showingShareSheet = true
                    // TODO: add analytics
                }
                .buttonStyle(PrimaryButtonStyle())
                .shareSheet(isPresented: $showingShareSheet) {
                    ShareSheet(activityItems: [shareMessage])
                }

                Button(Localization.close) {
                    onDismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Constants.contentPadding)
            .offset(x: 0, y: buttonsVerticalOffset)
        }
        .onAppear {
            animateEntry()
        }
        .onDisappear {
            onDismiss()
        }
    }

    private func animateEntry() {
        let buttonGroupAnimation = Animation.easeIn(duration: Constants.buttonGroupAnimationDuration)

        let imageAnimation = Animation
            .interpolatingSpring(stiffness: Constants.imageAnimationStiffness,
                                 damping: Constants.imageAnimationDamping,
                                 initialVelocity: Constants.imageAnimationInitialVelocity)
            .delay(Constants.imageAnimationDelay)

        let textAnimation = Animation
            .easeIn(duration: Constants.textAnimationDuration)
            .delay(Constants.textAnimationDelay)

        withAnimation(buttonGroupAnimation) {
            buttonsVerticalOffset = Constants.finalButtonsVerticalOffset
        }

        withAnimation(imageAnimation) {
            imageScale = Constants.finalImageScale
        }

        withAnimation(textAnimation) {
            imageBottomSpace = Constants.finalImageBottomSpacing
            textOpacity = Constants.finalTextOpacity
        }
    }
}

private extension CouponCreationSuccess {
    enum Constants {
        static let contentPadding: CGFloat = 16

        static let initialImageBottomSpacing: CGFloat = 80
        static let finalImageBottomSpacing: CGFloat = 40
        static let initialImageScale: CGFloat = 0
        static let finalImageScale: CGFloat = 1

        static let initialTextOpacity: CGFloat = 0
        static let finalTextOpacity: CGFloat = 1

        static let initialButtonsVerticalOffset: CGFloat = 300
        static let finalButtonsVerticalOffset: CGFloat = 0

        static let buttonGroupAnimationDuration: CGFloat = 0.3
        static let imageAnimationStiffness: CGFloat = 150
        static let imageAnimationDamping: CGFloat = 15
        static let imageAnimationInitialVelocity: CGFloat = 3
        static let imageAnimationDelay: CGFloat = 0.7
        static let textAnimationDuration: CGFloat = 0.3
        static let textAnimationDelay: CGFloat = 0.5
    }

    enum Localization {
        static let successMessage = NSLocalizedString("Your new coupon was created!", comment: "Message displayed when a coupon was successfully created")
        static let shareCoupon = NSLocalizedString("Share Coupon", comment: "Button to share coupon from the Coupon Creation Success screen.")
        static let close = NSLocalizedString("Close", comment: "Button to dismiss the Coupon Creation Success screen")
    }
}

struct CouponCreationSuccess_Previews: PreviewProvider {
    static var previews: some View {
        CouponCreationSuccess(couponCode: "34sdfg", shareMessage: "Use this coupon to get 10% off all products") {}
    }
}
