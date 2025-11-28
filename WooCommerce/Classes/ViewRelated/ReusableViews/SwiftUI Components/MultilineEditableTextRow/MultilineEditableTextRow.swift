import SwiftUI

struct MultilineEditableTextRow: View {
    @State var value: String
    let placeholder: String
    let detailTitle: String?

    init(value: String, placeholder: String, detailTitle: String? = nil) {
        self.value = value
        self.placeholder = placeholder
        self.detailTitle = detailTitle
    }

    var body: some View {
        NavigationLink {
            MultilineEditableTextDetailView(text: $value, title: detailTitle)
        } label: {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        HStack(alignment: .center, spacing: Layout.spacing) {
            label

            Spacer()

            DisclosureIndicator()
        }
        .padding(.vertical, Layout.padding)
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
        MultilineEditableTextRow(value: text, placeholder: "Add note")
            .padding(.horizontal, 16)
    }
    .preferredColorScheme(.dark)
}
#endif
