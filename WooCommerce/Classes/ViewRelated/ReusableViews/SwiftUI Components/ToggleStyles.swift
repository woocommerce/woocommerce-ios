import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? Color.accentColor : Color.primary)
                configuration.label
            }
        })
        .buttonStyle(.plain)
    }
}

#Preview {
    Toggle(isOn: .constant(true)) {
        Text("I'm not a robot")
    }
    .toggleStyle(CheckboxToggleStyle())
}

#Preview {
    Toggle(isOn: .constant(false)) {
        Text("I'm a human")
    }
    .toggleStyle(CheckboxToggleStyle())
}
