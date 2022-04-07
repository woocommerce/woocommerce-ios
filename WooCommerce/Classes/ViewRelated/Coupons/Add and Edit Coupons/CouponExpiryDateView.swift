import SwiftUI
import WordPressAuthenticator

/// View for selecting a date in SwiftUI.
///
struct CouponExpiryDateView: View {

    @State var date: Date = Date()

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        DatePicker("Date picker", selection: $date, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())

                        Button {
                            //TODO: handle action
                        } label: {
                            Text(Localization.resetButton)
                        }
                        .buttonStyle(LinkButtonStyle())
                        .fixedSize()
                        .padding(.bottom, Constants.verticalSpacing)

                        Spacer().frame(maxHeight: .infinity)
                    }
                }
            }
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.automatic)
        .wooNavigationBarStyle()
    }
}

// MARK: - Constants
//
private extension CouponExpiryDateView {

    enum Constants {
        static let margin: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
        static let iconSize: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString("Select an expiry date",
                                             comment: "Title of the view for selecting an expiry date for a coupon.")
        static let resetButton = NSLocalizedString("Reset",
                                                   comment: "Reset button in the view for selecting an expiry date for a coupon.")
    }
}

struct CouponExpiryDateView_Previews: PreviewProvider {
    static var previews: some View {
        CouponExpiryDateView(date: Date())
    }
}
