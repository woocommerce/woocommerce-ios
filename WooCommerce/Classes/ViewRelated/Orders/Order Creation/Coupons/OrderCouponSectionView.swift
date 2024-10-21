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
                        .foregroundColor(viewModel.disabled ? Color(.textSubtle) : Color(.primary))
                })
                .disabled(viewModel.disabled)
            }
            ForEach(couponViewModel.couponLineRows, id: \.couponID) { coupon in
                HStack {
                    Text(coupon.code)
                        .subheadlineStyle()
                    Spacer()
                    Button(action: {
                        removeCouponLine(with: coupon.code)
                    }, label: {
                        Image(uiImage: .trashImage)
                            .foregroundColor(Color(.primary))
                    })
                }
                .padding(Layout.contentPadding)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .fill(Color(uiColor: .init(light: UIColor.clear,
                                                   dark: UIColor.systemGray5)))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .stroke(Color(uiColor: .separator), lineWidth: Layout.borderLineWidth)
                }
            }
        }
        .padding()
        .renderedIf(couponViewModel.couponLineRows.isNotEmpty)
        .background(Color(.listForeground(modal: true)))
        .addingTopAndBottomDividers()
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

    enum Layout {
        static let cornerRadius: CGFloat = 8
        static let borderLineWidth: CGFloat = 0.5
        static let contentPadding: CGFloat = 16
    }

    func addCouponLine(with code: String) {
        viewModel.saveCouponLine(result: .added(newCode: code))
    }

    func removeCouponLine(with code: String) {
        viewModel.saveCouponLine(result: .removed(code: code))
    }
}
