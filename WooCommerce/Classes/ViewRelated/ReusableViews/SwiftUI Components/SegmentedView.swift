import SwiftUI

struct SegmentedView<Content: View>: View {
    @Binding private var selection: Int
    private let views: [Content]


    /// Creates a picker that displays a custom label.
    ///
    /// - Parameters:
    ///     - selection: A binding to a property that determines the
    ///       currently-selected option.
    ///     - views: A list of view that contains the set of options.
    public init(selection: Binding<Int>, views: [Content]) {
        _selection = selection
        self.views = views
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<views.count) { (index) in
                VStack {
                    views[index]
                        .frame(maxHeight: .infinity)
                        .foregroundColor(index == selection ? Color(.brand) : Color(.text))
                        .onTapGesture(perform: {
                            selection = index
                        })
                    if index == selection {
                        Rectangle()
                            .frame(height: 3)
                            .foregroundColor(Color(.brand))
                            .animation(.interactiveSpring())

                    }
                    else {
                        Rectangle()
                            .frame(height: 3)
                            .foregroundColor(Color(.clear))
                    }
                }
            }
        }
    }


}

struct SegmentedView_Previews: PreviewProvider {

    static var previews: some View {
        SegmentedView(selection: Binding.constant(0),
                      views: [Text("Ciao"), Text("Hello")])
            .previewLayout(.fixed(width: 275, height: 50))
    }
}
