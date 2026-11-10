import SwiftUI

struct OrderCouponSectionView: View {
    @ObservedObject var viewModel: EditableOrderViewModel
    @ObservedObject var couponViewModel: EditableOrderCouponLineViewModel

    /// Safe-area insets of the form's container.
    ///
    let safeAreaInsets: EdgeInsets

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
        .padding(.horizontal, insets: safeAreaInsets)
        .padding()
        .renderedIf(couponViewModel.couponLineRows.isNotEmpty)
        .background(Color(.listForeground(modal: true)), ignoresSafeAreaEdges: [])
        .addingTopAndBottomDividers()
        .sheet(isPresented: $shouldShowCouponList) {
            NavigationStack {
                CouponListView(siteID: viewModel.siteID,
                               emptyStateActionTitle: "",
                               emptyStateAction: { },
                               onCouponSelected: { coupon in
                    addCouponLine(with: coupon.code)
                    shouldShowCouponList = false
                })
                .ignoresSafeArea(.container, edges: .bottom)
                .navigationTitle(Localization.addCoupon)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localization.cancelButton) {
                            shouldShowCouponList = false
                        }
                    }
                }
            }
        }
    }
}

private extension OrderCouponSectionView {
    enum Localization {
        static let addCoupon = NSLocalizedString(
            "order.form.coupon.add.button.title",
            value: "Add Coupon",
            comment: "Title for the Coupon screen during order creation")

        static let cancelButton = NSLocalizedString(
            "order.form.coupon.cancel.button.title",
            value: "Cancel",
            comment: "Cancel button title when showing the coupon list selector")

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
