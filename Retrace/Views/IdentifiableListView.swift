import SwiftUI

struct IdentifiableListView<Element, ID, Content>: View
    where ID: Hashable, Content: View, ID == Element.ID, Element: Identifiable {
  var items: [Element]
  var content: (Element) -> Content

  var body: some View {
    LazyVStack(spacing: 0) {
      ForEach(items) { element in
        content(element)
      }
    }
  }
}
