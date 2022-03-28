import SwiftUI
import Yosemite

struct AddEditCoupon: View {

    @ObservedObject private(set) var viewModel: AddEditCouponViewModel

    init(_ viewModel: AddEditCouponViewModel) {
        self.viewModel = viewModel
        //TODO: add analytics
    }

    var body: some View {
        NavigationView {
            Text("Hello, World!")
        }
        .navigationTitle(viewModel.titleView)
    }
}

struct AddEditCoupon_Previews: PreviewProvider {
    static var previews: some View {

        /// Edit Coupon
        ///
        let editingViewModel = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon)
        AddEditCoupon(editingViewModel)
    }
}
