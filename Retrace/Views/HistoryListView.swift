import Defaults
import SwiftUI

struct HistoryListView: View {
  @FocusState.Binding var searchFocused: Bool

  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags
  @Environment(\.scenePhase) private var scenePhase

  @Default(.showFooter) private var showFooter

  private var visibleItems: [CommandHistoryItemDecorator] {
    appState.history.visibleItems
  }

  private var topPadding: CGFloat {
    return Popup.verticalSeparatorPadding
  }

  private var bottomPadding: CGFloat {
    return showFooter
      ? Popup.verticalSeparatorPadding
      : (Popup.verticalSeparatorPadding - 1)
  }

  private func topSeparator() -> some View {
    Divider()
      .padding(.horizontal, Popup.horizontalSeparatorPadding)
      .padding(.top, Popup.verticalSeparatorPadding)
  }

  var body: some View {
    VStack(spacing: 0) {
      topSeparator()
    }
    .padding(.top, topPadding)
    .readHeight(appState, into: \.popup.extraTopHeight)

    ScrollView {
      ScrollViewReader { proxy in
        IdentifiableListView(items: visibleItems) { item in
          CommandHistoryItemView(item: item)
        }
        .padding(.top, Popup.verticalSeparatorPadding)
        .padding(.bottom, bottomPadding)
        .task(id: appState.navigator.scrollTarget) {
          guard appState.navigator.scrollTarget != nil else { return }

          try? await Task.sleep(for: .milliseconds(10))
          guard !Task.isCancelled else { return }

          if let selection = appState.navigator.scrollTarget {
            proxy.scrollTo(selection)
            appState.navigator.scrollTarget = nil
          }
        }
        .onChange(of: scenePhase) {
          if scenePhase == .active {
            searchFocused = true
            appState.navigator.isKeyboardNavigating = true
            appState.navigator.select(item: appState.history.visibleItems.first)
          } else {
            modifierFlags.flags = []
            appState.navigator.isKeyboardNavigating = true
            appState.preview.cancelAutoOpen()
          }
        }
        // Calculate the total height inside a scroll view.
        .background {
          GeometryReader { geo in
            Color.clear
              .task(id: appState.popup.needsResize) {
                try? await Task.sleep(for: .milliseconds(10))
                guard !Task.isCancelled else { return }

                if appState.popup.needsResize {
                  appState.popup.resize(height: geo.size.height)
                }
              }
          }
        }
      }
      .contentMargins(.leading, 10, for: .scrollIndicators)
      .contentMargins(.top, Popup.verticalSeparatorPadding, for: .scrollIndicators)
      .contentMargins(.bottom, bottomPadding, for: .scrollIndicators)
    }

    EmptyView()
      .readHeight(appState, into: \.popup.extraBottomHeight)
  }
}
