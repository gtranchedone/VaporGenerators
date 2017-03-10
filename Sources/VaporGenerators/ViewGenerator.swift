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
        var viewsToGenerate = arguments.values
        guard viewsToGenerate.count > 0 else {
            throw ConsoleError.argumentNotFound
        }
        
        var directory = Directories.views.rawValue
        if arguments.flag(Arguments.useFirstArgumentAsDirectory.rawValue) {
            directory += viewsToGenerate.removeFirst().lowercased()
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
        console.info("Generating \(path)")
        let templatePath = pathForTemplate(named: Templates.view.rawValue,
                                           extension: "leaftemplate")
        try File(path: templatePath).saveCopy(atPath: path)
    }
    
}
