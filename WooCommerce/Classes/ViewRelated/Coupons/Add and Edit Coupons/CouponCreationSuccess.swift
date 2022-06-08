import SwiftUI

/// A view to be displayed when a coupon is created successfully.
///
struct CouponCreationSuccess: View {
    let couponCode: String
    let shareMessage: String
    let onDismiss: () -> Void
    @State private var showingShareSheet: Bool = false


    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Anchor the action sheet at the top to be able to show the popover on iPad in the most appropriate position
            Divider()
                .shareSheet(isPresented: $showingShareSheet) {
                    ShareSheet(activityItems: [shareMessage])
                }

            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Image(uiImage: UIImage.checkSuccessImage)
                    .padding(.bottom, Constants.imageBottomSpacing)
                Text(Localization.successMessage)
                    .font(.largeTitle)
                    .bold()
                Text(couponCode)
                    .font(.largeTitle)
            }
            .padding(Constants.contentPadding)

            Spacer()

            VStack(alignment: .center, spacing: Constants.contentPadding) {
                Button(Localization.shareCoupon) {
                    showingShareSheet = true
                    // TODO: add analytics
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(Localization.close) {
                    onDismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Constants.contentPadding)
        }
    }
}

private extension CouponCreationSuccess {
    enum Constants {
        static let imageBottomSpacing: CGFloat = 40
        static let contentPadding: CGFloat = 16
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
