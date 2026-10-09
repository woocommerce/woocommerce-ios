import SwiftUI

struct PointOfSaleModalHeader: View {
    @Binding var isPresented: Bool
    @Binding var title: AttributedString

    var body: some View {
        HStack {
            Text(title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .fixedSize(horizontal: false, vertical: true)
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
