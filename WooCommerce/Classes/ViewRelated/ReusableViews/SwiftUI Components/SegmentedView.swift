import SwiftUI

struct SegmentedView<Content: View>: View {
    @State private var selectionState: Int {
        didSet {
            selection = selectionState
        }
    }
    @Binding private var selection: Int
    private let views: [Content]


    /// Creates a picker that displays a custom label.
    ///
    /// - Parameters:
    ///     - selection: A binding to a property that determines the
    ///       currently-selected option.
    ///     - views: A list of view that contains the set of options.
    public init(selection: Binding<Int>, views: [Content]) {
        _selectionState = State(initialValue: selection.wrappedValue)
        _selection = selection
        self.views = views
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<views.count) { (index) in
                VStack(spacing: 0) {
                    getContentView(index)
                    if index == selection {
                        Rectangle()
                            .frame(height: 3)
                            .foregroundColor(Color(.brand))
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

    func getContentView(_ index: Int) -> some View {
        return views[index]
            .frame(maxHeight: .infinity)
            .foregroundColor(index == selectionState ? Color(.brand) : Color(.textSubtle))
            .onTapGesture {
                selectionState = index
            }
    }

}

struct SegmentedView_Previews: PreviewProvider {

    static var previews: some View {
        SegmentedView(selection: Binding.constant(0),
                      views: [Text("Menu 1"), Text("Menu 2")])
            .previewLayout(.fixed(width: 275, height: 50))
    }
}
