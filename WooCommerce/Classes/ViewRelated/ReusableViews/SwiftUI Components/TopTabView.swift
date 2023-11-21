import SwiftUI

struct TopTabItem {
    let name: String
    let view: AnyView
}

struct TopTabView: View {
    @State private var selectedTab = 0
    @State private var underlineOffset: CGFloat = 0
    @State private var tabWidths: [CGFloat]

    @Binding var isExpanded: Bool

    let tabs: [TopTabItem]

    init(tabs: [TopTabItem],
         isExpanded: Binding<Bool> = .constant(true)) {
        self.tabs = tabs
        self._isExpanded = isExpanded
        _tabWidths = State(initialValue: [CGFloat](repeating: 0, count: tabs.count))
    }

    var body: some View {
        VStack(spacing: 0) {
            if tabs.count > 1 && isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollViewProxy in
                        HStack(spacing: Layout.tabPadding * 2) {
                            ForEach(0..<tabs.count, id: \.self) { index in
                                VStack {
                                    Text(tabs[index].name)
                                        .font(.headline)
                                        .foregroundColor(selectedTab == index ? Colors.selected : .primary)
                                        .id(index)
                                        .onTapGesture {
                                            withAnimation {
                                                selectedTab = index
                                                underlineOffset = calculateOffset(index: index)
                                                scrollViewProxy.scrollTo(index, anchor: .center)
                                            }
                                        }
                                }
                                .padding()
                                .background(GeometryReader { geometry in
                                    Color.clear.onAppear {
                                        if index < tabWidths.count {
                                            tabWidths[index] = geometry.size.width
                                            if index == selectedTab {
                                                underlineOffset = calculateOffset(index: index)
                                            }
                                        }
                                    }
                                })
                            }
                        }
                        .padding(.horizontal, Layout.tabPadding)
                        .overlay(
                            Rectangle()
                                .frame(width: selectedTabUnderlineWidth(),
                                       height: Layout.selectedTabIndicatorHeight)
                                .foregroundColor(Colors.selected)
                                .offset(x: underlineOffset),
                            alignment: .bottomLeading
                        )
                    }
                }
                Divider()
            }

            // Display Content for selected tab
            tabs[safe: selectedTab]?.view
        }
    }

    private func selectedTabUnderlineWidth() -> CGFloat {
        guard let selectedTabWidth = tabWidths[safe: selectedTab] else {
            DDLogError("Out of bounds tab selected at index \(selectedTab)")
            return 0
        }
        return selectedTabWidth + (Layout.tabPadding * 2)
    }

    private func calculateOffset(index: Int) -> CGFloat {
        // Takes all preceeding tab widths, and adds appropriate spacing to each side to get the overall offset
        return tabWidths.prefix(index).reduce(0, +) + CGFloat(index) * (Layout.tabPadding * 2)
    }

    private enum Layout {
        static let tabPadding: CGFloat = 10
        static let selectedTabIndicatorHeight: CGFloat = 2
    }

    private enum Colors {
        static let selected: Color = .withColorStudio(name: .wooCommercePurple, shade: .shade50)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let tabs: [TopTabItem] = [
            TopTabItem(name: "A tab name", view: AnyView(Text("Content for Tab 1")
                .font(.largeTitle)
                .padding())),
            TopTabItem(name: "Tab2", view: AnyView(Text("Content for Tab 2")
                .font(.largeTitle)
                .padding())),
            TopTabItem(name: "More detail", view: AnyView(Text("Content for Tab 3")
                .font(.largeTitle)
                .padding())),
            TopTabItem(name: "A really long tab name", view: AnyView(Text("Content for Tab 4")
                .font(.largeTitle)
                .padding())),
            TopTabItem(name: "Tab", view: AnyView(Text("Content for Tab 5")
                .font(.largeTitle)
                .padding())),
        ]
        TopTabView(tabs: tabs)
            .previewLayout(.sizeThatFits)

        let oneTab: [TopTabItem] = [
            TopTabItem(name: "A tab name", view: AnyView(Text("Content for Tab 1")
                .font(.largeTitle)
                .padding()))
        ]
        TopTabView(tabs: oneTab)
            .previewLayout(.sizeThatFits)
    }
}
