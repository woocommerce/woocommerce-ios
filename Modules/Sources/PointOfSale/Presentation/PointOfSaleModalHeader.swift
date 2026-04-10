import SwiftUI

struct PointOfSaleModalHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding var isPresented: Bool
    @Binding var title: AttributedString

    var body: some View {
        HStack {
            Text(title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            Spacer()
            Button {
                isPresented = false
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
        }
        .foregroundColor(Color.posOnSurface)
    }
}
