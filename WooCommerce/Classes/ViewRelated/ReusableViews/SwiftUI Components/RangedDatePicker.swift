import Foundation
import SwiftUI

/// View to reselect a custom date range.
/// Consists of two date pickers laid out vertically.
///
struct RangedDatePicker: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {

                    // Start Picker
                    Text(Localization.startDate)
                        .foregroundColor(Color(.accent))
                        .headlineStyle()

                    Divider()

                    DatePicker("", selection: .constant(Date()), in: ...Date(), displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .accentColor(Color(.brand))

                    // End Picker
                    Text(Localization.endDate)
                        .foregroundColor(Color(.accent))
                        .headlineStyle()

                    Divider()

                    DatePicker("", selection: .constant(Date()), in: ...Date(), displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .accentColor(Color(.brand))
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    // Navigation Bar title
                    VStack(spacing: Layout.titleSpacing) {
                        Text(Localization.title)
                            .headlineStyle()
                        Text("Dec 1 - Dec 6") // TODO: This should be dynamic
                            .captionStyle()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        // TODO: Send apply action
                    }, label: {
                        Text(Localization.apply)
                    })
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        // TODO: Send dismiss action
                    }, label: {
                        Image(uiImage: .closeButton)
                    })
                }
            })
        }
        .navigationViewStyle(.stack)
        .wooNavigationBarStyle()
    }
}

// MARK: Constant

private extension RangedDatePicker {
    enum Localization {
        static let title = NSLocalizedString("Custom Date Range", comment: "Title in custom range date picker")
        static let apply = NSLocalizedString("Apply", comment: "Apply navigation button in custom range date picker")
        static let startDate = NSLocalizedString("Start Date", comment: "Start Date label in custom range date picker")
        static let endDate = NSLocalizedString("End Date", comment: "End Date label in custom range date picker")
    }
    enum Layout {
        static let titleSpacing: CGFloat = 4.0
    }
}

// MARK: Previews

struct RangedDatePickerPreview: PreviewProvider {
    static var previews: some View {
        RangedDatePicker()
    }
}
