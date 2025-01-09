import SwiftUI

extension View {
    /// Measures the height of a view and calls the provided callback with the height value.
    /// The callback is called both when the view first appears and whenever its height changes.
    /// If the view contains a list, consider wrapping it in a VStack to ensure the height updates are emitted as a group 
    /// instead of individual elements.
    /// - Parameter callback: A closure that receives the measured height as a CGFloat.
    /// - Returns: A modified view with height measurement capabilities.
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
