import Foundation
import Console

internal final class ModelGenerator: AbstractGenerator {
    
    private enum ReplacementKeys: String {
        case className = "_CLASS_NAME_"
        case variableName = "_IVAR_NAME_"
        case dbTableName = "_DB_TABLE_NAME_"
        case ivarsDefinition = "_IVARS_DEFINITION_"
        case ivarsInitializer = "_IVARS_INITIALIZER_"
        case ivarsNodeConversion = "_IVARS_DICTIONARY_PAIRS_"
        case dbTableRowsDefinition = "_TABLE_ROWS_DEFINITION_"
    }
    
    private enum Directories: String {
        case models = "Sources/App/Models/"
        case modelTests = "Tests/AppTests/Models/"
    }
    
    private enum Templates: String {
        case model = "Model"
        case tests = "ModelTests"
    }
    
    override internal var signature: [Argument] {
        return super.signature + [
            Value(name: "properties", help: ["An optional list of properties in the format variable:type (e.g. firstName:string lastname:string)"]),
        ]
    }
    
    override func performGeneration(arguments: [String]) throws {
        guard let name = arguments.first else {
            throw ConsoleError.argumentNotFound
        }
        let ivars = arguments.values.filter { return $0.contains(":") }
        console.print("Model '\(name)' with ivars \(ivars)")
        try generateModelClass(named: name, ivars: ivars)
        try generateModelTests(className: name)
    }
    
    func generateModelClass(named name: String, ivars: [String]) throws {
        let filePath = "\(Directories.models.rawValue)\(name.capitalized).swift"
        try copyTemplate(atPath: pathForTemplate(named: Templates.model.rawValue), toPath: filePath) { (contents) in
            func spacing(_ x: Int) -> String {
                guard x > 0 else { return "" }
                var result = ""
                for _ in 0 ..< x {
                    result += " "
                }
                return result
            }
            
            var newContents = contents
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.className.rawValue,
                                                           with: name.capitalized)
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.variableName.rawValue,
                                                           with: name.lowercased())
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.dbTableName.rawValue,
                                                           with: name.pluralized)
            
            var ivarDefinitions = ""
            var ivarInitializers = ""
            var ivarDictionaryPairs = ""
            var tableRowsDefinition = ""
            for ivar in ivars {
                let components = ivar.components(separatedBy: ":")
                let ivarName = components.first!
                let ivarType = components.last!
                ivarDefinitions += "\(spacing(4))var \(ivarName): \(ivarType.capitalized)\n"
                ivarInitializers += "\(spacing(8))\(ivarName) = try node.extract(\"\(ivarName)\")\n"
                ivarDictionaryPairs += "\(spacing(12))\"\(ivarName)\": \(ivarName),\n"
                tableRowsDefinition += "\(spacing(12))$0.\(ivarType.lowercased())(\"\(ivarName)\")\n"
            }
            ivarDefinitions = ivarDefinitions.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            ivarInitializers = ivarInitializers.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            ivarDictionaryPairs = ivarDictionaryPairs.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            tableRowsDefinition = tableRowsDefinition.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.ivarsDefinition.rawValue,
                                                           with: ivarDefinitions)
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.ivarsInitializer.rawValue,
                                                           with: ivarInitializers)
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.ivarsNodeConversion.rawValue,
                                                           with: ivarDictionaryPairs)
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.dbTableRowsDefinition.rawValue,
                                                           with: tableRowsDefinition)
            
            return newContents
        }
    }
    
    func generateModelTests(className: String) throws {
        let templatePath = pathForTemplate(named: Templates.tests.rawValue)
        let destination = "\(Directories.modelTests.rawValue)\(className.capitalized)Tests.swift"
        try copyTemplate(atPath: templatePath, toPath: destination) {
            return $0.replacingOccurrences(of: ReplacementKeys.className.rawValue,
                                           with: className.capitalized)
        }
    }
    
}
