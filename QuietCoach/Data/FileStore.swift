// FileStore.swift
// QuietCoach
//
// Manages audio file storage. All recordings stay on device.

import Foundation
import OSLog

final class FileStore {

    // MARK: - Singleton

    static let shared = FileStore()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "FileStore")
    private let fileManager = FileManager.default

    // MARK: - Initialization

    private init() {
        createRecordingsDirectoryIfNeeded()
    }

    // MARK: - Directory Management

    /// The recordings directory in Application Support
    var recordingsDirectory: URL {
        let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        return appSupport.appendingPathComponent(
            Constants.Directories.recordings,
            isDirectory: true
        )
    }

    /// Create the recordings directory if it doesn't exist
    private func createRecordingsDirectoryIfNeeded() {
        let path = recordingsDirectory.path

        if !fileManager.fileExists(atPath: path) {
            do {
                try fileManager.createDirectory(
                    at: recordingsDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                logger.info("Created recordings directory at \(path)")
            } catch {
                logger.error("Failed to create recordings directory: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - File Operations

    /// Get the full URL for an audio file
    func audioFileURL(for fileName: String) -> URL {
        recordingsDirectory.appendingPathComponent(fileName)
    }

    /// Generate a unique filename for a new recording
    func generateAudioFileName() -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        return "rehearsal_\(timestamp).m4a"
    }

    /// Delete an audio file
    func deleteAudioFile(named fileName: String) {
        let url = audioFileURL(for: fileName)

        do {
            try fileManager.removeItem(at: url)
            logger.info("Deleted audio file: \(fileName)")
        } catch {
            logger.error("Failed to delete audio file: \(error.localizedDescription)")
        }
    }

    /// Delete all audio files
    func deleteAllAudioFiles() {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: recordingsDirectory,
                includingPropertiesForKeys: nil
            )

            for file in files {
                try fileManager.removeItem(at: file)
            }

            logger.info("Deleted all audio files (\(files.count) files)")
        } catch {
            logger.error("Failed to delete all audio files: \(error.localizedDescription)")
        }
    }

    /// Check if an audio file exists
    func audioFileExists(named fileName: String) -> Bool {
        fileManager.fileExists(atPath: audioFileURL(for: fileName).path)
    }

    // MARK: - Storage Info

    /// Calculate total size of all recordings
    func totalRecordingsSize() -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: recordingsDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )

            return files.compactMap { url -> Int64? in
                let values = try? url.resourceValues(forKeys: [.fileSizeKey])
                return values?.fileSize.map { Int64($0) }
            }.reduce(0, +)
        } catch {
            logger.error("Failed to calculate recordings size: \(error.localizedDescription)")
            return 0
        }
    }

    /// Formatted storage size string
    var formattedRecordingsSize: String {
        ByteCountFormatter.string(
            fromByteCount: totalRecordingsSize(),
            countStyle: .file
        )
    }

    /// Number of recording files
    var recordingFileCount: Int {
        (try? fileManager.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: nil
        ).count) ?? 0
    }
}
