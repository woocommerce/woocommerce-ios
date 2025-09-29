import SwiftUI

public extension View {
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
                    .onChange(of: proxy.size.height) { _, newHeight in
                        callback(newHeight)
                    }
            }
        )
    }

    /// Measures the width of a view and calls the provided callback with the width value.
    /// The callback is called both when the view first appears and whenever its height changes.
    /// - Parameter callback: A closure that receives the measured width as a CGFloat.
    /// - Returns: A modified view with width measurement capabilities.
    func measureWidth(_ callback: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        callback(proxy.size.width)
                    }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        callback(newWidth)
                    }
            }
        )
    }

    /// Measures the frame of a view in a global coordinate space and calls the provided callback with the frame value.
    ///
    func measureFrame(_ callback: @escaping (CGRect) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        callback(proxy.frame(in: .global))
                    }
                    .onChange(of: proxy.size.height) { _, newHeight in
                        callback(proxy.frame(in: .global))
                    }
                    .onChange(of: proxy.frame(in: .global)) { _, newHeight in
                        callback(proxy.frame(in: .global))
                    }
            }
        )
    }
}
