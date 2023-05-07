import SwiftUI

struct CouponSelectorView: View {
    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: CouponSelectorViewModel

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    /// Defines whether the view is presented.
    ///
    @Binding var isPresented: Bool

    /// Environment presentation mode
    ///
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>


    /// Selected coupon
    ///
    @State private var selectedCoupon: CouponRowViewModel?


    var body: some View {
        NavigationView {
            VStack (spacing: .zero) {
                List {
                    ForEach(viewModel.couponRows) { rowViewModel in
                        createCouponRow(rowViewModel: rowViewModel)
                            .padding(Constants.defaultPadding)
                    }
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Choose Coupon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented.toggle()
                        presentationMode.wrappedValue.dismiss()
                        // TODO: add steps to clear all coupon selection
                    }
                }
            }
            .wooNavigationBarStyle()
        }
    }

    /// Creates the `CouponRow` for a coupon
    ///
    @ViewBuilder private func createCouponRow(rowViewModel: CouponRowViewModel) -> some View {
        CouponRow(viewModel: rowViewModel)
    }
}

private extension CouponSelectorView {
    enum Constants {
        static let defaultPadding: CGFloat = 8
    }
}

struct CouponSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CouponSelectorViewModel(siteID: 123)
        CouponSelectorView(viewModel: viewModel,
                           isPresented: .constant(true))
    }
}
