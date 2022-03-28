import SwiftUI

struct AddEditCoupon: View {

    let viewModel: AddEditCouponViewModel

    init(_ viewModel: AddEditCouponViewModel) {
        self.viewModel = viewModel

        //TODO: add analytics
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct AddEditCoupon_Previews: PreviewProvider {
    static var previews: some View {
        AddEditCoupon(AddEditCouponViewModel())
    }
}
