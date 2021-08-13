import SwiftUI

/// Custom view modifier for displaying a minimal back button in the navigation bar
struct MinimalNavigationBarBackButton: ViewModifier {
    @Environment(\.presentationMode) var presentation

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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


struct DynamicTitle: ViewModifier {

    let hidden: Binding<Bool>
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(!hidden.wrappedValue ? title : "")
    }
}

extension View {
    /// Displays a minimal back button in the navigation bar
    func dynamicNavigationTitle(hidden: Binding<Bool>, title: String) -> some View {
        self.modifier(DynamicTitle(hidden: hidden, title: title))
    }
}
