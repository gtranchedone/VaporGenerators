import Console

internal final class ViewGenerator: AbstractGenerator {
    
    private enum Arguments: String {
        case useFirstArgumentAsDirectory
    }
    
    private enum Directories: String {
        case views = "Resources/Views/"
    }
    
    private enum Templates: String {
        case view = "View"
    }
    
    override func performGeneration(arguments: [String]) throws {
        var viewsToGenerate = arguments.values.filter { !$0.contains(":") }
        guard viewsToGenerate.count > 0 else {
            throw ConsoleError.argumentNotFound
        }
        
        var directory = Directories.views.rawValue
        if arguments.flag(Arguments.useFirstArgumentAsDirectory.rawValue) {
            directory += viewsToGenerate.removeFirst().lowercased().pluralized + "/"
            console.info("Generating \(directory)")
            try File.createDirectory(atPath: directory)
            if viewsToGenerate.isEmpty {
                let gitKeep = File(path: directory + ".gitkeep", contents: "")
                try gitKeep.save()
            }
        }
        
        for view in viewsToGenerate {
            try generateView(atPath: directory + view + ".leaf")
        }
    }
    
    private func generateView(atPath path: String) throws {
        let templatePath = pathForTemplate(named: Templates.view.rawValue,
                                           extension: "leaftemplate")
        try copyTemplate(atPath: templatePath, toPath: path)
    }
    
}
