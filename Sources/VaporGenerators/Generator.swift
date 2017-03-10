import Console

public protocol Generator {
    var console: ConsoleProtocol { get }
    init(console: ConsoleProtocol)
    func generate(arguments: [String]) throws
}

public enum GeneratorError: Error {
    case general(String)
}

public final class Generate: Command {
    
    public let id: String = "generate"
    public let console: ConsoleProtocol
    
    public let signature: [Argument] = [
        Value(name: "type", help: ["model", "view", "controller", "resource", "routes"])
    ]
    
    public let help: [String] = [
    ]
    
    private var commands: [String : Generator.Type] = ["model": ModelGenerator.self,
                                                       "view": ViewGenerator.self,
                                                       "controller": ControllerGenerator.self,
                                                       "resource": ResourceGenerator.self,
                                                       "routes": RouteGenerator.self]
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func set(_ generator: Generator.Type, forType type: String) {
        commands[type] = generator
    }
    
    public func run(arguments: [String]) throws {
        guard let type = try value("type", from: arguments).string else { throw ConsoleError.argumentNotFound }
        guard let command = commands[type] else { throw ConsoleError.commandNotFound(type) }
        // Remove the generator type from the arguments.
        let passedOnArguments = Array(arguments[1 ..< arguments.count])
        try command.init(console: console).generate(arguments: passedOnArguments)
    }
    
}
