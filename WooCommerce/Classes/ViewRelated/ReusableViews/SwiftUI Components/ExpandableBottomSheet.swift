import SwiftUI

struct ExpandableBottomSheet<AlwaysVisibleContent, ExpandableContent>: View where AlwaysVisibleContent: View, ExpandableContent: View {
    @State private var isExpanded: Bool = false
    @State private var expandingContentHeight: CGFloat = 300 // Will be updated after first shown
    @State private var fixedContentHeight: CGFloat = 100 // Will be updated after first shown, excludes chevron
    @State private var panelHeight: CGFloat = 120 // Actual height of the content at any given time, includes chevron
    @State private var revealContentDuringDrag: Bool = false
    @GestureState private var isDragging: Bool = false

    @ViewBuilder private var alwaysVisibleContent: () -> AlwaysVisibleContent

    @ViewBuilder private var expandableContent: () -> ExpandableContent

    public init(@ViewBuilder alwaysVisibleContent: @escaping () -> AlwaysVisibleContent,
                @ViewBuilder expandableContent: @escaping () -> ExpandableContent) {
        self.alwaysVisibleContent = alwaysVisibleContent
        self.expandableContent = expandableContent
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chevron button to control view expansion
            Button(action: {
                withAnimation {
                    self.isExpanded.toggle()
                    panelHeight = calculateHeight()
                }
            }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: Layout.chevronHeight))
                    .rotationEffect(.degrees(self.isExpanded ? 180 : 0))
                    .padding(Layout.chevronPadding)
                    .foregroundColor(Color(uiColor: .primary))
            }

            Spacer()

            // Content that will expand/collapse
            Group {
                if isExpanded || revealContentDuringDrag {
                    expandableContent()
                        .background(GeometryReader { geometryProxy in
                            Color.clear
                                .onAppear(perform: {
                                    expandingContentHeight = geometryProxy.size.height
                                })
                                .onChange(of: geometryProxy.size.height,
                                          perform: { newValue in
                                    expandingContentHeight = newValue
                                    if !isDragging {
                                        withAnimation {
                                            panelHeight = calculateHeight()
                                        }
                                    }
                                })
                        })
                }
            }
            .clipped()

            // Always visible content
            alwaysVisibleContent()
                .background(GeometryReader { geometryProxy in
                    Color.clear
                        .onAppear(perform: {
                            fixedContentHeight = geometryProxy.size.height
                            panelHeight = calculateHeight()
                        })
                        .onChange(of: geometryProxy.size.height,
                                  perform: { newValue in
                            fixedContentHeight = newValue
                            if !isDragging {
                                withAnimation {
                                    panelHeight = calculateHeight()
                                }
                            }
                        })
                })
        }
        .background(Color(.listForeground(modal: true)))
        .frame(maxWidth: .infinity, maxHeight: panelHeight, alignment: .bottom)
        .cornerRadius(Layout.sheetCornerRadius)
        .shadow(radius: Layout.sheetCornerRadius)
        .mask(Rectangle().padding(.top, Layout.sheetCornerRadius * -2))
        .gesture(
            DragGesture()
                .updating($isDragging) { value, state, _ in
                    state = value.translation.height < 0
                }
                .onChanged { value in
                    let dragAmount = value.translation.height
                    revealContentDuringDrag = dragAmount < 0
                    withAnimation {
                        panelHeight = calculateHeight(offsetBy: dragAmount)
                    }
                }
                .onEnded { gesture in
                    withAnimation {
                        let dragAmount = gesture.predictedEndTranslation.height as CGFloat
                        let threshold: CGFloat = expandingContentHeight / 4

                        if dragAmount > threshold && isExpanded {
                            self.isExpanded = false
                        } else if dragAmount < -threshold && !isExpanded {
                            self.isExpanded = true
                        }
                        panelHeight = calculateHeight()
                        revealContentDuringDrag = false
                    }
                }
        )
        .edgesIgnoringSafeArea(.all)
    }

    private func calculateHeight(offsetBy dragAmount: CGFloat = 0) -> CGFloat {
        let collapsedHeight = fixedContentHeight + Layout.chevronHeight + (Layout.chevronPadding * 2)
        let fullHeight = collapsedHeight + expandingContentHeight
        let currentHeight = isExpanded ? fullHeight : collapsedHeight
        let dragAdjustedHeight = currentHeight - dragAmount

        // Prevent the view from shrinking below the minHeight when dragging down.
        return max(collapsedHeight, dragAdjustedHeight)
    }
}

fileprivate enum Layout {
    static let chevronHeight: CGFloat = 20
    static let chevronPadding: CGFloat = 8
    static let sheetCornerRadius: CGFloat = 10
}

struct ExpandableBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        ExpandableBottomSheet {
            Text("Always visible")
        } expandableContent: {
            Text("Can be hidden")
        }

    }
}
