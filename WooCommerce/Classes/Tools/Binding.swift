import struct SwiftUI.Binding

/// `Binding` resides inside `SwiftUI`.
/// This alias allows us to use it inside view models to communicate with `SwiftUI` views without having the import the module on each file.
///
typealias Binding = SwiftUI.Binding
