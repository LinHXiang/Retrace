import SwiftUI

struct CommandHistoryItemView: View {
  @Bindable var item: CommandHistoryItemDecorator

  @Environment(AppState.self) private var appState

  var body: some View {
    ListItemView(
      id: item.id,
      selectionId: item.id,
      attributedTitle: item.attributedTitle,
      shortcuts: item.shortcuts,
      isSelected: item.isSelected
    ) {
      Text(verbatim: item.title)
    }
    .font(AppFont.bold())
    .onTapGesture {
      Task {
        appState.history.select(item)
      }
    }
  }
}
