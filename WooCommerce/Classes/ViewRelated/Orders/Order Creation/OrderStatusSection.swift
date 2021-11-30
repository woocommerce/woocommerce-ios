import SwiftUI
import Yosemite

struct OrderStatusSection: View {
    let geometry: GeometryProxy
    let dateCreated: Date
    let statusEnum: OrderStatusEnum

    var body: some View {
        Divider()

        VStack(alignment: .leading) {
            Text(dateString)
                .footnoteStyle()

            HStack {
                Text(statusBadgeTitle)
                    .foregroundColor(.black)
                    .footnoteStyle()
                    .padding(.horizontal, Layout.StatusBadge.horizontalPadding)
                    .padding(.vertical, Layout.StatusBadge.verticalPadding)
                    .background(Color(statusBadgeColor))
                    .cornerRadius(Layout.StatusBadge.cornerRadius)
                Spacer()
                Button(Localization.editButton) {}
                    .buttonStyle(LinkButtonStyle())
                    .fixedSize(horizontal: true, vertical: true)
                    .padding(.trailing, -Layout.linkButtonTrailingPadding) // remove trailing padding to align button title to the side
            }
        }
        .padding(.horizontal, insets: geometry.safeAreaInsets)
        .padding([.leading, .trailing, .top])
        .background(Color(.listForeground))

        Divider()
    }

    private var dateString: String {
        let formatter = DateFormatter.mediumLengthLocalizedDateFormatter

        return formatter.string(from: dateCreated)
    }

    private var statusBadgeTitle: String {
        statusEnum.rawValue
    }

    private var statusBadgeColor: UIColor {
        switch statusEnum {
        case .pending, .completed, .cancelled, .refunded, .custom:
            return .gray(.shade5)
        case .onHold:
            return .withColorStudio(.orange, shade: .shade5)
        case .processing:
            return .withColorStudio(.green, shade: .shade5)
        case .failed:
            return .withColorStudio(.red, shade: .shade5)
        }
    }
}

// MARK: Constants
private extension OrderStatusSection {
    enum Layout {
        enum StatusBadge {
            static let horizontalPadding: CGFloat = 12.0
            static let verticalPadding: CGFloat = 4.0
            static let cornerRadius: CGFloat = 4.0
        }
        static let linkButtonTrailingPadding: CGFloat = 22.0
    }

    enum Localization {
        static let editButton = NSLocalizedString("Edit", comment: "Button to edit an order status on the New Order screen")
    }
}

struct OrderStatusSection_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            ScrollView {
            OrderStatusSection(geometry: geometry, dateCreated: Date(), statusEnum: .pending)
            }
        }
    }
}
