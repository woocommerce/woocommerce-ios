import SwiftUI

struct PlusButtonView: View {
    private var buttonTapped: (() -> Void)?

    init(buttonTapped: (() -> Void)? = nil) {
        self.buttonTapped = buttonTapped
    }

    var body: some View {
        Button(action: {
            buttonTapped?()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.clear))
        }
    }
}

#Preview {
    PlusButtonView(buttonTapped: { })
}
