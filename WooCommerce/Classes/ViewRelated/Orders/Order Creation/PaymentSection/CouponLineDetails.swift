import SwiftUI

/// View to add/edit a single coupon line in an order, with the option to remove it.
///
struct CouponLineDetails: View {
    private enum Field: Hashable {
        case couponCode
    }

    /// View model to drive the view content
    ///
    @ObservedObject private var viewModel: CouponLineDetailsViewModel

    @Environment(\.presentationMode) var presentation

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    @FocusState private var focusedField: Field?

    init(viewModel: CouponLineDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: .zero) {
                    TitleAndTextFieldRow(title: Localization.couponCodeField,
                                         placeholder: Localization.couponCodePlaceholder,
                                         text: $viewModel.code,
                                         keyboardType: .numbersAndPunctuation)
                    .focused($focusedField, equals: .couponCode)
                    .background(Color(.listForeground(modal: false)))
                    .padding(.horizontal, insets: safeAreaInsets)
                    .addingTopAndBottomDividers()
                    .background(Color(.listForeground(modal: false)))
                    .onTapGesture {
                        focusedField = .couponCode
                    }

                    Spacer(minLength: Layout.sectionSpacing)

                    if viewModel.isExistingCouponLine {
                        Section {
                            Button(Localization.remove) {
                                focusedField = nil
                                viewModel.didSelectSave(nil)
                                presentation.wrappedValue.dismiss()
                            }
                            .padding()
                            .foregroundColor(Color(.error))
                            .padding(.horizontal, insets: safeAreaInsets)
                            .addingTopAndBottomDividers()
                        }
                        .background(Color(.listForeground(modal: false)))
                    }
                }
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .navigationTitle(viewModel.isExistingCouponLine ? Localization.coupon : Localization.addCoupon)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        presentation.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(Localization.done) {
                        viewModel.saveData()
                        presentation.wrappedValue.dismiss()
                    }
                    .disabled(viewModel.shouldDisableDoneButton)
                }
            }
        }
        .wooNavigationBarStyle()
    }
}

// MARK: Constants
private extension CouponLineDetails {
    enum Layout {
        static let sectionSpacing: CGFloat = 16.0
    }

    enum Localization {
        static let addCoupon = NSLocalizedString("Add coupon", comment: "Title for the Coupon screen during order creation")
        static let coupon = NSLocalizedString("Coupon", comment: "Title for the Coupon screen during order creation")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Coupon Details screen")
        static let done = NSLocalizedString("Done", comment: "Text for the done button in the Coupon Details screen")
        static let remove = NSLocalizedString("Remove Coupon from Order",
                                              comment: "Text for the button to remove a Coupon from the order during order creation")
        static let couponCodeField = NSLocalizedString("Coupon", comment: "Title for the coupon field on the Coupon Details screen during order creation")
        static let couponCodePlaceholder = NSLocalizedString(
            "Enter a coupon",
            comment: "Text field coupon code placeholder in the view for adding or editing a coupon.")
    }
}

struct CouponLineDetails_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: true,
                                                   code: "",
                                                   didSelectSave: { _ in })
        CouponLineDetails(viewModel: viewModel)
    }
}
