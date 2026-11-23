import SwiftUI

struct ContentView: View {
  @State private var appState = AppState.shared
  @State private var modifierFlags = ModifierFlags()
  @State private var scenePhase: ScenePhase = .background

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @FocusState private var searchFocused: Bool

  var body: some View {
    ZStack {
      PanelBackgroundView()

      KeyHandlingView(searchQuery: $appState.history.searchQuery, searchFocused: $searchFocused) {
        VStack(spacing: 0) {
          HeaderView(
            searchFocused: $searchFocused
          )

          HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
              CommandHistoryListView(
                searchFocused: $searchFocused
              )

              .disabled(appState.history.editingCommand != nil)
              FooterView(footer: appState.footer)
                .allowsHitTesting(appState.history.editingCommand == nil)
            }
            .padding(.horizontal, Popup.horizontalPadding)
            .frame(minWidth: Popup.minimumListWidth, minHeight: 0)
            .layoutPriority(1)

            if let command = appState.history.editingCommand {
              FavoriteEditor(command: command, favorite: appState.history.all.first { $0.item.command == command }?.favorite)
                .id(command)
            } else if let selectedCommandItem = appState.navigator.selectedCommandItem {
              CommandPreviewView(item: selectedCommandItem)
                .transition(.opacity)
            }
          }
          .onAppear {
            searchFocused = true
            ensurePreviewWidth()
          }
          .onChange(of: appState.navigator.selectedCommandItem?.id) {
            ensurePreviewWidth()
          }
          .onMouseMove {
            appState.navigator.isKeyboardNavigating = false
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .onChange(of: appState.history.editingCommand) { _, command in
        searchFocused = command == nil
        appState.popup.needsResize = true
      }
      .font(AppFont.regular())
      .task {
        try? await appState.history.loadIfChanged()
      }
    }
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: appState.searchVisible)
    .environment(\.colorScheme, .dark)
    .tint(ConsoleTheme.accent)
    .environment(appState)
    .environment(modifierFlags)
    .environment(\.scenePhase, scenePhase)
    // FloatingPanel is not a scene, so let's implement custom scenePhase..
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) {
      if let window = $0.object as? NSWindow,
         let bundleIdentifier = Bundle.main.bundleIdentifier,
         window.identifier == NSUserInterfaceItemIdentifier(bundleIdentifier) {
        scenePhase = .active
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) {
      if let window = $0.object as? NSWindow,
         let bundleIdentifier = Bundle.main.bundleIdentifier,
         window.identifier == NSUserInterfaceItemIdentifier(bundleIdentifier) {
        scenePhase = .background
        appState.history.editingCommand = nil
      }
    }
  }

  private func ensurePreviewWidth() {
    guard appState.navigator.selectedCommandItem != nil else { return }
    appState.appDelegate?.panel.ensureMinimumWidth(Popup.minimumWidthWithPreview)
  }
}

#Preview {
  ContentView()
    .environment(\.locale, .init(identifier: "en"))
}
