import SwiftUI

struct ListItemTitleView<Title: View>: View {
  var attributedTitle: AttributedString?
  var isSelected: Bool
  @ViewBuilder var title: () -> Title

  var body: some View {
    if let attributedTitle {
      Text(attributedTitle)
        .accessibilityIdentifier("command-history-item")
        .lineLimit(1)
        .truncationMode(.middle)
    } else {
      title()
        .accessibilityIdentifier("command-history-item")
        .lineLimit(1)
        .truncationMode(.middle)
        .foregroundStyle(isSelected ? Color.white : .primary)
        // Workaround for macOS 26 to avoid flipped text.
        .drawingGroup()
    }
  }
}
