import SwiftUI

struct PreviewItemView: View {
  var item: HistoryItemDecorator

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ScrollView {
        Text(item.text)
          .font(.body.monospaced())
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      Spacer(minLength: 0)

      Divider()
        .padding(.vertical)

      HStack(spacing: 3) {
        Text("Recorded")
        Text(item.item.lastCopiedAt, style: .date)
        Text(item.item.lastCopiedAt, style: .time)
      }
    }
    .controlSize(.small)
  }
}
