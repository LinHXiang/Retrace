import SwiftUI

struct HistoryItemListView<Element, ID, Content>: View
    where ID: Hashable, Content: View, ID == Element.ID, Element: Identifiable {
  var items: [Element]
  var content: (Element, Int) -> Content

  var body: some View {
    LazyVStack(spacing: 0) {
      ForEach(Array(items.enumerated()), id: \.element.id) { (index, element) in
        content(element, index)
      }
    }
  }
}
