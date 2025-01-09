import SwiftUI

extension View {
    func measureHeight(_ callback: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        callback(proxy.size.height)
                    }
                    .onChange(of: proxy.size.height) { newHeight in
                        callback(newHeight)
                    }
            }
        )
    }
}
