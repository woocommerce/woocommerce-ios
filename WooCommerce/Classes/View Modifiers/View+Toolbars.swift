import SwiftUI

/// Custom view modifier for displaying a minimal back button in the navigation bar
struct MinimalNavigationBarBackButton: ViewModifier {
    @Environment(\.presentationMode) var presentation

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        presentation.wrappedValue.dismiss()
                    } label: {
                        Image(uiImage: .chevronLeftImage.imageFlippedForRightToLeftLayoutDirection())
                    }
                }
            }
    }
}

extension View {
    /// Displays a minimal back button in the navigation bar
    func minimalNavigationBarBackButton() -> some View {
        self.modifier(MinimalNavigationBarBackButton())
    }
}
