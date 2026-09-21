import SwiftUI

struct MultilineEditableTextRow: View {
    @Binding var value: String
    let placeholder: String
    let detailTitle: String?
    let onTap: (() -> Void)?
    let onCommit: (String) async -> MultilineCommitResult

    init(value: Binding<String>,
         placeholder: String,
         detailTitle: String? = nil,
         onTap: (() -> Void)? = nil,
         onCommit: @escaping (String) async -> MultilineCommitResult
    ) {
        self._value = value
        self.placeholder = placeholder
        self.detailTitle = detailTitle
        self.onTap = onTap
        self.onCommit = onCommit
    }

    var body: some View {
        NavigationLink {
            MultilineEditableTextDetailView(text: $value, title: detailTitle, onCommit: onCommit)
        } label: {
            content
        }
        .simultaneousGesture(TapGesture().onEnded {
            onTap?()
        })
    }

    @ViewBuilder
    private var content: some View {
        HStack(alignment: .center, spacing: Layout.spacing) {
            label

            Spacer()

            DisclosureIndicator()
        }
        .padding(.vertical, Layout.padding)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var label: some View {
        if value.isEmpty {
            Text(placeholder)
                .rowTextStyle()
                .foregroundStyle(Color(.textSubtle))
        } else {
            Text(value)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Color.primary)
        }
    }
}

fileprivate extension MultilineEditableTextRow {
    enum Layout {
        static let spacing: CGFloat = 10
        static let padding: CGFloat = 12
    }
}

#if DEBUG
#Preview {
    @Previewable @State var text: String = ""

    NavigationStack {
        MultilineEditableTextRow(value: $text, placeholder: "Add note") { _ in
            return .success
        }
            .padding(.horizontal, 16)
    }
    .preferredColorScheme(.dark)
}
#endif
