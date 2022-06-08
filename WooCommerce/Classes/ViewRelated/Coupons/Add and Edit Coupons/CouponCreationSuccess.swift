import SwiftUI

/// A view to be displayed when a coupon is created successfully.
///
struct CouponCreationSuccess: View {
    let couponCode: String

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
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
                    // TODO
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(Localization.close) {
                    // TODO
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
        CouponCreationSuccess(couponCode: "34sdfg")
    }
}
