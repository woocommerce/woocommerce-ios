import SwiftUI

struct PlusButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        return IconButton(configuration: configuration,
                          icon: Image(systemName: "plus"))
    }

    private struct IconButton: View {
        let configuration: ButtonStyleConfiguration
        let icon: Image

        var body: some View {
            HStack {
                Label {
                    configuration.label
                } icon: {
                    icon
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .foregroundColor(Color.white)
            .background(Color(.clear))
        }
    }
}
