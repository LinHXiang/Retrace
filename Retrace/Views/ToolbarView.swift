import Defaults
import KeyboardShortcuts
import SwiftUI

private struct KeyboardShortcutHelpModifier: ViewModifier {
  let name: KeyboardShortcuts.Name
  let key: String
  let tableName: String
  let comment: String = ""
  let replacementKey: String

  func body(content: Content) -> some View {
    if let shortcut = KeyboardShortcuts.Shortcut(name: name) {
      content
        .help(
          Text(
            NSLocalizedString(key, tableName: tableName, comment: comment)
              .replacingOccurrences(
                of: "{\(replacementKey)}",
                with: shortcut.description
              )
          )
        )
    } else {
      content
    }
  }
}

struct ToolbarButton<Label: View>: View {
  @Environment(AppState.self) private var appState

  let action: @MainActor () -> Void
  let label: () -> Label

  var body: some View {
    Button(action: action) {
      label()
    }
    .buttonStyle(.plain)
    .frame(height: 23)
    .onHover(perform: { inside in
      if let window = appState.appDelegate?.panel {
        window.isMovableByWindowBackground = !inside
      }
    })
  }

  func shortcutKeyHelp(
    name: KeyboardShortcuts.Name,
    key: String,
    tableName: String,
    replacementKey: String
  ) -> some View {
    self.modifier(
      KeyboardShortcutHelpModifier(
        name: name,
        key: key,
        tableName: tableName,
        replacementKey: replacementKey
      )
    )
  }

}

struct ToolbarView: View {
  @State private var appState = AppState.shared

  var body: some View {
    HStack {
      if !appState.navigator.selection.isEmpty {
        Spacer()

        ToolbarButton {
          appState.deleteSelection()
        } label: {
          Image(systemName: "trash")
        }
        .shortcutKeyHelp(
          name: .delete,
          key: "DeleteKey",
          tableName: "PreviewItemView",
          replacementKey: "deleteKey"
        )
      }
    }
  }
}
