import SwiftUI

/// A view to be displayed when a coupon is created successfully.
///
struct CouponCreationSuccess: View {
    let couponCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Image(uiImage: UIImage.checkSuccessImage)
                    .padding(.bottom, 40)
                Text("Your new coupon was created!")
                    .font(.largeTitle)
                    .bold()
                Text(couponCode)
                    .font(.largeTitle)
            }
        }
    }
}

struct CouponCreationSuccess_Previews: PreviewProvider {
    static var previews: some View {
        CouponCreationSuccess(couponCode: "34sdfg")
    }
}
