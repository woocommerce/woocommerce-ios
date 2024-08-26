import SwiftUI

extension View {
    func withoutAnimation() -> some View {
        return self.animation(nil, value: UUID())
    }
}
