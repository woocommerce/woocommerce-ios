import SwiftUI
import Yosemite

struct MostActiveCouponRow: View {
    let viewModel: MostActiveCouponRowViewModel
    let tapHandler: (() -> Void)

    var body: some View {
        Button {
            tapHandler()
        } label: {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.code)
                            .bodyStyle()
                        Text(viewModel.summary)
                            .subheadlineStyle()
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(viewModel.uses)
                            .bodyStyle()
                        Spacer()
                    }
                }
                .padding(.horizontal, Layout.padding)

                Divider()
                    .padding(.leading, Layout.padding)
            }
        }
    }
}

private extension MostActiveCouponRow {
    enum Layout {
        static let padding: CGFloat = 16
    }
}

struct MostActiveCouponRowViewModel: Identifiable {
    let coupon: Coupon
    private let report: CouponReport

    init(coupon: Coupon, report: CouponReport) {
        self.coupon = coupon
        self.report = report
    }

    var id: Int64 {
        coupon.couponID
    }

    var code: String {
        coupon.code
    }

    var summary: String {
        coupon.summary()
    }

    var uses: String {
        "\(report.ordersCount)"
    }
}
