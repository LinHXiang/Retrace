import SwiftUI

struct CommandHistoryItemView: View {
  @Bindable var item: CommandHistoryItemDecorator
  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags

  var body: some View {
    HStack(spacing: 6) {
      Button {
        appState.history.select(item)
      } label: {
        HStack(spacing: 6) {
          if item.isPinned { Image(systemName: "pin.fill") }
          VStack(alignment: .leading, spacing: 1) {
            if let alias = item.favorite?.alias, !alias.isEmpty {
              Text(item.highlightedAlias ?? AttributedString(alias)).lineLimit(1)
            }
            ListItemTitleView(attributedTitle: item.isSelected ? nil : item.attributedTitle, isSelected: item.isSelected) {
              Text(verbatim: item.title)
            }
          }
          Spacer(minLength: 0)
          ForEach(item.shortcuts) { shortcut in
            if shortcut.isVisible(item.shortcuts, modifierFlags.flags) { KeyboardShortcutView(shortcut: shortcut) }
          }
        }.contentShape(Rectangle())
      }
      Button {
        appState.navigator.select(item: item)
        appState.history.editingCommand = item.item.command
      } label: {
        Image(systemName: item.favorite == nil ? "star" : "star.fill").frame(width: 24, height: Popup.itemHeight)
      }.accessibilityLabel(Text("Edit favorite"))
    }
    .buttonStyle(.plain)
    .font(AppFont.bold())
    .foregroundStyle(item.isSelected ? Color.black : Color.white)
    .padding(.horizontal, 8)
    .frame(minHeight: Popup.itemHeight)
    .background(item.isSelected ? ConsoleTheme.accent : Color.white.opacity(0.001), in: CutCorner())
    .hoverSelectionId(item.id)
  }
}
