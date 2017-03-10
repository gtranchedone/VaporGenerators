import Console

internal final class ViewGenerator: AbstractGenerator {
    
    private enum Directories: String {
        case views = "Resources/Views/"
    }
    
    private enum Templates: String {
        case view = "View"
    }
    
    override func performGeneration(arguments: [String]) throws {
        guard let name = arguments.first else {
            throw ConsoleError.argumentNotFound
        }
        if arguments.flag("resource") {
            try generateViews(forResourceNamed: name.lowercased(), actions: Array(arguments[1 ..< arguments.count]).values)
        }
        else {
            try generateView(atPath: "\(Directories.views.rawValue)/\(name.lowercased()).leaf")
        }
    }
    
    private func generateViews(forResourceNamed resourceName: String, actions: [String]) throws {
        let viewDirectory = "\(Directories.views.rawValue)\(resourceName.pluralized)/"
        console.info("Generating directory \(viewDirectory)")
        try File.createDirectory(atPath: viewDirectory)
        if actions.isEmpty {
            let gitKeep = File(path: viewDirectory + ".gitkeep", contents: "")
            try gitKeep.save()
        }
        for action in actions {
            try generateView(atPath: "\(viewDirectory)\(action).leaf")
        }
    }
    
    private func generateView(atPath path: String) throws {
        console.info("Generating \(path)")
        let templatePath = pathForTemplate(named: Templates.view.rawValue, extension: "leaftemplate")
        try File(path: templatePath).saveCopy(atPath: path)
    }
    
}
