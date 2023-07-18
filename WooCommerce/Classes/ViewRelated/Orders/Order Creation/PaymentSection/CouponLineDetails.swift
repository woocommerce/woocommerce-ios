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

    /// Defines whether we should show a progress view instead of the done button.
    ///
    @State private var showValidateCouponLoading: Bool = false

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
                    .disabled(showValidateCouponLoading)

                    Spacer(minLength: Layout.sectionSpacing)
                    Section {
                            Button(Localization.remove) {
                                focusedField = nil
                                viewModel.removeCoupon()
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
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .navigationTitle(Localization.coupon)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        presentation.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if showValidateCouponLoading {
                        ProgressView()
                    } else {
                        Button(Localization.done) {
                            showValidateCouponLoading = true

                            viewModel.validateAndSaveData() { shouldDimiss in
                                showValidateCouponLoading = false

                                if shouldDimiss {
                                    presentation.wrappedValue.dismiss()
                                }
                            }
                        }
                    }
                }
            }
        }
        .wooNavigationBarStyle()
        .notice($viewModel.notice)
    }
}

// MARK: Constants
private extension CouponLineDetails {
    enum Layout {
        static let sectionSpacing: CGFloat = 16.0
    }

    enum Localization {
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
        let viewModel = CouponLineDetailsViewModel(code: "",
                                                   siteID: 0,
                                                   didSelectSave: { _ in })
        CouponLineDetails(viewModel: viewModel)
    }
}
