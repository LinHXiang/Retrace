import SwiftUI

struct FavoriteEditor: View {
  let command: String
  let favorite: FavoriteCommand?
  @State private var alias = ""
  @FocusState private var focused: Bool
  @Environment(AppState.self) private var appState

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Label("Edit favorite", systemImage: "star.fill").foregroundStyle(ConsoleTheme.accent)
      TextField("Alias (optional)", text: $alias)
        .focused($focused)
        .onSubmit(save)
      ScrollView { Text(verbatim: command).frame(maxWidth: .infinity, alignment: .leading) }
      HStack {
        if let favorite {
          Button("Remove favorite") { appState.history.removeFavorite(favorite) }
        }
        Spacer()
        Button("Cancel") { appState.history.editingCommand = nil }.keyboardShortcut(.cancelAction)
        Button("Save", action: save)
      }
    }
    .padding(10)
    .frame(width: Popup.previewWidth)
    .background(ConsoleTheme.surface)
    .onAppear { alias = favorite?.alias ?? ""; focused = true }
  }

  private func save() {
    appState.history.saveFavorite(.init(command: command, alias: alias, savedAt: favorite?.savedAt ?? Date()))
  }
}
