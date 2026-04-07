import Foundation
import Combine
import Compression

// MARK: - Protocol

protocol StorageServiceProtocol {
    var itemsPublisher: AnyPublisher<[WarrantyItem], Never> { get }
    var settingsPublisher: AnyPublisher<AppSettings, Never> { get }
    
    func loadAllItems()
    func save(_ item: WarrantyItem) throws
    func update(_ item: WarrantyItem) throws
    func delete(_ item: WarrantyItem) throws
    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings)
    func saveReceiptImage(_ imageData: Data, for itemID: UUID, fileName: String) throws
    func saveThumbnail(_ imageData: Data, for itemID: UUID, fileName: String) throws
    func receiptImageURL(fileName: String, for itemID: UUID) -> URL?
    func thumbnailURL(fileName: String, for itemID: UUID) -> URL?
    func exportData() throws -> URL
    func importData(from url: URL) throws
    func deleteAllData() throws
}

// MARK: - Errors

enum StorageError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case fileNotFound
    case directoryCreationFailed
    case exportFailed
    case importFailed
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode data."
        case .decodingFailed: return "Failed to decode data."
        case .fileNotFound: return "The requested file was not found."
        case .directoryCreationFailed: return "Failed to create directory."
        case .exportFailed: return "Failed to export data."
        case .importFailed: return "Failed to import data."
        }
    }
}

// MARK: - Implementation

final class StorageService: StorageServiceProtocol, ObservableObject {
    
    // MARK: - Publishers
    
    var itemsPublisher: AnyPublisher<[WarrantyItem], Never> {
        itemsSubject.eraseToAnyPublisher()
    }
    
    var settingsPublisher: AnyPublisher<AppSettings, Never> {
        settingsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    
    private let itemsSubject = CurrentValueSubject<[WarrantyItem], Never>([])
    private let settingsSubject = CurrentValueSubject<AppSettings, Never>(.default)
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.guardslip.storage", qos: .userInitiated)
    
    private lazy var encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = .prettyPrinted
        return enc
    }()
    
    private lazy var decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var itemsDirectory: URL {
        documentsDirectory.appendingPathComponent("items", isDirectory: true)
    }
    
    private var settingsFileURL: URL {
        documentsDirectory.appendingPathComponent("settings.json")
    }
    
    // MARK: - Init
    
    init() {
        ensureDirectoryExists(itemsDirectory)
        loadAllItems()
        settingsSubject.send(loadSettings())
    }
    
    // MARK: - Item Operations
    
    func loadAllItems() {
        queue.sync { [weak self] in
            guard let self else { return }
            var items: [WarrantyItem] = []
            
            guard let contents = try? self.fileManager.contentsOfDirectory(
                at: self.itemsDirectory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                self.itemsSubject.send([])
                return
            }
            
            for itemDir in contents {
                var isDir: ObjCBool = false
                guard self.fileManager.fileExists(atPath: itemDir.path, isDirectory: &isDir),
                      isDir.boolValue else { continue }
                
                let jsonURL = itemDir.appendingPathComponent("item.json")
                guard self.fileManager.fileExists(atPath: jsonURL.path) else { continue }
                do {
                    let data = try Data(contentsOf: jsonURL)
                    let item = try self.decoder.decode(WarrantyItem.self, from: data)
                    items.append(item)
                } catch {
                    continue
                }
            }
            
            self.itemsSubject.send(items.sorted { $0.expiryDate < $1.expiryDate })
        }
    }
    
    func save(_ item: WarrantyItem) throws {
        try queue.sync { [weak self] in
            guard let self else { return }
            let itemDir = self.itemsDirectory.appendingPathComponent(item.id.uuidString, isDirectory: true)
            self.ensureDirectoryExists(itemDir)
            
            let data = try self.encoder.encode(item)
            let jsonURL = itemDir.appendingPathComponent("item.json")
            try data.write(to: jsonURL, options: .atomic)
            
            var current = self.itemsSubject.value
            current.append(item)
            self.itemsSubject.send(current.sorted { $0.expiryDate < $1.expiryDate })
        }
    }
    
    func update(_ item: WarrantyItem) throws {
        try queue.sync { [weak self] in
            guard let self else { return }
            let itemDir = self.itemsDirectory.appendingPathComponent(item.id.uuidString, isDirectory: true)
            guard self.fileManager.fileExists(atPath: itemDir.path) else {
                throw StorageError.fileNotFound
            }
            
            let data = try self.encoder.encode(item)
            let jsonURL = itemDir.appendingPathComponent("item.json")
            try data.write(to: jsonURL, options: .atomic)
            
            var current = self.itemsSubject.value
            if let index = current.firstIndex(where: { $0.id == item.id }) {
                current[index] = item
            }
            self.itemsSubject.send(current.sorted { $0.expiryDate < $1.expiryDate })
        }
    }
    
    func delete(_ item: WarrantyItem) throws {
        try queue.sync { [weak self] in
            guard let self else { return }
            let itemDir = self.itemsDirectory.appendingPathComponent(item.id.uuidString, isDirectory: true)
            if self.fileManager.fileExists(atPath: itemDir.path) {
                try self.fileManager.removeItem(at: itemDir)
            }
            
            var current = self.itemsSubject.value
            current.removeAll { $0.id == item.id }
            self.itemsSubject.send(current)
        }
    }
    
    // MARK: - Settings
    
    func loadSettings() -> AppSettings {
        guard fileManager.fileExists(atPath: settingsFileURL.path),
              let data = try? Data(contentsOf: settingsFileURL),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    func saveSettings(_ settings: AppSettings) {
        queue.async { [weak self] in
            guard let self else { return }
            if let data = try? self.encoder.encode(settings) {
                try? data.write(to: self.settingsFileURL, options: .atomic)
            }
            self.settingsSubject.send(settings)
        }
    }
    
    // MARK: - Receipt Images
    
    func saveReceiptImage(_ imageData: Data, for itemID: UUID, fileName: String) throws {
        try queue.sync { [weak self] in
            guard let self else { return }
            let receiptsDir = self.receiptsDirectory(for: itemID)
            self.ensureDirectoryExists(receiptsDir)
            let fileURL = receiptsDir.appendingPathComponent(fileName)
            try imageData.write(to: fileURL, options: .atomic)
        }
    }
    
    func saveThumbnail(_ imageData: Data, for itemID: UUID, fileName: String) throws {
        try queue.sync { [weak self] in
            guard let self else { return }
            let thumbsDir = self.thumbnailsDirectory(for: itemID)
            self.ensureDirectoryExists(thumbsDir)
            let fileURL = thumbsDir.appendingPathComponent(fileName)
            try imageData.write(to: fileURL, options: .atomic)
        }
    }
    
    func receiptImageURL(fileName: String, for itemID: UUID) -> URL? {
        let url = receiptsDirectory(for: itemID).appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
    
    func thumbnailURL(fileName: String, for itemID: UUID) -> URL? {
        let url = thumbnailsDirectory(for: itemID).appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
    
    // MARK: - Export / Import
    
    func exportData() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("guardslip_export_\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let exportItemsDir = tempDir.appendingPathComponent("items", isDirectory: true)
        if fileManager.fileExists(atPath: itemsDirectory.path) {
            try fileManager.copyItem(at: itemsDirectory, to: exportItemsDir)
        }
        
        if fileManager.fileExists(atPath: settingsFileURL.path) {
            try fileManager.copyItem(at: settingsFileURL, to: tempDir.appendingPathComponent("settings.json"))
        }
        
        let archiveURL = fileManager.temporaryDirectory
            .appendingPathComponent("GuardSlip_Backup.zip")
        if fileManager.fileExists(atPath: archiveURL.path) {
            try fileManager.removeItem(at: archiveURL)
        }
        
        var coordinatorError: NSError?
        var archiveResult: URL?
        
        NSFileCoordinator().coordinate(
            readingItemAt: tempDir,
            options: [.forUploading],
            error: &coordinatorError
        ) { zipURL in
            do {
                try self.fileManager.copyItem(at: zipURL, to: archiveURL)
                archiveResult = archiveURL
            } catch {
                archiveResult = nil
            }
        }
        
        try? fileManager.removeItem(at: tempDir)
        
        if let error = coordinatorError { throw error }
        guard let finalURL = archiveResult else { throw StorageError.exportFailed }
        return finalURL
    }
    
    func importData(from url: URL) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("guardslip_import_\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        try extractZip(at: url, to: tempDir)
        
        let importedItemsDir = tempDir.appendingPathComponent("items", isDirectory: true)
        if fileManager.fileExists(atPath: importedItemsDir.path) {
            if fileManager.fileExists(atPath: itemsDirectory.path) {
                try fileManager.removeItem(at: itemsDirectory)
            }
            try fileManager.copyItem(at: importedItemsDir, to: itemsDirectory)
        }
        
        let importedSettings = tempDir.appendingPathComponent("settings.json")
        if fileManager.fileExists(atPath: importedSettings.path) {
            if fileManager.fileExists(atPath: settingsFileURL.path) {
                try fileManager.removeItem(at: settingsFileURL)
            }
            try fileManager.copyItem(at: importedSettings, to: settingsFileURL)
        }
        
        loadAllItems()
        settingsSubject.send(loadSettings())
    }
    
    func deleteAllData() throws {
        try queue.sync { [weak self] in
            guard let self else { return }
            if self.fileManager.fileExists(atPath: self.itemsDirectory.path) {
                try self.fileManager.removeItem(at: self.itemsDirectory)
                self.ensureDirectoryExists(self.itemsDirectory)
            }
            if self.fileManager.fileExists(atPath: self.settingsFileURL.path) {
                try self.fileManager.removeItem(at: self.settingsFileURL)
            }
            self.itemsSubject.send([])
            self.settingsSubject.send(.default)
        }
    }
    
    // MARK: - Private Helpers
    
    private func receiptsDirectory(for itemID: UUID) -> URL {
        itemsDirectory
            .appendingPathComponent(itemID.uuidString, isDirectory: true)
            .appendingPathComponent("receipts", isDirectory: true)
    }
    
    private func thumbnailsDirectory(for itemID: UUID) -> URL {
        itemsDirectory
            .appendingPathComponent(itemID.uuidString, isDirectory: true)
            .appendingPathComponent("thumbnails", isDirectory: true)
    }
    
    private func ensureDirectoryExists(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// Extracts a zip archive using NSFileCoordinator by coordinating a
    /// write into the destination and letting the system decompress the source.
    private func extractZip(at sourceURL: URL, to destinationURL: URL) throws {
        let sourceData = try Data(contentsOf: sourceURL)
        
        let tempZip = fileManager.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).zip")
        try sourceData.write(to: tempZip)
        defer { try? fileManager.removeItem(at: tempZip) }
        
        guard let archive = try? ZipReader(fileURL: tempZip) else {
            throw StorageError.importFailed
        }
        try archive.extractAll(to: destinationURL)
    }
}

// MARK: - Minimal Zip Reader (PKZip / iOS-compatible)

/// A lightweight, dependency-free zip reader supporting stored & deflated entries.
/// Uses the zlib decompression built into iOS/macOS via the Compression framework.
private struct ZipReader {
    
    private let data: Data
    
    init?(fileURL: URL) throws {
        guard let data = try? Data(contentsOf: fileURL), data.count > 22 else { return nil }
        self.data = data
    }
    
    func extractAll(to baseURL: URL) throws {
        let fm = FileManager.default
        var offset = 0
        
        while offset + 30 <= data.count {
            let header = data[offset...]
            
            guard header.readUInt32(at: 0) == 0x04034b50 else { break }
            
            let compressionMethod = header.readUInt16(at: 8)
            let compressedSize = Int(header.readUInt32(at: 18))
            let uncompressedSize = Int(header.readUInt32(at: 22))
            let fileNameLength = Int(header.readUInt16(at: 26))
            let extraFieldLength = Int(header.readUInt16(at: 28))
            
            let nameStart = offset + 30
            let nameEnd = nameStart + fileNameLength
            guard nameEnd <= data.count else { throw StorageError.importFailed }
            
            let nameData = data[nameStart..<nameEnd]
            guard let entryName = String(data: nameData, encoding: .utf8) else {
                throw StorageError.importFailed
            }
            
            let dataStart = nameEnd + extraFieldLength
            let dataEnd = dataStart + compressedSize
            guard dataEnd <= data.count else { throw StorageError.importFailed }
            
            let entryURL = baseURL.appendingPathComponent(entryName)
            
            if entryName.hasSuffix("/") {
                try fm.createDirectory(at: entryURL, withIntermediateDirectories: true)
            } else {
                let parentDir = entryURL.deletingLastPathComponent()
                if !fm.fileExists(atPath: parentDir.path) {
                    try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
                }
                
                let compressedData = data[dataStart..<dataEnd]
                
                if compressionMethod == 0 {
                    try compressedData.write(to: entryURL)
                } else if compressionMethod == 8 {
                    let decompressed = try decompressDeflate(
                        compressedData,
                        expectedSize: uncompressedSize
                    )
                    try decompressed.write(to: entryURL)
                } else {
                    throw StorageError.importFailed
                }
            }
            
            offset = dataEnd
        }
    }
    
    private func decompressDeflate(_ input: Data, expectedSize: Int) throws -> Data {
        let bufferSize = max(expectedSize, 1024)
        var decompressed = Data(count: bufferSize)
        
        let result = input.withUnsafeBytes { srcPtr -> Data? in
            guard let srcBase = srcPtr.baseAddress else { return nil }
            return decompressed.withUnsafeMutableBytes { dstPtr -> Data? in
                guard let dstBase = dstPtr.baseAddress else { return nil }
                let written = compression_decode_buffer(
                    dstBase.assumingMemoryBound(to: UInt8.self),
                    bufferSize,
                    srcBase.assumingMemoryBound(to: UInt8.self),
                    input.count,
                    nil,
                    COMPRESSION_ZLIB
                )
                guard written > 0 else { return nil }
                return Data(bytes: dstBase, count: written)
            }
        }
        
        guard let output = result else { throw StorageError.importFailed }
        return output
    }
}

// MARK: - Data Helpers for Binary Reading

private extension Data {
    func readUInt16(at offset: Int) -> UInt16 {
        let slice = self[self.startIndex + offset ..< self.startIndex + offset + 2]
        return slice.withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
    }
    
    func readUInt32(at offset: Int) -> UInt32 {
        let slice = self[self.startIndex + offset ..< self.startIndex + offset + 4]
        return slice.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
    }
}
