import SwiftUI

struct SegmentedView<Content: View>: View {
    @Binding private var selection: Int
    let content: Content


    /// Creates a picker that displays a custom label.
    ///
    /// - Parameters:
    ///     - selection: A binding to a property that determines the
    ///       currently-selected option.
    ///     - content: A view that contains the set of options.
    public init(selection: Binding<Int>, @ViewBuilder content: () -> Content) {
        _selection = selection
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<content.subv.count) { (index) in
                 
              }
        }
    }
}

struct SegmentedView_Previews: PreviewProvider {

    static var previews: some View {
        SegmentedView(selection: Binding.constant(0)) {
            Text("Ciao")
            Text("Hello")
        }
        .previewLayout(.fixed(width: 275, height: 50))
    }
}
