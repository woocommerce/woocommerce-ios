import SwiftUI

struct CouponDetails: View {
    @ObservedObject private var viewModel: CouponDetailsViewModel

    init(viewModel: CouponDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct CouponDetails_Previews: PreviewProvider {
    static let sampleViewModel: CouponDetailsViewModel = .init(couponID: 123, siteID: 456)

    static var previews: some View {
        CouponDetails(viewModel: sampleViewModel)
    }
}
