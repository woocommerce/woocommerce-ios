import Kingfisher
import SwiftUI

struct ProductStockRow: View {

    struct RowData: Equatable {
        let imageURL: URL?
        let name: String
        let subtitle: String
        let accessoryText: String
        let accessoryIsError: Bool

        init(imageURL: URL?,
             name: String,
             subtitle: String,
             accessoryText: String,
             accessoryIsError: Bool = false) {
            self.imageURL = imageURL
            self.name = name
            self.subtitle = subtitle
            self.accessoryText = accessoryText
            self.accessoryIsError = accessoryIsError
        }
    }

    private let data: RowData
    private let showDivider: Bool
    private let paddedRow: Bool
    private let tapHandler: () -> Void

    @ScaledMetric private var scale: CGFloat = 1.0

    init(data: RowData, showDivider: Bool, paddedRow: Bool = false, tapHandler: @escaping () -> Void) {
        self.data = data
        self.showDivider = showDivider
        self.paddedRow = paddedRow
        self.tapHandler = tapHandler
    }

    var body: some View {
        Button {
            tapHandler()
        } label: {
            VStack(spacing: paddedRow ? 0 : nil) {
                HStack(alignment: .top, spacing: Layout.padding) {
                    KFImage(data.imageURL)
                        .placeholder { Image(uiImage: .productPlaceholderImage)
                                .foregroundColor(Color(.listIcon))
                        }
                        .resizable()
                        .frame(width: Layout.thumbnailSize * scale,
                               height: Layout.thumbnailSize * scale)
                        .clipShape(RoundedRectangle(cornerSize: Layout.thumbnailCornerSize))

                    VStack {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading) {
                                Text(data.name)
                                    .bodyStyle()
                                    .multilineTextAlignment(.leading)
                                if !data.subtitle.isEmpty {
                                    Text(data.subtitle)
                                        .subheadlineStyle()
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            Spacer()
                            Text(data.accessoryText)
                                .foregroundStyle(data.accessoryIsError ? Color(.error) : Color(.text))
                                .bodyStyle()
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding(.horizontal, Layout.padding)
                .padding(.vertical, paddedRow ? Layout.chatRowVerticalPadding : 0)
                // Make the whole row width the tap target, not just the rendered text.
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())

                if showDivider {
                    Divider()
                        .padding(.leading, Layout.padding)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private extension ProductStockRow {
    enum Layout {
        static let padding: CGFloat = 16
        static let chatRowVerticalPadding: CGFloat = 12
        static let thumbnailSize: CGFloat = 40
        static let thumbnailCornerSize = CGSize(width: 4.0, height: 4.0)
    }
}
