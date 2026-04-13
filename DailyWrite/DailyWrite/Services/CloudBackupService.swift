import Foundation
import CloudKit
import UniformTypeIdentifiers

// Backs up essays to iCloud using CloudKit
class CloudBackupService {
    static let shared = CloudBackupService()
    
    private let container = CKContainer.default()
    private var database: CKDatabase {
        return container.privateCloudDatabase
    }
    
    // Check iCloud availability
    func checkICloudStatus() async -> Bool {
        do {
            let accountStatus = try await container.accountStatus()
            return accountStatus == .available
        } catch {
            print("iCloud check error: \(error)")
            return false
        }
    }
    
    // Backup a single essay to iCloud
    func backupEssay(_ essay: Essay) async throws {
        let record = CKRecord(recordType: "EssayBackup")
        record["essayId"] = essay.id
        record["keyword"] = essay.keyword
        record["title"] = essay.title
        record["content"] = essay.content
        record["visibility"] = essay.visibility.rawValue
        record["isDraft"] = essay.isDraft
        record["createdAt"] = essay.createdAt
        record["updatedAt"] = essay.updatedAt
        record["authorId"] = essay.authorId
        
        _ = try await database.save(record)
        print("Essay backed up to iCloud: \(essay.id)")
    }
    
    // Backup all user essays
    func backupAllEssays(_ essays: [Essay]) async {
        for essay in essays {
            do {
                try await backupEssay(essay)
            } catch {
                print("Failed to backup essay \(essay.id): \(error)")
            }
        }
    }
    
    // Restore essays from iCloud
    func restoreEssays() async throws -> [EssayBackup] {
        let query = CKQuery(recordType: "EssayBackup", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (matchResults, _) = try await database.records(matching: query)
        
        return matchResults.compactMap { (recordID, result) -> EssayBackup? in
            guard let record = try? result.get() else { return nil }
            return EssayBackup(from: record)
        }
    }
    
    // Delete old backups (keep last 30 days)
    func cleanupOldBackups() async {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -30, to: Date()) else { return }
        
        let predicate = NSPredicate(format: "createdAt < %@", cutoffDate as NSDate)
        let query = CKQuery(recordType: "EssayBackup", predicate: predicate)
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            for (recordID, result) in matchResults {
                if let record = try? result.get() {
                    try await database.deleteRecord(withID: record.recordID)
                }
            }
        } catch {
            print("Cleanup error: \(error)")
        }
    }
}

// Backup model
struct EssayBackup: Identifiable {
    let id: String
    let essayId: String
    let keyword: String
    let title: String
    let content: String
    let visibility: String
    let isDraft: Bool
    let createdAt: Date
    let updatedAt: Date
    let authorId: String
    
    init(from record: CKRecord) {
        self.id = record.recordID.recordName
        self.essayId = record["essayId"] as? String ?? ""
        self.keyword = record["keyword"] as? String ?? ""
        self.title = record["title"] as? String ?? ""
        self.content = record["content"] as? String ?? ""
        self.visibility = record["visibility"] as? String ?? "private"
        self.isDraft = record["isDraft"] as? Bool ?? false
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.updatedAt = record["updatedAt"] as? Date ?? Date()
        self.authorId = record["authorId"] as? String ?? ""
    }
}

// MARK: - Essay Export Service

// Exports essays to files that can be saved to Files app or Google Drive
class EssayExportService {
    static let shared = EssayExportService()
    
    // Export as JSON
    func exportToJSON(essays: [Essay]) -> Data? {
        let exportData = essays.map { essay -> [String: Any] in
            return [
                "id": essay.id,
                "keyword": essay.keyword,
                "title": essay.title,
                "content": essay.content,
                "visibility": essay.visibility.rawValue,
                "isDraft": essay.isDraft,
                "createdAt": ISO8601DateFormatter().string(from: essay.createdAt),
                "updatedAt": ISO8601DateFormatter().string(from: essay.updatedAt),
                "authorId": essay.authorId
            ]
        }
        
        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    // Export as Markdown (for easy reading)
    func exportToMarkdown(essays: [Essay]) -> String {
        var markdown = "# DailyWrite Backup\n\n"
        let dateStr = Date().formatted(date: .long, time: .shortened)
        markdown += "Exported: \(dateStr)\n\n"
        markdown += "---\n\n"
        
        for essay in essays {
            markdown += "## \(essay.keyword)\n"
            if !essay.title.isEmpty {
                markdown += "**Title:** \(essay.title)\n"
            }
            let essayDate = essay.createdAt.formatted(date: .long, time: .shortened)
            markdown += "**Date:** \(essayDate)\n"
            let status = essay.isDraft ? "Draft" : essay.visibility.displayName
            markdown += "**Status:** \(status)\n\n"
            markdown += "\(essay.content)\n\n"
            markdown += "---\n\n"
        }
        
        return markdown
    }
    
    // Export as plain text (one file per essay)
    func exportToText(essay: Essay) -> String {
        var text = "Keyword: \(essay.keyword)\n"
        if !essay.title.isEmpty {
            text += "Title: \(essay.title)\n"
        }
        let essayDate = essay.createdAt.formatted(date: .long, time: .shortened)
        text += "Date: \(essayDate)\n"
        text += "---\n\n"
        text += essay.content
        return text
    }
}

// MARK: - Usage in Views

// Add this to ProfileView or SettingsView for backup options:

/*
// In your view body:
Section("Backup") {
    Button("Backup to iCloud") {
        Task {
            await backupToICloud()
        }
    }
    
    Button("Export to Files") {
        showingExportSheet = true
    }
    
    Button("Export to Google Drive") {
        exportToGoogleDrive()
    }
}

// Functions:
private func backupToICloud() async {
    guard await CloudBackupService.shared.checkICloudStatus() else {
        showAlert("iCloud not available. Please check Settings.")
        return
    }
    
    do {
        let essays = try await FirebaseService.shared.getUserEssays(userId: userId)
        await CloudBackupService.shared.backupAllEssays(essays)
        showAlert("Backup complete!")
    } catch {
        showAlert("Backup failed: \(error.localizedDescription)")
    }
}

private func exportToGoogleDrive() {
    // Export as file and open share sheet
    let essays = // get user's essays
    if let jsonData = EssayExportService.shared.exportToJSON(essays: essays) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("dailywrite_backup.json")
        try? jsonData.write(to: tempURL)
        
        // Present share sheet
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        // Present from your view controller
    }
}
*/
