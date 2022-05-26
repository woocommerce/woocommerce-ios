import SwiftUI
import WordPressAuthenticator

/// View for selecting a date in SwiftUI.
///
struct CouponExpiryDateView: View {

    @State var date: Date = Date()
    var timezone: TimeZone
    let onCompletion: (Date) -> Void
    let onRemoval: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    DatePicker("Date picker", selection: $date, displayedComponents: .date)
                        .environment(\.timeZone, timezone)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .onChange(of: date) { newDate in
                            onCompletion(newDate)
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
        static let title = NSLocalizedString("Coupon expiry date",
                                             comment: "Title of the view for selecting an expiry date for a coupon.")
    }
}

struct CouponExpiryDateView_Previews: PreviewProvider {
    static var previews: some View {
        CouponExpiryDateView(date: Date(), timezone: TimeZone.siteTimezone, onCompletion: { _ in }, onRemoval: {})
    }
}
