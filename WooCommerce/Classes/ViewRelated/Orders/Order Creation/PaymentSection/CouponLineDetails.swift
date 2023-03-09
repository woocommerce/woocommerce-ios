import SwiftUI

/// View to add/edit a single coupon line in an order, with the option to remove it.
///
struct CouponLineDetails: View {

    /// View model to drive the view content
    ///
    @ObservedObject private var viewModel: CouponLineDetailsViewModel

    /// Defines if the coupon code input text field should be focused. Defaults to `true`
    ///
    @State private var focusCouponCodeInput: Bool = true

    @Environment(\.presentationMode) var presentation

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    init(viewModel: CouponLineDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: .zero) {
                    Section {
                        AdaptiveStack(horizontalAlignment: .leading) {
                            Text(Localization.couponCodeField)
                                .bodyStyle()
                                .fixedSize()

                            HStack {
                                Spacer()
                                BindableTextfield(Localization.couponCodePlaceholder,
                                                  text: $viewModel.code,
                                                  focus: $focusCouponCodeInput)
                                    .keyboardType(.numbersAndPunctuation)
                                    .textAlignment(.right)
                                    .onTapGesture {
                                        focusCouponCodeInput = true
                                    }
                            }
                        }
                        .frame(minHeight: Layout.rowHeight)
                        .padding([.leading, .trailing], Layout.rowPadding)
                    }
                    .background(Color(.listForeground(modal: false)))
                    .addingTopAndBottomDividers()

                    Spacer(minLength: Layout.sectionSpacing)

                    if viewModel.isExistingCouponLine {
                        Section {
                            Button(Localization.remove) {
                                viewModel.didSelectSave(nil)
                                presentation.wrappedValue.dismiss()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
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
        static let dividerPadding: CGFloat = 16.0
        static let rowHeight: CGFloat = 44
        static let rowPadding: CGFloat = 16
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
