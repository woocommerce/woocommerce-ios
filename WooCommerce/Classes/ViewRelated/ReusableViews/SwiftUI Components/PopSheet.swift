//
//  This is an updated version of the solution you can find here
// https://stackoverflow.com/questions/56910941/present-actionsheet-in-swiftui-on-ipad/58490096#58490096
//
import SwiftUI

extension View {
    func popSheet(isPresented: Binding<Bool>,
                  arrowEdge: Edge = .bottom,
                  content: @escaping () -> PopSheet) -> some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                popover(isPresented: isPresented,
                        attachmentAnchor: .point(.bottom),
                        arrowEdge: arrowEdge,
                        content: { content().popover(isPresented: isPresented) })
            } else {
                actionSheet(isPresented: isPresented, content: { content().actionSheet() })
            }
        }
        .background(Color(.listForeground))
    }
}

struct PopSheet {
    let title: Text
    let message: Text?
    let buttons: [PopSheet.Button]

    init(title: Text, message: Text? = nil, buttons: [PopSheet.Button] = [.cancel()]) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }

    func actionSheet() -> ActionSheet {
        ActionSheet(title: title, message: message, buttons: buttons.map({ popButton in
            switch popButton.kind {
            case .default: return .default(popButton.label, action: popButton.action)
            case .cancel: return .cancel(popButton.label, action: popButton.action)
            case .destructive: return .destructive(popButton.label, action: popButton.action)
            }
        }))
    }

    func popover(isPresented: Binding<Bool>) -> some View {
        let width = UIScreen.main.bounds.width / 2

        return VStack() {
            title.font(.title)

            if message != nil {
                message
                    .font(.body)
                    .padding()
            }

            LazyVStack {
            ForEach(buttons) { button in
                SwiftUI.Button(action: {
                    // hide the popover whenever an action is performed
                    isPresented.wrappedValue = false

                    // if the action shows a sheet or popover, it will fail unless this one has already been dismissed
                    DispatchQueue.main.async {
                        button.action?()
                    }
                }, label: {
                    button.label
                })
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            }
            .background(Color(.listBackground))
        }
        .padding()
        .frame(width: width)
        .frame(maxHeight: .infinity)
    }

    struct Button: Identifiable {
        let id = UUID().uuidString
        let kind: Kind
        let label: Text
        let action: (() -> Void)?
        enum Kind { case `default`, cancel, destructive }

        /// Creates a `Button` with the default style.
        static func `default`(_ label: Text, action: (() -> Void)? = {}) -> Self {
            Self(kind: .default, label: label, action: action)
        }

        /// Creates a `Button` that indicates cancellation of some operation.
        static func cancel(_ label: Text, action: (() -> Void)? = {}) -> Self {
            Self(kind: .cancel, label: label, action: action)
        }

        /// Creates an `Alert.Button` that indicates cancellation of some operation.
        static func cancel(_ action: (() -> Void)? = {}) -> Self {
            Self(kind: .cancel, label: Text("Cancel"), action: action)
        }

        /// Creates an `Alert.Button` with a style indicating destruction of some data.
        static func destructive(_ label: Text, action: (() -> Void)? = {}) -> Self {
            Self(kind: .destructive, label: label, action: action)
        }
    }
}
