import Console
import Foundation

public extension Generator {
    
    // Supporting method required due to lack of support for Resources in SwiftPM
    private func pathOfDirectory(matchingName name: String, inPath containerPath: String) -> String? {
        let enumerator = FileManager.default.enumerator(atPath: containerPath)
        while let directory = enumerator?.nextObject() as? String {
            if directory.contains(name) {
                return directory
            }
        }
        return nil
    }
    
    // Supporting method required due to lack of support for Resources in SwiftPM
    private var packageDirectory: String {
        let packageName = String(describing: self).components(separatedBy: ".").first!
        if let packagePath =  pathOfDirectory(matchingName: packageName, inPath: "Packages") {
            return "Packages/\(packagePath)/Sources/\(packageName)/"
        }
        return "Sources/\(packageName)/"
    }
    
    internal func pathForTemplate(named templateName: String, extension fileExtension: String = "swifttemplate") -> String {
        return packageDirectory + "Templates/\(templateName).\(fileExtension)"
    }
    
    public func checkThatFileExists(atPath path: String) throws {
        guard File.exists(atPath: path) else {
            throw GeneratorError.general("\(path) not found.")
        }
    }
    
    public func checkThatFileDoesNotExist(atPath path: String) throws {
        guard !File.exists(atPath: path) else {
            throw GeneratorError.general("\(path) already exists")
        }
    }
    
    public func loadTemplate(atPath: String, fallbackURL: URL) throws -> File {
        if !File.exists(atPath: atPath) {
            try cloneTemplate(atURL: fallbackURL, toPath: atPath.directory)
        }
        return try File(path: atPath)
    }
    
    public func copyTemplate(atPath: String, fallbackURL: URL, toPath: String, _ editsBlock: ((String) -> String)? = nil) throws {
        var templateFile = try loadTemplate(atPath: atPath, fallbackURL: fallbackURL)
        if let editedContents = editsBlock?(templateFile.contents) {
            templateFile.contents = editedContents
        }
        try checkThatFileDoesNotExist(atPath: toPath)
        console.info("Generating \(toPath)")
        try templateFile.saveCopy(atPath: toPath)
    }
    
    public func copyTemplate(atPath templatePath: String, toPath: String, _ editsBlock: ((String) -> String)? = nil) throws {
        try checkThatFileDoesNotExist(atPath: toPath)
        console.info("Generating \(toPath)")
        var templateFile = try File(path: templatePath)
        if let editedContents = editsBlock?(templateFile.contents) {
            templateFile.contents = editedContents
        }
        try templateFile.saveCopy(atPath: toPath)
    }
    
    private func cloneTemplate(atURL templateURL: URL, toPath: String) throws {
        let cloneBar = console.loadingBar(title: "Cloning Template")
        cloneBar.start()
        do {
            _ = try console.backgroundExecute(program: "git", arguments: ["clone", "\(templateURL)", "\(toPath)"])
            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", "\(toPath)/.git"])
            cloneBar.finish()
        } catch ConsoleError.backgroundExecute(_, let error, _) {
            cloneBar.fail()
            throw GeneratorError.general(error.string.trim())
        }
    }
    
}
