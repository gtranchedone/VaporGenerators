import Console

internal final class ControllerGenerator: AbstractGenerator {
    
    private enum Templates: String {
        case tests = "Controller_Tests"
        case basic = "Controller_Simple"
        case resource = "Controller_Resource"
    }
    
    private enum Directories: String {
        case styles = "Public/styles/"
        case scripts = "Public/scripts/"
        case controllers = "Sources/App/Controllers/"
        case controllersTests = "Tests/AppTests/Controllers/"
    }
    
    private enum ReplacementKeys: String {
        case className = "_CLASS_NAME_"
        case resourceName = "_RESOURCE_NAME_"
        case variableName = "_VAR_NAME_"
        case variableNamePluralized = "_VAR_NAME_PLURALIZED_"
    }
    
    private enum Arguments: String {
        case actions
        case resource
        case noCSS = "no-css"
        case noJS = "no-js"
    }
    
    override internal var signature: [Argument] {
        return [
            Value(name: Arguments.actions.rawValue,
                  help: ["An optional list of actions. Routes and Views will be created for each action."]),
            Option(name: Arguments.resource.rawValue,
                   help: ["Builds controller for a resource"]),
            Option(name: Arguments.noCSS.rawValue,
                   help: ["If true it doen't create a CSS file for the controller, defaults to true if 'actions' is empty."]),
            Option(name: Arguments.noJS.rawValue,
                   help: ["If true it doen't create a JavsScript file for the controller, defaults to true if 'actions' is empty."]),
        ]
    }
    
    override internal func performGeneration(arguments: [String]) throws {
        guard let name = arguments.first?.lowercased() else {
            throw ConsoleError.argumentNotFound
        }
        
        let argumentsWithoutName = Array(arguments.values[1 ..< arguments.values.count])
        let controllerName = ControllerGenerator.controllerNameFromCommandInput(name)
        let actions = argumentsWithoutName.filter { !$0.contains(":") }
        console.print("Controller '\(controllerName)' actions => \(actions)")
        
        if arguments.flag(Arguments.resource.rawValue) {
            try generateResourcesController(forResourceNamed: name, actions: actions)
            try generateModel(arguments: arguments)
        }
        else {
            try generateSimpleController(named: name, actions: actions)
        }
        
        try generateViews(forActions: actions, resourceName: name)
        if actions.count > 0 {
            try generateResources(arguments: arguments, resourceName: name)
        }
    }
    
    private func generateModel(arguments: [String]) throws {
        let modelGenerator = ModelGenerator(console: console)
        try modelGenerator.generate(arguments: arguments)
    }
    
    private func generateResourcesController(forResourceNamed resourceName: String, actions: [String]) throws {
        var file = try generateController(named: resourceName, templateName: Templates.resource.rawValue)
        file = try uncommentMethods(forActions: actions, inFile: file)
        try file.save()
        try generateRoutes(forResource: resourceName)
    }
    
    private func generateSimpleController(named name: String, actions: [String]) throws {
        try generateController(named: name, templateName: Templates.basic.rawValue)
        try generateRoutes(forActions: actions, resourceName: name)
    }
    
    @discardableResult
    private func generateController(named resourceName: String, templateName: String) throws -> File {
        let className = ControllerGenerator.controllerNameFromCommandInput(resourceName)
        let filePath = "\(Directories.controllers.rawValue)\(className).swift"
        let templatePath = pathForTemplate(named: templateName)
        let testsTemplatePath = pathForTemplate(named: Templates.tests.rawValue)
        let testsFilePath = "\(Directories.controllersTests.rawValue)\(className)Tests.swift"
        try generateClass(named: "\(className)Tests", forResource: resourceName, template: testsTemplatePath, destination: testsFilePath)
        return try generateClass(named: className, forResource: resourceName, template: templatePath, destination: filePath)
    }
    
    @discardableResult
    private func generateClass(named className: String, forResource resourceName: String, template: String, destination: String) throws -> File {
        try copyTemplate(atPath: template, toPath: destination) { (contents) in
            var newContents = contents
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.className.rawValue,
                                                           with: className)
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.resourceName.rawValue,
                                                           with: resourceName.capitalized)
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.variableNamePluralized.rawValue,
                                                           with: resourceName.pluralized.lowercased())
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.variableName.rawValue,
                                                           with: resourceName.lowercased())
            return newContents
        }
        let file = try File(path: destination)
        try file.save()
        return file
    }
    
    private func generateViews(forActions actions: [String], resourceName: String) throws {
        let viewGenerator = ViewGenerator(console: console)
        try viewGenerator.generate(arguments: [resourceName] + actions + ["--resource"])
    }
    
    private func generateResources(arguments: [String], resourceName: String) throws {
        var resourcesToGenerate: [String] = []
        if !arguments.flag(Arguments.noCSS.rawValue) {
            resourcesToGenerate.append("\(Directories.styles.rawValue)\(resourceName.pluralized).css")
        }
        if !arguments.flag(Arguments.noJS.rawValue) {
            resourcesToGenerate.append("\(Directories.scripts.rawValue)\(resourceName.pluralized).js")
        }
        for path in resourcesToGenerate {
            console.info("Generating \(path)")
            try File(path: path, contents: "").save()
        }
    }
    
    private func uncommentMethods(forActions actions: [String], inFile file: File) throws -> File {
        var string = file.contents
        var rangesToRemove: [Range<String.CharacterView.Index>] = []
        
        var openingRange: Range<String.CharacterView.Index>?
        var shouldCloseRange = false
        let searchRange = string.startIndex ..< string.endIndex
        
        var invalidTemplate = false
        var currentAction: String?
        var error: String?
        var line = 0
        
        string.enumerateSubstrings(in: searchRange, options: .byLines) { (substring, _, range, stop) in
            line += 1
            guard let substring = substring else { stop = true; return }
            if substring.contains("/*") {
                openingRange = range
                currentAction = nil
                // if we find two '/*' in a row without a closing comment stop: the template is invalid
                if shouldCloseRange {
                    error = "Found two /* in a row while examining line \(line)"
                    invalidTemplate = true
                    stop = true
                    return
                }
            }
            else if substring.contains("func") {
                for action in actions {
                    if substring.contains(action) {
                        shouldCloseRange = true
                        currentAction = action
                        break
                    }
                }
                if !shouldCloseRange {
                    // commented code doesn't contain any action we're looking for
                    // we can then reset the current partial search result and move to the next line in the template
                    openingRange = nil
                    return
                }
            }
            else if substring.contains("*/") && shouldCloseRange {
                guard let blockOpeningRange = openingRange else {
                    error = "Cannot uncomment range for action '\(currentAction ?? "something is wrong")'"
                    invalidTemplate = true
                    stop = true
                    return
                }
                rangesToRemove.append(blockOpeningRange)
                rangesToRemove.append(range)
                shouldCloseRange = false
                currentAction = nil
                openingRange = nil
            }
            else if substring.contains(": nil, //") || substring.contains(": nil //") {
                // update the 'makeResource' method's implementation
                actions.forEach({ action in
                    if let range = string.range(of: "\(action): nil, // \(action)") {
                        string.replaceSubrange(range, with: "\(action): \(action)")
                    }
                    else if let range = string.range(of: "\(action): nil // \(action)") {
                        string.replaceSubrange(range, with: "\(action): \(action)")
                    }
                })
            }
        }
        
        if invalidTemplate {
            throw GeneratorError.general(error!)
        }
        
        // as indexes are invalidated on subrange removal,
        // by reversing the array of ranges we keep the indexes we're working on valid
        for range in rangesToRemove.reversed() {
            string.removeSubrange(range)
        }
        
        return File(path: file.path, contents: string)
    }
    
    private func generateRoutes(forActions actions: [String], resourceName: String) throws {
        let routeGenerator = RouteGenerator(console: console)
        let controllerName = ControllerGenerator.controllerNameFromCommandInput(resourceName)
        for action in actions {
            let path = "\(resourceName.pluralized.lowercased())/\(action)"
            let handler = "\"try \(controllerName)().render(\"\(action)\")\""
            try routeGenerator.generate(arguments: [path, "get", handler])
        }
    }
    
    private func generateRoutes(forResource resourceName: String) throws {
        try RouteGenerator(console: console).generate(arguments: [resourceName, "--resource"])
    }
    
    private class func controllerNameFromCommandInput(_ name: String) -> String {
        let controllerSuffix = "Controller"
        let controllerName = name.capitalized
        guard !controllerName.localizedCaseInsensitiveContains(controllerSuffix) else { return controllerName }
        return controllerName.pluralized + controllerSuffix
    }
    
}
