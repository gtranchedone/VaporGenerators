import Console

internal final class RouteGenerator: AbstractGenerator {
    
    private enum Arguments: String {
        case path
        case method
        case resource
    }
    
    private enum ReplacementKeys: String {
        case route = "_ROUTE_"
        case method = "_METHOD_"
        case handler = "_HANDLER_"
        case resource = "_RESOURCE_"
    }
    
    private enum ReplacementText: String {
        case routesOriginal = "func configureRoutes(with droplet: Droplet) throws {"
        case routesConfigOriginal = "drop.run()"
        case routesConfigReplacement = "configure(droplet: drop)"
    }
    
    private enum Templates: String {
        case routesFile = "Routes"
        case simpleRoute = "Route_Simple"
        case resourceRoute = "Route_Resource"
        case resourceHelpers = "Route_ResourceHelpers"
        
        func file(generator: Generator) -> File {
            return try! File(path: generator.pathForTemplate(named: rawValue))
        }
    }
    
    private static let routesFileSearchPaths = [
        "Sources/App/Configuration/Routes.swift",
        "Sources/App/Routes.swift"
    ]
    
    private static let applicationMainSearchPaths = [
        "Sources/App/main.swift",
        "Sources/Executable/main.swift"
    ]
    
    private static var routesFile: File? {
        return File.searchFile(in: routesFileSearchPaths)
    }
    
    private static var mainFile: File? {
        return File.searchFile(in: applicationMainSearchPaths)
    }
    
    override internal var signature: [Argument] {
        return super.signature + [
            Value(name: Arguments.method.rawValue,
                  help: ["The route's HTTP method"]),
            Option(name: Arguments.resource.rawValue,
                   help: ["Builds routes for a resource instead of the path as specified. If true, method is ignored."]),
        ]
    }
    
    override func performGeneration(arguments: [String]) throws {
        guard arguments.count >= 1 else {
            throw ConsoleError.insufficientArguments
        }
        
        let path = arguments[0]
        if arguments.flag(Arguments.resource.rawValue) {
            try generateRoutes(forResource: path)
        }
        else {
            let method =  arguments.count > 1 ? arguments[1] : "get"
            let handler = arguments.count > 2 ? arguments[2] : "return JSON([:])"
            try generateRoute(forPath: path, method: method, handler: handler)
        }
    }
    
    private func generateRoute(forPath path: String, method: String, handler: String) throws {
        console.info("Generating route '\(path)'")
        let template = Templates.simpleRoute.file(generator: self)
        let routeText = routeString(fromTemplate: template, path: path, handler: handler, method: method)
        try addRoute(routeText)
    }
    
    private func generateRoutes(forResource resourceName: String) throws {
        console.info("Generating route for resource '\(resourceName)'")
        let template = Templates.resourceRoute.file(generator: self)
        let routeName = resourceName.pluralized
        let handler = "\(routeName.capitalized)Controller(droplet: droplet)"
        let routeText = routeString(fromTemplate: template, path: routeName, handler: handler)
        try addRoute(routeText)
        try generateHelpers(forResource: resourceName)
    }
    
    private func generateHelpers(forResource resourceName: String) throws {
        let helpersFile = Templates.resourceHelpers.file(generator: self)
        var helpersContent = helpersFile.contents
        helpersContent = helpersContent.replacingOccurrences(of: ReplacementKeys.resource.rawValue, with: resourceName.capitalized)
        helpersContent = helpersContent.replacingOccurrences(of: ReplacementKeys.route.rawValue, with: resourceName.pluralized)
        var routesFile = try searchRoutesFile()
        routesFile.contents += "\n\(helpersContent)"
        try routesFile.save()
    }
    
    private func addRoute(_ text: String) throws {
        let originalText = ReplacementText.routesOriginal.rawValue
        let replacementString = originalText + "\n\(text)"
        let file = try searchRoutesFile()
        console.info("Adding route to file '\(file.path)'")
        if !file.contents.contains(originalText) {
            throw GeneratorError.general("Routing function not found in routes file")
        }
        let newFile = File(path: file.path, contents: file.contents.replacingOccurrences(of: originalText, with: replacementString))
        try newFile.save()
    }
    
    private func configureDropletUsingRoutesFile() throws {
        let originalText = ReplacementText.routesConfigOriginal.rawValue
        let replacementString = "try \(module(fromPath: RouteGenerator.routesFile!.path)).\(ReplacementText.routesConfigReplacement.rawValue)\n\(originalText)"
        guard let file = RouteGenerator.mainFile else {
            throw GeneratorError.general("Cannot find main.swift")
        }
        let newFile = File(path: file.path, contents: file.contents.replacingOccurrences(of: originalText, with: replacementString))
        try newFile.save()
    }
    
    private func routeString(fromTemplate template: File, path: String, handler: String, method: String = "") -> String {
        var contents = template.contents
        contents = contents.replacingOccurrences(of: ReplacementKeys.route.rawValue, with: path)
        contents = contents.replacingOccurrences(of: ReplacementKeys.method.rawValue, with: method)
        contents = contents.replacingOccurrences(of: ReplacementKeys.handler.rawValue, with: handler)
        return contents
    }
    
    private func module(fromPath path: String) -> String {
        // assuming path is in the form "[Sources|Packages]/[MODULE]/../../file.extension"
        return path.components(separatedBy: "/")[1]
    }
    
    private func searchRoutesFile() throws -> File {
        if let file = RouteGenerator.routesFile {
            return file
        }
        let filePath = RouteGenerator.routesFileSearchPaths.first!
        console.warning("Routes file not found. Creating it at '\(filePath)'")
        try copyTemplate(atPath: pathForTemplate(named: Templates.routesFile.rawValue), toPath: filePath)
        try configureDropletUsingRoutesFile()
        return try File(path: filePath)
    }
    
}
