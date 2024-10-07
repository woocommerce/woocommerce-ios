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
            ForEach(couponViewModel.couponLineRows, id: \.couponID) { couponRow in
                HStack {
                    Text(couponRow.code)
                    Spacer()
                    Button(action: {
                        couponViewModel.temporary_deleteCoupon()
                    }, label: {
                        Image(uiImage: .trashImage)
                            .foregroundColor(Color(.primary))
                    })
                }
            }
        }
        .border(.green, width: 2.0)
        .renderedIf(couponViewModel.couponLineRows.isNotEmpty)
        .sheet(isPresented: $shouldShowCouponList) {
            CouponListView(siteID: viewModel.siteID,
                           emptyStateActionTitle: "",
                           emptyStateAction: { },
                           onCouponSelected: { coupon in
                viewModel.saveCouponLine(result: .added(newCode: coupon.code))
                shouldShowCouponList = false
            })
        }
    }
}

private extension OrderCouponSectionView {
    enum Localization {
        static let couponsSectionTitle = NSLocalizedString("", value: "Coupons", comment: "")
    }
}
