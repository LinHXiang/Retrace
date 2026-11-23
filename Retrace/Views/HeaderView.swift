import SwiftUI

struct HeaderView: View {
  @State private var appState = AppState.shared
  @FocusState.Binding var searchFocused: Bool

  var body: some View {
    HStack(spacing: 8) {
      if appState.searchVisible {
        ListHeaderView(searchFocused: $searchFocused, searchQuery: $appState.history.searchQuery)
      }
      Spacer(minLength: 0)
      if let removed = appState.history.removedFavorite {
        Button("Undo removal") { appState.history.saveFavorite(removed) }
      }
      Button {
        appState.history.toggleFavoritesFilter()
      } label: {
        Label(appState.history.favoritesOnly ? "Favorites" : "All commands", systemImage: appState.history.favoritesOnly ? "star.fill" : "line.3.horizontal.decrease")
          .padding(.horizontal, 9).padding(.vertical, 4)
          .background(appState.history.favoritesOnly ? ConsoleTheme.accent : ConsoleTheme.surface, in: CutCorner())
          .foregroundStyle(appState.history.favoritesOnly ? Color.black : .white)
      }.buttonStyle(.plain).help("Toggle favorites (⇧⌘F)")
    }
    .disabled(appState.history.editingCommand != nil)
    .padding(.vertical, 5).padding(.horizontal, 10)
    .readHeight(appState, into: \.popup.headerHeight)
  }
}
