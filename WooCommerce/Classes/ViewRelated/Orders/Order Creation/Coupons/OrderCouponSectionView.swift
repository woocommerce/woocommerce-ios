import SwiftUI

struct OrderCouponSectionView: View {
    @ObservedObject var viewModel: EditableOrderViewModel
    @ObservedObject var couponViewModel: EditableOrderCouponLineViewModel

    @State private var shouldShowCouponList: Bool = false

    var body: some View {
        VStack {
            HStack {
                Text(Localization.couponsSectionTitle)
                    .accessibilityAddTraits(.isHeader)
                    .headlineStyle()

                Spacer()

                Button(action: {
                    shouldShowCouponList = true
                }, label: {
                    Image(uiImage: .plusImage)
                        .foregroundColor(Color(.primary))
                })

            }
            .padding(.horizontal)
            ForEach(couponViewModel.couponLineRows, id: \.couponID) { coupon in
                HStack {
                    Text(coupon.code)
                    Spacer()
                    Button(action: {
                        removeCouponLine(with: coupon.code)
                    }, label: {
                        Image(uiImage: .trashImage)
                            .foregroundColor(Color(.primary))
                    })
                }
            }
        }
        .renderedIf(couponViewModel.couponLineRows.isNotEmpty)
        .sheet(isPresented: $shouldShowCouponList) {
            CouponListView(siteID: viewModel.siteID,
                           emptyStateActionTitle: "",
                           emptyStateAction: { },
                           onCouponSelected: { coupon in
                addCouponLine(with: coupon.code)
                shouldShowCouponList = false
            })
        }
    }
}

private extension OrderCouponSectionView {
    enum Localization {
        static let couponsSectionTitle = NSLocalizedString(
            "OrderCouponSectionView.header.coupons",
            value: "Coupons",
            comment: "Title of the section that display coupons applied to an order, within the order creation screen.")
    }

    func addCouponLine(with code: String) {
        viewModel.saveCouponLine(result: .added(newCode: code))
    }

    func removeCouponLine(with code: String) {
        viewModel.saveCouponLine(result: .removed(code: code))
    }
}
