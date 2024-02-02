import SwiftUI

struct ListPressableButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State var pressed: Bool = false
    // using default values for now, we can remove them later if needed and pass them when creating ListPressableButton
    let listRowBackgroundColor: Color = Color(.listForeground(modal: false))
    let listRowPressedBackgroundColor: Color = Color(.listSelectedBackground)

    public init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }

    var body: some View {
        Button {
            action()
        } label: {
            label()
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle(pressed: $pressed))
        .listRowBackground(pressed ? listRowPressedBackgroundColor : listRowBackgroundColor)
    }
}

// solution based from https://stackoverflow.com/a/71714195
struct PressableButtonStyle: ButtonStyle {
    @Binding var pressed: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .onChange(of: configuration.isPressed, perform: { newValue in
                pressed = newValue
            })
    }
}
