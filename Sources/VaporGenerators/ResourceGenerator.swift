import Console

internal final class ResourceGenerator: AbstractGenerator {
    
    override internal var signature: [Argument] {
        return super.signature + [
            Value(name: "properties", help: ["An optional list of properties for the resource Model class in the format variable:type (e.g. firstName:string lastname:string)"]),
            Value(name: "actions", help: ["An optional list of actions. Routes and Views will be created for each action."]),
            Option(name: "no-css", help: ["If true it doen't create a CSS file for the controller, defaults to true if 'actions' is empty."]),
            Option(name: "no-js", help: ["If true it doen't create a JavsScript file for the controller, defaults to true if 'actions' is empty."]),
        ]
    }
    
    override func performGeneration(arguments: [String]) throws {
        let controllerGenerator = ControllerGenerator(console: console)
        try controllerGenerator.generate(arguments: arguments + ["--resource"])
    }
    
}
