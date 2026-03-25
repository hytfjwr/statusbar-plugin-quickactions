import Foundation
import StatusBarKit

@MainActor
@Observable
final class QuickActionsSettings: WidgetConfigProvider {
    static let shared = QuickActionsSettings()

    let configID = "quick-actions"
    private var suppressNotify = false

    var configPath: String {
        didSet { if !suppressNotify { WidgetConfigRegistry.shared.notifySettingsChanged() } }
    }

    private(set) var actions: [QuickAction] = []

    private init() {
        let cfg = WidgetConfigRegistry.shared.values(for: "quick-actions")
        configPath = cfg?["configPath"]?.stringValue
            ?? "~/.config/statusbar/plugins/quickactions.statusplugin/config.json"
        WidgetConfigRegistry.shared.register(self)
        loadActions()
    }

    // MARK: - WidgetConfigProvider

    func exportConfig() -> [String: ConfigValue] {
        ["configPath": .string(configPath)]
    }

    func applyConfig(_ values: [String: ConfigValue]) {
        suppressNotify = true
        defer { suppressNotify = false }
        if let v = values["configPath"]?.stringValue { configPath = v }
        loadActions()
    }

    // MARK: - Path Resolution

    var resolvedConfigPath: String {
        (configPath as NSString).expandingTildeInPath
    }

    // MARK: - JSON I/O

    private func loadActions() {
        let url = URL(fileURLWithPath: resolvedConfigPath)
        guard let data = try? Data(contentsOf: url) else {
            actions = []
            return
        }
        let config = try? JSONDecoder().decode(QuickActionsConfig.self, from: data)
        actions = config?.actions ?? []
    }

    private func saveActions() {
        let url = URL(fileURLWithPath: resolvedConfigPath)
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(QuickActionsConfig(actions: actions)) else { return }
        try? data.write(to: url)
    }

    // MARK: - CRUD

    func addAction(_ action: QuickAction) {
        actions.append(action)
        saveActions()
    }

    func updateAction(_ action: QuickAction) {
        guard let idx = actions.firstIndex(where: { $0.id == action.id }) else { return }
        actions[idx] = action
        saveActions()
    }

    func deleteAction(id: UUID) {
        actions.removeAll { $0.id == id }
        saveActions()
    }
}
