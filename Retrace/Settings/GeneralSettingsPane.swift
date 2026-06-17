import AppKit
import SwiftUI
import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import Settings

struct GeneralSettingsPane: View {
  @Default(.searchMode) private var searchMode
  @Default(.commandHistorySize) private var commandHistorySize
  @Default(.historySources) private var historySources

  private let sizeFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimum = 1
    formatter.maximum = 999
    return formatter
  }()

  var body: some View {
    Settings.Container(contentWidth: 620) {
      Settings.Section(title: "", bottomDivider: true) {
        LaunchAtLogin.Toggle {
          Text("LaunchAtLogin", tableName: "GeneralSettings")
        }
      }

      Settings.Section(label: { Text("Open", tableName: "GeneralSettings") }) {
        KeyboardShortcuts.Recorder(for: .popup, onChange: { newShortcut in
          if newShortcut == nil {
            // No shortcut is recorded. Remove keys monitor
            AppState.shared.popup.deinitEventsMonitor()
          } else {
            // User is using shortcut. Ensure keys monitor is initialized
            AppState.shared.popup.initEventsMonitor()
          }
        })
          .help(Text("OpenTooltip", tableName: "GeneralSettings"))
      }

      Settings.Section(
        bottomDivider: true,
        label: { Text("Search", tableName: "GeneralSettings") }
      ) {
        Picker("", selection: $searchMode) {
          ForEach(Search.Mode.allCases) { mode in
            Text(mode.description)
          }
        }
        .labelsHidden()
        .frame(width: 180, alignment: .leading)
      }

      Settings.Section(
        bottomDivider: true,
        label: { Text("CommandHistorySize", tableName: "GeneralSettings") }
      ) {
        HStack {
          TextField("", value: $commandHistorySize, formatter: sizeFormatter)
            .frame(width: 80)
            .help(Text("CommandHistorySizeTooltip", tableName: "GeneralSettings"))
          Stepper("", value: $commandHistorySize, in: 1...999)
            .labelsHidden()
        }
      }

      Settings.Section(
        label: { Text("HistorySources", tableName: "GeneralSettings") }
      ) {
        VStack(alignment: .leading, spacing: 8) {
          if historySources.isEmpty {
            Text("NoHistorySources", tableName: "GeneralSettings")
              .foregroundStyle(.secondary)
          } else {
            ForEach($historySources) { $source in
              HistorySourceRow(source: $source) {
                removeHistorySource(id: source.id)
              }
            }
          }

          HStack(spacing: 8) {
            Button {
              addHistorySource()
            } label: {
              Label {
                Text("AddHistorySource", tableName: "GeneralSettings")
              } icon: {
                Image(systemName: "plus")
              }
            }

            Button {
              historySources = HistorySource.defaultSources
            } label: {
              Label {
                Text("RestoreHistorySources", tableName: "GeneralSettings")
              } icon: {
                Image(systemName: "arrow.uturn.backward")
              }
            }
          }
          .controlSize(.small)
        }
      }
    }
    .onChange(of: historySources) {
      reloadHistory()
    }
  }

  private func addHistorySource() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.showsHiddenFiles = true

    guard panel.runModal() == .OK,
          let url = panel.url else { return }

    if let index = historySources.firstIndex(where: { $0.url == url }) {
      historySources[index].kind = ShellHistoryKind.infer(from: url)
      historySources[index].isEnabled = true
      return
    }

    historySources.append(HistorySource(kind: ShellHistoryKind.infer(from: url), url: url))
  }

  private func removeHistorySource(id: UUID) {
    historySources.removeAll { $0.id == id }
  }

  private func reloadHistory() {
    Task { @MainActor in
      await AppState.shared.history.reloadSources()
    }
  }
}

private struct HistorySourceRow: View {
  @Binding var source: HistorySource
  var remove: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Toggle("", isOn: $source.isEnabled)
        .labelsHidden()

      Picker("", selection: $source.kind) {
        ForEach(ShellHistoryKind.allCases) { kind in
          Text(kind.description)
        }
      }
      .labelsHidden()
      .frame(width: 80)

      Text(source.url.path)
        .lineLimit(1)
        .truncationMode(.middle)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.secondary)

      Button {
        chooseFile()
      } label: {
        Image(systemName: "folder")
      }
      .buttonStyle(.borderless)
      .help(Text("ChooseHistorySource", tableName: "GeneralSettings"))

      Button(role: .destructive) {
        remove()
      } label: {
        Image(systemName: "minus.circle")
      }
      .buttonStyle(.borderless)
      .help(Text("RemoveHistorySource", tableName: "GeneralSettings"))
    }
    .controlSize(.small)
  }

  private func chooseFile() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.showsHiddenFiles = true

    guard panel.runModal() == .OK,
          let url = panel.url else { return }

    source.url = url
    source.kind = ShellHistoryKind.infer(from: url)
  }
}

#Preview {
  GeneralSettingsPane()
    .environment(\.locale, .init(identifier: "en"))
}
