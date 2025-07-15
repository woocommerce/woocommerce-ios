import SwiftUI

struct PointOfSaleModalHeader: View {
    @Binding var isPresented: Bool
    @Binding var title: AttributedString

    var body: some View {
        HStack {
            Text(title)
                .font(.posHeadingBold)
                .lineLimit(1)
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
