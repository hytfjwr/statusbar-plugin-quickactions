import SwiftUI

public struct QuickActionsSettingsView: View {
    let settings = QuickActionsSettings.shared
    @State private var editingAction: QuickAction?
    @State private var isAdding = false
    @State private var needsReload = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Actions").font(.headline)
                Spacer()
                Button {
                    isAdding = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }

            if settings.actions.isEmpty {
                Text("No actions configured.\nClick + to add an action.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 4) {
                    ForEach(settings.actions) { action in
                        HStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .frame(width: 20)
                            VStack(alignment: .leading) {
                                Text(action.label)
                                Text(action.command)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button("Edit") { editingAction = action }
                                .buttonStyle(.borderless)
                            Button("Delete") {
                                settings.deleteAction(id: action.id)
                                needsReload = true
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                    }
                }
            }

            if needsReload {
                HStack {
                    Text("Changes saved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        settings.loadActions()
                        needsReload = false
                    } label: {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                    .controlSize(.small)
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $isAdding) {
            ActionEditSheet(mode: .add) { action in
                settings.addAction(action)
                needsReload = true
            }
        }
        .sheet(item: $editingAction) { action in
            ActionEditSheet(mode: .edit(action)) { updated in
                settings.updateAction(updated)
                needsReload = true
            }
        }
    }
}

// MARK: - ActionEditSheet

private struct ActionEditSheet: View {
    enum Mode: Identifiable {
        case add
        case edit(QuickAction)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let a): a.id.uuidString
            }
        }
    }

    let mode: Mode
    let onSave: (QuickAction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var icon: String
    @State private var label: String
    @State private var command: String

    init(mode: Mode, onSave: @escaping (QuickAction) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            _icon = State(initialValue: "terminal")
            _label = State(initialValue: "")
            _command = State(initialValue: "")
        case .edit(let action):
            _icon = State(initialValue: action.icon)
            _label = State(initialValue: action.label)
            _command = State(initialValue: action.command)
        }
    }

    private var isValid: Bool {
        !icon.isEmpty && !label.isEmpty && !command.isEmpty
    }

    private var title: String {
        switch mode {
        case .add: "Add Action"
        case .edit: "Edit Action"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title).font(.headline)

            Form {
                TextField("SF Symbol Name", text: $icon)
                TextField("Label", text: $label)
                TextField("Command", text: $command)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let action: QuickAction
                    switch mode {
                    case .add:
                        action = QuickAction(icon: icon, label: label, command: command)
                    case .edit(let existing):
                        action = QuickAction(id: existing.id, icon: icon, label: label, command: command)
                    }
                    onSave(action)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 350)
    }
}
