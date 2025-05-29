import Observation
import SwiftUI

@available(iOS 17.0, *)
@Observable
final class AppInputFocusState {
    enum Input: Hashable {
        case none
        case search
        case email
        case cashAmount
    }

    var activeInput: Input = .none
}

@available(iOS 17.0, *)
struct InputFocusTracking: ViewModifier {
    @FocusState var isFocused: Bool
    let inputType: AppInputFocusState.Input
    @Environment(AppInputFocusState.self) private var focusState

    @State private var wasFocused = false

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { _, newValue in
                wasFocused = newValue
                focusState.activeInput = newValue ? inputType : .none
            }
            .onDisappear {
                // Handle case where field is removed while still focused
                // Note that `isFocused` may become false without `onChange` having a chance to run.
                if wasFocused {
                    focusState.activeInput = .none
                }
            }
    }
}

@available(iOS 17.0, *)
extension View {
    func trackInputFocus(
        _ isFocused: FocusState<Bool>,
        as inputType: AppInputFocusState.Input
    ) -> some View {
        self.modifier(InputFocusTracking(isFocused: isFocused, inputType: inputType))
    }
}
