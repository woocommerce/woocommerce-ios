import SwiftUI

/// View to input a simple text in a full screen view.
///
struct FullScreenTextView: View {

    /// Title of the view, displayed in the Navigation Bar.
    ///
    let title: String

    /// The text that will be displayed inside the text view.
    ///
    @Binding var text: String

    /// The placeholder text that will be displayed when `text` is empty.
    ///
    let placeholder: String

    @State private var isTextEditorFirstResponded = false
    private var displayPlaceholder: Bool {
        return !isTextEditorFirstResponded && text.isEmpty
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                TextEditor(text: $text)
                    .bodyStyle()
                    .frame(minHeight: geometry.size.height, alignment: .leading)
                    .padding(.horizontal, Constants.margin)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                    .onAppear {
                        // Remove the placeholder text when keyboard appears
                        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                                               object: nil, queue: .main) { _ in
                            withAnimation {
                                isTextEditorFirstResponded = true
                            }
                        }

                        // Put back the placeholder text if the user dismisses the keyboard without adding any text
                        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                                               object: nil, queue: .main) { _ in
                            withAnimation {
                                isTextEditorFirstResponded = false
                            }
                        }
                    }

                /// We use a text editor as a placeholder view for mantaining the same internal configuration of the Text Editor (eg: leading distance).
                ///
                TextEditor(text: .constant(placeholder))
                    .foregroundColor(Color(.gray(.shade30)))
                    .bodyStyle()
                    .disabled(true)
                    .opacity(displayPlaceholder  ? 1 : 0)
                    .padding(.horizontal, Constants.margin)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                Spacer()
            }
            .padding([.top, .bottom], Constants.topSpacing)
            .ignoresSafeArea(.container, edges: [.horizontal])
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.automatic)
    }
}

private extension FullScreenTextView {
    enum Constants {
        static let margin: CGFloat = 16
        static let topSpacing: CGFloat = 24
    }
}

struct FullScreenTextView_Previews: PreviewProvider {
    static var previews: some View {
        let text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit." +
        " Sed lobortis elit pretium arcu consectetur commodo. Sed in blandit augue. Nunc in laoreet felis. Quisque vitae dolor sed arcu iaculis eleifend." +
        " Vestibulum quam augue, luctus eu rhoncus at, consequat euismod est. Suspendisse blandit feugiat lorem, varius fermentum metus commodo ac." +
        " Vivamus et gravida eros, vel pretium lacus." +
        " Aenean tempus risus suscipit condimentum molestie. Sed dignissim auctor ligula id viverra. Nunc vitae eros gravida, aliquam sem sed, facilisis velit."
        FullScreenTextView(title: "Title of the view", text: .constant(text), placeholder: "Enter your text ")
    }
}
