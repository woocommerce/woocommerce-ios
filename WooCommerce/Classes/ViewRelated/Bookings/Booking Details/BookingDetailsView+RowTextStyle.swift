import SwiftUI

private extension BookingDetailsView {
    struct RowTextStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(TextFont.bodyMedium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
    }
}

extension View {
    func rowTextStyle() -> some View {
        self.modifier(BookingDetailsView.RowTextStyle())
    }
}
