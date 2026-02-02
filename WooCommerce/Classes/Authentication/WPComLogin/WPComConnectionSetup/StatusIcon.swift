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
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color(uiColor: UIColor.opaqueSeparator))
        case .running:
            Image(uiImage: .circlePartialSuccessImage)
                .resizable()
                .scaledToFit()
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        isRotating = true
                    }
                }
        case .success:
            Image(uiImage: .checkCircleImage)
                .resizable()
                .scaledToFit()
        case .failure:
            Image(uiImage: .exclamationFilledImage)
                .resizable()
                .scaledToFit()
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
