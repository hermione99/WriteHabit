import SwiftUI

struct EditorStylePickerView: View {
    @StateObject private var editorManager = EditorSettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                ForEach(EditorStyle.allCases) { style in
                    Button {
                        editorManager.setEditorStyle(style)
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: style.icon)
                                .font(.title2)
                                .foregroundStyle(style == editorManager.editorStyle ? .blue : .secondary)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(style.displayName.localized)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(style.description.localized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if editorManager.editorStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } footer: {
                Text("Choose your preferred writing interface. The simple editor offers a clean, paper-like experience with minimal distractions.".localized)
            }
        }
        .navigationTitle("Editor Style".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EditorStylePickerView()
    }
}
