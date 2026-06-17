import SwiftUI

struct FooterItemView: View {
  @Bindable var item: FooterItem
  @Environment(AppState.self) private var appState

  var body: some View {
    ListItemView(id: item.id, selectionId: item.id, shortcuts: item.shortcuts, isSelected: item.isSelected) {
      Text(LocalizedStringKey(item.title))
    }
    .onTapGesture {
      appState.navigator.selectWithoutScrolling(id: item.id)
      item.action()
    }
    .onHover { hovering in
      if hovering && appState.preview.state.isOpen {
        appState.preview.togglePreview()
      }
    }
  }
}
