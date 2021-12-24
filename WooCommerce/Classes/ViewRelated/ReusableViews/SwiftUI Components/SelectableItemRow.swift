import SwiftUI

struct SelectableItemRow: View {
    private let id = UUID()
    private let title: String
    private let subtitle: String?
    private let selected: Bool
    private let displayMode: DisplayMode
    private let alignment: Alignment
    @Environment(\.isEnabled) private var isEnabled

    init(title: String, subtitle: String? = nil, selected: Bool, displayMode: DisplayMode = .full, alignment: Alignment = .leading) {
        self.title = title
        self.subtitle = subtitle
        self.selected = selected
        self.displayMode = displayMode
        self.alignment = alignment
    }
    var body: some View {
        HStack(spacing: 0) {
            if alignment == .leading {
                checkmark
            }

            VStack(alignment: .leading) {
                Text(title)
                    .bodyStyle(isEnabled)
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
                checkmark
            }
        }
        .padding([.top, .bottom], Constants.hStackPadding)
        .frame(minHeight: displayMode.minHeight)
        .contentShape(Rectangle())
    }

    private var checkmark: some View {
        ZStack {
            if selected, isEnabled {
                Image(uiImage: .checkmarkStyledImage).frame(width: Constants.imageSize, height: Constants.imageSize)
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

        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: false)
            .previewLayout(.fixed(width: 375, height: 100))

        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: true)
            .disabled(true)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Disabled state")
    }
}
