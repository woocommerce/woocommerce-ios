import SwiftUI

struct ARHintRow: View {
    let iconName: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

            Text(label)
                .font(.system(size: 13.5))
                .lineSpacing(13.5 * 0.35)
                .foregroundStyle(.white.opacity(0.62))
        }
    }
}
