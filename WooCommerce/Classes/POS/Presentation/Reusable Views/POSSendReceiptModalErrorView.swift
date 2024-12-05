import SwiftUI

struct POSSendReceiptModalErrorView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("Something went wrong. Please retry.")
        }
        .posModalCloseButton(action: {
            isPresented = false
        })
    }
}

#Preview {
    POSSendReceiptModalErrorView(isPresented: .constant(true))
}
