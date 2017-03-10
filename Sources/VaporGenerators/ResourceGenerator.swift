import Console

internal final class ResourceGenerator: AbstractGenerator {

    private enum Directories: String {
        case styles = "Public/styles/"
        case scripts = "Public/scripts/"
    }
    
    override func performGeneration(arguments: [String]) throws {
        let modelGenerator = ModelGenerator(console: console)
        try modelGenerator.generate(arguments: arguments)
        
        let controllerGenerator = ControllerGenerator(console: console)
        try controllerGenerator.generate(arguments: arguments + ["--resource"])
        
        let viewsGenerator = ViewGenerator(console: console)
        try viewsGenerator.generate(arguments: arguments + ["--useFirstArgumentAsDirectory"])
        
        let routesGenerator = RouteGenerator(console: console)
        try routesGenerator.generate(arguments: arguments + ["--resource"])
        
        guard let name = arguments.first else {
            throw ConsoleError.insufficientArguments
        }
        try generateViewResourcesForResource(named: name)
    }
    
    private func generateViewResourcesForResource(named name: String) throws {
        let resourcesToGenerate: [String] = [
            "\(Directories.styles.rawValue)\(name.pluralized).css",
            "\(Directories.scripts.rawValue)\(name.pluralized).js"
        ]
        for path in resourcesToGenerate {
            console.info("Generating \(path)")
            try File(path: path, contents: "").save()
        }
    }
    
}
