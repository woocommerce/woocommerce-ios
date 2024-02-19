import SwiftUI

struct SelectableItemRow: View {
    private let id = UUID()
    private let title: String
    private let subtitle: String?
    private let selected: Bool
    private let displayMode: DisplayMode
    private let alignment: Alignment
    private let selectionStyle: SelectionStyle
    @Environment(\.isEnabled) private var isEnabled

    init(title: String,
         subtitle: String? = nil,
         selected: Bool,
         displayMode: DisplayMode = .full,
         alignment: Alignment = .leading,
         selectionStyle: SelectionStyle = .checkmark) {
        self.title = title
        self.subtitle = subtitle
        self.selected = selected
        self.displayMode = displayMode
        self.alignment = alignment
        self.selectionStyle = selectionStyle
    }
    var body: some View {
        HStack(spacing: 0) {
            if alignment == .leading {
                selectionIcon
            }

            VStack(alignment: .leading) {
                Text(title)
                    .bodyStyle(isEnabled)
                    .multilineTextAlignment(.leading)
                subtitle.map {
                    Text($0)
                        .footnoteStyle(isEnabled: isEnabled)
                        .padding(.top, 8)
                }
            }
            .padding(.leading, alignment.leadingSpace)
            .padding(.trailing, alignment.trailingSpace)

            Spacer()

            if alignment == .trailing {
                selectionIcon
            }
        }
        .padding([.top, .bottom], Constants.hStackPadding)
        .frame(minHeight: displayMode.minHeight)
        .contentShape(Rectangle())
    }

    private var selectionIcon: some View {
        ZStack {
            if let image = selectionStyle.image(selected: selected, isEnabled: isEnabled) {
                Image(uiImage: image)
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                    .iconStyle(isEnabled)
            }
        }
        .frame(width: Constants.zStackWidth)
    }
}

extension SelectableItemRow {
    enum DisplayMode {
        case compact
        case full

        var minHeight: CGFloat {
            switch self {
            case .compact:
                return Constants.compactHeight
            case .full:
                return Constants.height
            }
        }
    }

    enum Alignment {
        case leading
        case trailing

        var leadingSpace: CGFloat {
            switch self {
            case .leading:
                return 0
            case .trailing:
                return Constants.vStackPadding
            }
        }

        var trailingSpace: CGFloat {
            switch self {
            case .leading:
                return Constants.vStackPadding
            case .trailing:
                return 0
            }
        }
    }

    enum SelectionStyle {
        case checkmark
        case checkcircle

        func image(selected: Bool, isEnabled: Bool) -> UIImage? {
            switch (self, selected, isEnabled) {
            case (.checkmark, true, true):
                return .checkmarkStyledImage
            case (.checkmark, _, _):
                return nil
            case (.checkcircle, true, _):
                return .checkCircleImage.withRenderingMode(.alwaysTemplate)
            case (.checkcircle, false, _):
                return .checkEmptyCircleImage
            }
        }
    }
}

private extension SelectableItemRow {
    enum Constants {
        static let zStackWidth: CGFloat = 48
        static let vStackPadding: CGFloat = 16
        static let hStackPadding: CGFloat = 10
        static let height: CGFloat = 60
        static let compactHeight: CGFloat = 52
        static let imageSize: CGFloat = 22
    }
}

struct SelectableItemRow_Previews: PreviewProvider {
    static var previews: some View {
        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: true)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Selected")

        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: false)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Unselected")

        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: true)
            .disabled(true)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Disabled state")

        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: true, selectionStyle: .checkcircle)
            .previewDisplayName("Check Circle Selected")

        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: false, selectionStyle: .checkcircle)
            .previewDisplayName("Check Circle Unselected")

        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: true, selectionStyle: .checkcircle)
            .disabled(true)
            .previewDisplayName("Check Circle Disabled")
    }
}
