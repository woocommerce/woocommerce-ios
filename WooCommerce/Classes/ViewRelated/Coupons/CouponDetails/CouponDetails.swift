import SwiftUI
import Yosemite

struct CouponDetails: View {
    @ObservedObject private var viewModel: CouponDetailsViewModel

    init(viewModel: CouponDetailsViewModel) {
        self.viewModel = viewModel
    }

    private var detailRows: [DetailRow] {
        [
            .init(title: Localization.couponCode, content: viewModel.couponCode, action: {}),
            .init(title: Localization.description, content: viewModel.description, action: {}),
            .init(title: Localization.discount, content: viewModel.amount, action: {}),
            .init(title: Localization.applyTo, content: viewModel.productsAppliedTo, action: {}),
            .init(title: Localization.expiryDate, content: viewModel.expiryDate, action: {})
        ]
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Localization.performance)
                        .bold()
                        .padding(Constants.margin)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                            Text(Localization.discountedOrders)
                                .secondaryBodyStyle()
                            Text(viewModel.discountedOrdersCount)
                                .font(.title)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                            Text(Localization.amount)
                                .secondaryBodyStyle()
                            Text(viewModel.discountedAmount)
                                .font(.title)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding([.horizontal, .bottom], Constants.margin)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                }
                .background(Color(.listForeground))

                Spacer().frame(height: Constants.margin)

                VStack(alignment: .leading, spacing: 0) {
                    Text(Localization.detailSectionTitle)
                        .bold()
                        .padding(Constants.margin)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                    ForEach(detailRows) { row in
                        TitleAndValueRow(title: row.title,
                                         value: .content(row.content),
                                         selectable: true,
                                         action: row.action)
                            .padding(.vertical, Constants.verticalSpacing)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                    }
                }
                .background(Color(.listForeground))
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .navigationTitle(Localization.navigationTitle)
    }
}

// MARK: - Subtypes
//
private extension CouponDetails {
    enum Constants {
        static let margin: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
    }

    enum Localization {
        static let navigationTitle = NSLocalizedString("Coupon", comment: "Title of Coupon Details screen")
        static let detailSectionTitle = NSLocalizedString("Coupon Details", comment: "Title of Details section in Coupon Details screen")
        static let couponCode = NSLocalizedString("Coupon Code", comment: "Title of the Coupon Code row in Coupon Details screen")
        static let description = NSLocalizedString("Description", comment: "Title of the Description row in Coupon Details screen")
        static let discount = NSLocalizedString("Discount", comment: "Title of the Discount row in Coupon Details screen")
        static let applyTo = NSLocalizedString("Apply To", comment: "Title of the Apply To row in Coupon Details screen")
        static let expiryDate = NSLocalizedString("Coupon Expiry Date", comment: "Title of the Coupon Expiry Date row in Coupon Details screen")
        static let performance = NSLocalizedString("Performance", comment: "Title of the Performance section on Coupons Details screen")
        static let discountedOrders = NSLocalizedString("Discounted Orders", comment: "Title of the Discounted Orders label on Coupon Details screen")
        static let amount = NSLocalizedString("Amount", comment: "Title of the Amount label on Coupon Details screen")
    }

    struct DetailRow: Identifiable {
        var id: String { title }

        let title: String
        let content: String
        let action: () -> Void
    }
}

#if DEBUG
struct CouponDetails_Previews: PreviewProvider {
    static var previews: some View {
        CouponDetails(viewModel: CouponDetailsViewModel(coupon: Coupon.sampleCoupon))
    }
}
#endif
