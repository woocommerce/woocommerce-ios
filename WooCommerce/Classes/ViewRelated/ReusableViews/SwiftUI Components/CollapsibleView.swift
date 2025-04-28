import SwiftUI

/// Renders a view that can be toggled to show / hide contents.
///
struct CollapsibleView<Label: View, Content: View>: View {
    private let label: Label
    private let content: Content
    private let safeAreaInsets: EdgeInsets
    private let isCollapsible: Bool

    @Binding private var isCollapsed: Bool
    private var shouldShowDividers: Bool
    private let backgroundColor: UIColor
    private let hasSubtleChevron: Bool

    init(isCollapsible: Bool = true,
         isCollapsed: Binding<Bool> = .constant(false),
         safeAreaInsets: EdgeInsets = .zero,
         shouldShowDividers: Bool = true,
         backgroundColor: UIColor = .listForeground(modal: false),
         hasSubtleChevron: Bool = false,
         @ViewBuilder label: () -> Label,
         @ViewBuilder content: () -> Content) {
        self.label = label()
        self.content = content()
        self.safeAreaInsets = safeAreaInsets
        self.shouldShowDividers = shouldShowDividers
        self.backgroundColor = backgroundColor
        self.isCollapsible = isCollapsible
        self.hasSubtleChevron = hasSubtleChevron
        self._isCollapsed = isCollapsed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .renderedIf(shouldShowDividers)
            Button(action: {
                guard isCollapsible else { return }
                withAnimation {
                    isCollapsed.toggle()
                }
            }, label: {
                HStack(alignment: .top) {
                    label
                    Spacer()
                    if isCollapsible {
                        Image(uiImage: isCollapsed ? .chevronDownImage : .chevronUpImage)
                            .foregroundColor(hasSubtleChevron ? Color(.textSubtle) : Color(.accent))
                    }
                }
            })
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, CollapsibleViewConstants.horizontalPadding)
            .padding(.horizontal, insets: safeAreaInsets)
            .padding(.vertical, CollapsibleViewConstants.verticalPadding)
            .background(Color(backgroundColor))

            Divider()
                .renderedIf(shouldShowDividers)

            if !isCollapsed {
                content
            }
        }
    }
}

enum CollapsibleViewConstants {
    /// Internal horizontal padding of the view
    fileprivate static let horizontalPadding: CGFloat = 16
    /// Internal vertical padding of the view
    static let verticalPadding: CGFloat = 8
}

struct CollapsibleView_Previews: PreviewProvider {
    static var previews: some View {
        CollapsibleView(label: {
            Text("Test")
                .font(.headline)
        }, content: {
            VStack {
                Text("Roses are red")
                Divider()
                Text("Violets are blue")
            }
        })
    }
}
