import SwiftUI

struct PreviewItemView: View {
  var item: CommandHistoryItemDecorator

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ScrollView {
        Text(item.text)
          .font(.body.monospaced())
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      Spacer(minLength: 0)

      if item.showsRecordedAt {
        Divider()
          .padding(.vertical)

        HStack(spacing: 3) {
          Text("Recorded")
          Text(item.item.recordedAt, style: .date)
          Text(item.item.recordedAt, style: .time)
        }
      }
    }
    .controlSize(.small)
  }
}
