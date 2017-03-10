import Foundation

public struct File {
    public let path: String
    public var contents: String
    
    public init(path: String) throws {
        let contents = try String(contentsOfFile: path, encoding: .utf8)
        self.init(path: path, contents: contents)
    }
    
    public init(path: String, contents: String) {
        self.path = path
        self.contents = contents
    }
    
    public func save() throws {
        try saveCopy(atPath: path)
    }
    
    public func saveCopy(atPath path: String) throws {
        let directory = path.directory
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directory) {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        try contents.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    public static func searchFile(in searchPaths: [String]) -> File? {
        for path in searchPaths {
            if let file = try? File(path: path) {
                return file
            }
        }
        return nil
    }
}

extension File {
    public static func createDirectory(atPath path: String) throws {
        return try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
    
    public static func exists(atPath path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    public static func open(atPath path: String, _ editClosure: ((inout File) -> Void)) throws {
        var file = try File(path: path)
        editClosure(&file)
        try file.save()
    }
}

extension String {
    internal var directory: String {
        var pathComponents = components(separatedBy: "/")
        pathComponents.removeLast()
        return pathComponents.joined(separator: "/")
    }
}
