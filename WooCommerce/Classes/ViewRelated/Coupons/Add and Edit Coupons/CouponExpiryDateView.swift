import SwiftUI
import WordPressAuthenticator

/// View for selecting a date in SwiftUI.
///
struct CouponExpiryDateView: View {
    @Environment(\.presentationMode) var presentationMode

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
                    Spacer()
                    
                    Divider()
                    Button(action: {
                        onRemoval()
                        presentationMode.wrappedValue.dismiss()
                    }, label: { Text(Localization.removeButton) })
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, Constants.margin)
                    .foregroundColor(Color(.error))
                    Divider()
                }
            }
        }
        .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Localization.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    onCompletion(date)
                    presentationMode.wrappedValue.dismiss()
                }, label: { Text(Localization.doneButton) })
                        .foregroundColor(Color(.accent))
            }
        }
    }
}

// MARK: - Constants
//
private extension CouponExpiryDateView {
    enum Constants {
        static let margin: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString("Coupon expiry date",
                                             comment: "Title of the view for selecting an expiry date for a coupon.")
        static let doneButton = NSLocalizedString("Done", comment: "Button to finish selecting the Coupon expiry date in the AddEditCoupon screen")
        static let removeButton = NSLocalizedString("Remove Expiry Date", comment: "Button to remove the Coupon expiry date in the AddEditCoupon screen")
    }
}

struct CouponExpiryDateView_Previews: PreviewProvider {
    static var previews: some View {
        CouponExpiryDateView(date: Date(), timezone: TimeZone.siteTimezone, onCompletion: { _ in }, onRemoval: {})
    }
}
