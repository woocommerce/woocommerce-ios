import SwiftUI

struct POSErrorExclamationMark: View {
    var body: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: 64))
            .foregroundStyle(Color.wooAmberShade60)
    }
}

#Preview {
    POSErrorExclamationMark()
}
