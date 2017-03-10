import Foundation
import Console

open class AbstractGenerator: Generator {
    
    public let console: ConsoleProtocol
    
    open var signature: [Argument] {
        return []
    }
    
    open var help: [String] {
        return []
    }
    
    public required init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public final func generate(arguments: [String]) throws {
        guard File.exists(atPath: "Sources/App/") else {
            throw GeneratorError.general("Please run this command from your project's root folder.")
        }
        try performGeneration(arguments: arguments)
    }
    
    open func performGeneration(arguments: [String]) throws {
        throw GeneratorError.general("'\(String(describing: AbstractGenerator.self))' is meant to be subclassed.")
    }
    
}
