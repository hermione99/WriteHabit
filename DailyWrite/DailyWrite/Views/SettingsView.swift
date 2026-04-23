import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var fontManager = FontManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showBackupSheet = false
    @State private var showNotificationSettings = false
    @State private var backupMessage = ""
    @State private var showBackupAlert = false
    @State private var showingDeleteAccountConfirmation = false
    @State private var showingSignOutConfirmation = false
    @State private var showRecentlyDeleted = false
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // Notifications Section
                Section("Notifications".localized) {
                    Button {
                        showNotificationSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(.orange)
                            Text("Daily Reminder".localized)
                            Spacer()
                            Text(NotificationService.shared.isReminderEnabled ? "On".localized : "Off".localized)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                Section("Backup & Export".localized) {
                    Button {
                        Task {
                            await backupToICloud()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "icloud")
                                .foregroundStyle(themeManager.accent)
                            Text("Backup to iCloud".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    Button {
                        showBackupSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.green)
                            Text("Export Essays".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    Button {
                        showRecentlyDeleted = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.orange)
                            Text("Recently Deleted".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                Section("About".localized) {
                    HStack {
                        Text("Version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Account".localized) {
                    // Sign Out button
                    Button {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(themeManager.accent)
                            Text("Sign Out".localized)
                                .foregroundStyle(themeManager.accent)
                            Spacer()
                        }
                    }
                    
                    Button {
                        showingDeleteAccountConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .foregroundStyle(.red)
                            Text("Delete Account".localized)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                }
            }
            .alert("Sign Out?".localized, isPresented: $showingSignOutConfirmation) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Sign Out".localized, role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?".localized)
            }
            .navigationTitle("Settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBackupSheet) {
                BackupSheet()
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showRecentlyDeleted) {
                RecentlyDeletedView()
            }
            .alert("Backup".localized, isPresented: $showBackupAlert) {
                Button("OK".localized, role: .cancel) { }
            } message: {
                Text(backupMessage)
            }
            .alert("Delete Account?".localized, isPresented: $showingDeleteAccountConfirmation) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Delete".localized, role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all your data. This action cannot be undone.".localized)
            }
        }
    }
    
    private func backupToICloud() async {
        guard let user = Auth.auth().currentUser else {
            backupMessage = "Please sign in first".localized
            showBackupAlert = true
            return
        }
        
        let isAvailable = await CloudBackupService.shared.checkICloudStatus()
        guard isAvailable else {
            backupMessage = "iCloud not available. Please check Settings > iCloud.".localized
            showBackupAlert = true
            return
        }
        
        do {
            let essays = try await FirebaseService.shared.getUserEssays(userId: user.uid)
            await CloudBackupService.shared.backupAllEssays(essays)
            backupMessage = "Successfully backed up \(essays.count) essays to iCloud!".localized
            showBackupAlert = true
        } catch {
            backupMessage = "Backup failed: \(error.localizedDescription)".localized
            showBackupAlert = true
        }
    }
    
    private func deleteAccount() async {
        guard let user = Auth.auth().currentUser else {
            backupMessage = "Please sign in first".localized
            showBackupAlert = true
            return
        }
        
        do {
            // Delete user's essays
            let essays = try await FirebaseService.shared.getUserEssays(userId: user.uid)
            for essay in essays {
                if let essayId = essay.id {
                    try await FirebaseService.shared.deleteEssay(essayId: essayId)
                }
            }
            
            // Delete user profile
            try await FirebaseService.shared.deleteUserProfile(userId: user.uid)
            
            // Delete Firebase Auth account
            try await user.delete()
            
            backupMessage = "Account deleted successfully".localized
            showBackupAlert = true
            
            // Dismiss settings after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        } catch {
            backupMessage = "Failed to delete account: \(error.localizedDescription)".localized
            showBackupAlert = true
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            // Dismiss settings
            dismiss()
        } catch {
            backupMessage = "Failed to sign out: \(error.localizedDescription)".localized
            showBackupAlert = true
        }
    }
}


#Preview {
    SettingsView()
}

// MARK: - Backup Sheet

struct BackupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var exportFormat: ExportFormat = .markdown
    @State private var essayCount: Int = 0
    
    enum ExportFormat {
        case json, markdown, text
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Export Format".localized) {
                    ForEach([ExportFormat.json, .markdown, .text], id: \.self) { format in
                        Button {
                            exportFormat = format
                        } label: {
                            HStack {
                                Image(systemName: iconFor(format))
                                Text(displayNameFor(format))
                                Spacer()
                                if exportFormat == format {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(themeManager.accent)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await exportEssays()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Export \(essayCount) Essays".localized)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                }
                
                Section {
                    Text("Export your essays as a file you can save to Files, iCloud Drive, Google Drive, or share with others.".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Export Essays".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url], title: "Exported Essays".localized)
                }
            }
            .task {
                await loadEssayCount()
            }
        }
    }
    
    private func loadEssayCount() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let essays = try await FirebaseService.shared.getUserEssays(userId: userId)
            // Filter out deleted essays
            essayCount = essays.filter { $0.deletedAt == nil }.count
        } catch {
            print("Error loading essay count: \(error)")
        }
    }
    
    private func exportEssays() async {
        isExporting = true
        
        guard let user = Auth.auth().currentUser else {
            isExporting = false
            return
        }
        
        do {
            let essays = try await FirebaseService.shared.getUserEssays(userId: user.uid)
            
            let tempDir = FileManager.default.temporaryDirectory
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            
            var fileURL: URL?
            
            switch exportFormat {
            case .json:
                if let data = EssayExportService.shared.exportToJSON(essays: essays) {
                    fileURL = tempDir.appendingPathComponent("dailywrite_backup_\(dateString).json")
                    try? data.write(to: fileURL!)
                }
                
            case .markdown:
                let markdown = EssayExportService.shared.exportToMarkdown(essays: essays)
                fileURL = tempDir.appendingPathComponent("dailywrite_backup_\(dateString).md")
                try? markdown.write(to: fileURL!, atomically: true, encoding: .utf8)
                
            case .text:
                // Export first essay as text (or combine all)
                let text = essays.map { EssayExportService.shared.exportToText(essay: $0) }.joined(separator: "\n\n---\n\n")
                fileURL = tempDir.appendingPathComponent("dailywrite_backup_\(dateString).txt")
                try? text.write(to: fileURL!, atomically: true, encoding: .utf8)
            }
            
            if let url = fileURL {
                exportURL = url
                showShareSheet = true
            }
            
        } catch {
            print("Export error: \(error)")
        }
        
        isExporting = false
    }
    
    private func iconFor(_ format: ExportFormat) -> String {
        switch format {
        case .json: return "curlybraces"
        case .markdown: return "doc.text"
        case .text: return "doc.plaintext"
        }
    }
    
    private func displayNameFor(_ format: ExportFormat) -> String {
        switch format {
        case .json: return "JSON (Structured Data)".localized
        case .markdown: return "Markdown (Readable)".localized
        case .text: return "Plain Text".localized
        }
    }
}

// Localization strings needed:
// "Backup & Export" = "Backup & Export"
// "Backup to iCloud" = "Backup to iCloud"
// "Export Essays" = "Export Essays"
// "Please sign in first" = "Please sign in first"
// "iCloud not available. Please check Settings > iCloud." = "iCloud not available. Please check Settings > iCloud."
// "Successfully backed up %@ essays to iCloud!" = "Successfully backed up %@ essays to iCloud!"
// "Backup failed: %@" = "Backup failed: %@"
// "Export Format" = "Export Format"
// "JSON (Structured Data)" = "JSON (Structured Data)"
// "Markdown (Readable)" = "Markdown (Readable)"
// "Plain Text" = "Plain Text"
// "Export %@ Essays" = "Export %@ Essays"
// "Export your essays as a file you can save to Files, iCloud Drive, Google Drive, or share with others." = "Export your essays as a file you can save to Files, iCloud Drive, Google Drive, or share with others."
