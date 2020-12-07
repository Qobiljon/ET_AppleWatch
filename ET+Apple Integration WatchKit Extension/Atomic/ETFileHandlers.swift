import Foundation


private let DELIMITER = "\t"
private let NEWLINE = "\n"
private let BATCH_SIZE = 200
private let ACQUISITION_FILENAME = "data.csv"

class ETwatchOSAcquisitionFile {
    private let documentsUrl: URL
    private let fileUrl: URL
    private var queue = DispatchQueue(label: "acquisition-file-queue")
    
    
    // singleton
    private static var instance: ETwatchOSAcquisitionFile?
    static func getInstance() -> ETwatchOSAcquisitionFile? {
        if instance == nil {
            do {
                instance = try ETwatchOSAcquisitionFile(fileName: ACQUISITION_FILENAME)
            } catch {
                print("acquisition file error \(error)")
            }
        }
        return instance
    }
    private init(fileName: String) throws {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            throw NSError(domain: "cannot resolve documents directory", code: 1, userInfo: nil)
        }
        self.documentsUrl = documentsUrl
        self.fileUrl = documentsUrl.appendingPathComponent(fileName, isDirectory: false)
        
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            if !FileManager.default.createFile(atPath: fileUrl.path, contents: "".data(using: .utf8), attributes: nil) {
                throw NSError(domain: "error creating an acquisition file", code: 1, userInfo: nil)
            }
        }
    }
    
    
    func storeDataSample(dataSourceId: Int32, timestamp: Int64, value: String) throws {
        try queue.sync {
            if let fileHandle = FileHandle(forWritingAtPath: fileUrl.path) {
                fileHandle.seekToEndOfFile()
                let columns = [String(dataSourceId), String(timestamp), value]
                let line = columns.joined(separator: DELIMITER) + NEWLINE
                fileHandle.write(line.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                throw NSError(domain: "error opening a file for atomic writing", code: 3, userInfo: nil)
            }
        }
    }
    func moveContentToBatchFiles() throws {
        try queue.sync {
            let lines = try String(contentsOf: fileUrl, encoding: .utf8).split(separator: String.Element(NEWLINE))
            let batches = ETwatchOSTools.splitToBatches(array: lines, batchSize: BATCH_SIZE)
            if batches.count == 1 {
                throw NSError(domain: "too small content", code: 1, userInfo: nil)
            }
            
            var counter = Int64(Date().timeIntervalSince1970*1000) - Int64(batches.count)
            do {
                for batch in batches {
                    let content = batch.joined(separator: NEWLINE)
                    let batchFileUrl = documentsUrl.appendingPathComponent("\(counter).csv", isDirectory: false)
                    try content.write(to: batchFileUrl, atomically: false, encoding: .utf8)
                    counter += 1
                }
                try "".write(to: fileUrl, atomically: false, encoding: .utf8)
                print("acquisition file content splitted into batch submission files")
            } catch {
                print("batch submission file write error \(error)")
            }
        }
    }
}

class ETwatchOSSubmissionFile {
    private static var instances: [String:ETwatchOSSubmissionFile] = [:]
    private let documentsUrl: URL
    private let fileName: String
    private let fileUrl: URL
    private var queue = DispatchQueue(label: "submission-file-queue")
    
    
    static func listSubmissionFileNames() throws -> [String] {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            throw NSError(domain: "atomic file handler cannot resolve documents directory", code: 1, userInfo: nil)
        }
        var res: [String] = []
        
        for fileUrl in try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil) {
            if fileUrl.isFileURL {
                let fileName = fileUrl.lastPathComponent
                let isSubmissionBatchFile = fileName.range(of: "^\\d+.csv$", options: .regularExpression) != nil
                if isSubmissionBatchFile {
                    res += [fileName]
                }
            }
        }
        
        return res
    }
    static func getInstance(fileName: String) -> ETwatchOSSubmissionFile? {
        if let instance = instances[fileName] {
            return instance
        } else {
            do {
                let newInstance = try ETwatchOSSubmissionFile(fileName: fileName)
                instances[fileName] = newInstance
                return newInstance
            } catch {
                print("submission file error \(error)")
                return nil
            }
        }
    }
    private init(fileName: String) throws {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            throw NSError(domain: "atomic file handler cannot resolve documents directory", code: 1, userInfo: nil)
        }
        self.fileName = fileName
        self.documentsUrl = documentsUrl
        self.fileUrl = documentsUrl.appendingPathComponent(fileName, isDirectory: false)
        // self.submitState = false
        
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            throw NSError(domain: "submission file doesn't exist", code: 1, userInfo: nil)
        }
    }
    
    
    func readBatchContentForGrpc() throws -> ([Int32], [Int64], [Data]) {
        var dataSourceIds: [Int32] = []
        var timestamps: [Int64] = []
        var values: [Data] = []
        
        let lines = try String(contentsOf: fileUrl, encoding: .utf8).split(separator: String.Element(NEWLINE))
        for line in lines {
            let cells = line.split(separator: String.Element(DELIMITER))
            if cells.count == 3 {
                let dataSourceId = Int32(cells[0]) ?? Int32(-1)
                let timestamp = Int64(cells[1]) ?? Int64(-1)
                let value = cells[2].data(using: .utf8)!
                
                dataSourceIds += [dataSourceId]
                timestamps += [timestamp]
                values += [value]
            } else {
                print("data inconsistency : \(line)")
            }
        }
        
        return (dataSourceIds, timestamps, values)
    }
    func readBatchContentForWc() throws -> String {
        return try String(contentsOf: fileUrl, encoding: .utf8)
    }
    func removeFile() throws {
        try FileManager.default.removeItem(at: fileUrl)
        ETwatchOSSubmissionFile.instances.removeValue(forKey: fileName)
    }
}
