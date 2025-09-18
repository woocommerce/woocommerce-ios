import SwiftUI

public struct SizeTracker: ViewModifier {
    @Binding var size: CGSize

    public init(size: Binding<CGSize>) {
        self._size = size
    }

    public func body(content: Content) -> some View {
        content
            .background(GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        self.size = proxy.size
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        self.size = newSize
                    }
            })
    }
}

public extension View {
    func trackSize(size: Binding<CGSize>) -> some View {
        modifier(SizeTracker(size: size))
    }
}
