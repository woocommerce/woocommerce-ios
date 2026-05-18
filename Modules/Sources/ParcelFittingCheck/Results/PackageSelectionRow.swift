import SwiftUI

struct PackageSelectionRow<Content: View, Trailing: View>: View {
    let isSelected: Bool
    let onSelect: () -> Void
    @ViewBuilder let content: () -> Content
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: Constants.spacing) {
            Button(action: onSelect) {
                HStack(spacing: Constants.spacing) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .gray)
                        .font(.title2)

                    content()

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            trailing()
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
    }
}

extension PackageSelectionRow where Trailing == EmptyView {
    init(isSelected: Bool, onSelect: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.content = content
        self.trailing = { EmptyView() }
    }
}

private enum Constants {
    static let spacing: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 12
}
