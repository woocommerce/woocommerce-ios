import SwiftUI

struct StatusIcon: View {
    enum Status: CaseIterable {
        case notStarted
        case running
        case success
        case failure
    }

    let status: Status

    @State private var isRotating = false

    var body: some View {
        switch status {
        case .notStarted:
            Image(uiImage: UIImage.checkEmptyCircleImage)
                .foregroundStyle(Color(uiColor: UIColor.opaqueSeparator))
        case .running:
            Image(uiImage: .circlePartialSuccessImage)
                .environment(\.colorScheme, .light)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
                .onAppear {
                    isRotating = true
                }
        case .success:
            Image(uiImage: .checkCircleImage)
                .environment(\.colorScheme, .light)
        case .failure:
            Image(uiImage: .exclamationFilledImage)
                .foregroundColor(Color(uiColor: .error))
        }
    }
}

#Preview {
    VStack {
        ForEach(StatusIcon.Status.allCases, id: \.self) { status in
            StatusIcon(status: status)
        }
    }
}
