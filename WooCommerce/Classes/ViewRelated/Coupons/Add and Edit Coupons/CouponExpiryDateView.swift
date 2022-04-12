import SwiftUI
import WordPressAuthenticator

/// View for selecting a date in SwiftUI.
///
struct CouponExpiryDateView: View {

    @State var date: Date = Date()
    let completion: ((Date) -> Void)

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    DatePicker("Date picker", selection: $date, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .onChange(of: date) { newDate in
                            completion(newDate)
                        }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Localization.title)
    }
}

// MARK: - Constants
//
private extension CouponExpiryDateView {

    enum Localization {
        static let title = NSLocalizedString("Select an expiry date",
                                             comment: "Title of the view for selecting an expiry date for a coupon.")
        static let resetButton = NSLocalizedString("Reset",
                                                   comment: "Reset button in the view for selecting an expiry date for a coupon.")
    }
}

struct CouponExpiryDateView_Previews: PreviewProvider {
    static var previews: some View {
        CouponExpiryDateView(date: Date(), completion: { _ in })
    }
}
