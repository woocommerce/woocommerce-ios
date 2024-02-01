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
        }
        .buttonStyle(PressableButtonStyle(onPressed: {
            pressed = true
        }, onReleased: {
            pressed = false
        }))
        .listRowBackground(pressed ? listRowPressedBackgroundColor : listRowBackgroundColor)
    }
}

// solution from https://stackoverflow.com/a/71714195
struct PressableButtonStyle: ButtonStyle {
    let onPressed: () -> Void
    let onReleased: () -> Void
    @State private var isPressedWrapper: Bool = false {
        didSet {
            // new value is pressed, old value is not pressed -> switching to pressed state
            if isPressedWrapper && !oldValue {
                onPressed()
            }
            // new value is not pressed, old value is pressed -> switching to unpressed state
            else if oldValue && !isPressedWrapper {
                onReleased()
            }
        }
    }
    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .onChange(of: configuration.isPressed, perform: { newValue in isPressedWrapper = newValue })
    }
}
