import SwiftUI

/// Represent a single coupon row in the Product section of a New Order in the CouponSelectorView
///
struct CouponRow: View {
    @ObservedObject var viewModel: CouponRowViewModel

    /// Accessibility hint describing the coupon row tap gesture.
    let accessibilityHint: String

    init(viewModel: CouponRowViewModel,
         accessibilityHint: String = "") {
        self.viewModel = viewModel
        self.accessibilityHint = accessibilityHint
    }

    var body: some View {
        Button(action: {
            viewModel.isSelected.toggle()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.couponCode)
                        .bodyStyle()
                    Text(viewModel.summary)
                        .subheadlineStyle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                if viewModel.isSelected {
                    Image(uiImage: UIImage.checkmarkImage)
                        .foregroundColor(Color(.accent))
                        .imageScale(.large)
                }
            }
            .frame(minHeight: Constants.height)
        }
        .accessibilityLabel(viewModel.couponAccessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private enum Constants {
        static let height: CGFloat = 36
    }
}

struct CouponRow_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CouponRowViewModel(couponCode: "FREESHIPPING",
                                           summary: "Free shipping for all orders.")
        CouponRow(viewModel: viewModel)
    }
}
