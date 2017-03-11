import Console

internal class TestsGenerator: AbstractGenerator {
    
    private enum Arguments: String {
        case fileName // e.g. "MyController" or "MyControllerTests"
        case directory // e.g. "Tests/AppTests/Controllers/"
    }
    
    private enum Files: String {
        case testsDirectory = "Tests/AppTests/"
        case linuxMain = "Tests/LinuxMain.swift"
    }
    
    private enum Templates: String {
        case linuxMain = "LinuxMain"
        case simple = "Tests"
    }
    
    private enum ReplacementKeys: String {
        case className = "_CLASS_NAME_"
        case linuxMain = "XCTMain(["
    }
    
    override func performGeneration(arguments: [String]) throws {
        guard let name = arguments.first else {
            throw ConsoleError.argumentNotFound
        }
        var directory = Files.testsDirectory.rawValue
        if arguments.values.count > 1 {
            directory = arguments.values[1]
        }
        let templatePath = pathForTemplate(named: Templates.simple.rawValue)
        let className = testsFileName(from: name).capitalizingFirstLetter()
        let filePath = directory + className + ".swift"
        try copyTemplate(atPath: templatePath, toPath: filePath) {
            $0.replacingOccurrences(of: ReplacementKeys.className.rawValue,
                                    with: className)
        }
        try? copyTemplate(atPath: pathForTemplate(named: Templates.linuxMain.rawValue),
                          toPath: Files.linuxMain.rawValue)
        try File.open(atPath: Files.linuxMain.rawValue) { file in
            let original = ReplacementKeys.linuxMain.rawValue
            let replacement = original + "\n    testCase(\(className).allTests),"
            file.contents = file.contents.replacingOccurrences(of: original, with: replacement)
        }
    }
    
    private func testsFileName(from input: String) -> String {
        guard !input.contains("Test") else { return input }
        return input + "Tests"
    }
    
}

extension String {
    public func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let other = String(characters.dropFirst())
        return first + other
    }

    public mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
