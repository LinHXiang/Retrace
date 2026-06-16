import SwiftUI

struct ListItemView<Title: View, ID: Hashable>: View {
  var id: ID
  var selectionId: UUID
  var attributedTitle: AttributedString?
  var shortcuts: [KeyShortcut]
  var isSelected: Bool
  var help: LocalizedStringKey?
  @ViewBuilder var title: () -> Title

  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags

  var body: some View {
    HStack(spacing: 0) {
      Spacer()
        .frame(width: 10)

      ListItemTitleView(attributedTitle: attributedTitle, title: title)
        .padding(.trailing, 5)

      Spacer()

      HStack(spacing: 5) {
        if !shortcuts.isEmpty {
          ZStack(alignment: .trailing) {
            ForEach(shortcuts) { shortcut in
              let visible = shortcut.isVisible(shortcuts, modifierFlags.flags)
              KeyboardShortcutView(shortcut: shortcut)
                .opacity(visible ? 1 : 0)
                .frame(width: visible ? nil : 0)
            }
          }
        }
      }
      .padding(.trailing, 10)
    }
    .frame(minHeight: Popup.itemHeight)
    .id(id)
    .frame(maxWidth: .infinity, alignment: .leading)
    .foregroundStyle(isSelected ? Color.white : .primary)
    // macOS 26 broke hovering if no background is present.
    // The slight opcaity white background is a workaround
    .background(isSelected ? Color.accentColor.opacity(0.8) : .white.opacity(0.001))
    .clipShape(.rect(cornerRadius: Popup.cornerRadius))
    .hoverSelectionId(selectionId)
    .help(help ?? "")
  }
}
