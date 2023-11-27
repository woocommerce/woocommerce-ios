import SwiftUI

struct TopTabItem {
    let name: String
    let view: AnyView
    let onSelected: (() -> Void)?

    init(name: String,
         view: AnyView,
         onSelected: (() -> Void)? = nil) {
        self.name = name
        self.view = view
        self.onSelected = onSelected
    }
}

struct TopTabView: View {
    @State private var selectedTab = 0
    @State private var underlineOffset: CGFloat = 0
    @State private var tabWidths: [CGFloat]

    @Binding var showTabs: Bool

    let tabs: [TopTabItem]

    init(tabs: [TopTabItem],
         showTabs: Binding<Bool> = .constant(true)) {
        self.tabs = tabs
        self._showTabs = showTabs
        _tabWidths = State(initialValue: [CGFloat](repeating: 0, count: tabs.count))
    }

    var body: some View {
        VStack(spacing: 0) {
            if tabs.count > 1 && showTabs {
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
                                                tabs[selectedTab].onSelected?()
                                                underlineOffset = calculateOffset(index: index)
                                                scrollViewProxy.scrollTo(index, anchor: .center)
                                            }
                                        }
                                        .accessibilityAddTraits(.isButton)
                                        .accessibilityAddTraits(selectedTab == index ? [.isSelected, .isHeader] : [])
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
            ZStack {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Group {
                        if selectedTab == index {
                            tabs[index].view
                                .gesture(
                                    DragGesture().onEnded { gesture in
                                        let horizontalAmount = gesture.translation.width as CGFloat
                                        let shouldChangeTab = abs(horizontalAmount) > 50 // Threshold to avoid accidental swipes

                                        if shouldChangeTab {
                                            if horizontalAmount > 0 {
                                                // swipe right, go to previous tab if possible
                                                let previousTab = max(selectedTab - 1, 0)
                                                changeToTab(index: previousTab)
                                            } else {
                                                // swipe left, go to next tab if possible
                                                let nextTab = min(selectedTab + 1, tabs.count - 1)
                                                changeToTab(index: nextTab)
                                            }
                                        }
                                    }
                                )
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width)
                }
            }
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

    private func changeToTab(index: Int) {
        withAnimation {
            selectedTab = index
            tabs[selectedTab].onSelected?()
            underlineOffset = calculateOffset(index: index)
        }
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
