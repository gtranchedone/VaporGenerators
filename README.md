# Vapor Generators

VaporGenerators is a package that extends [Vapor](https://vapor.codes) to add a command line tool that generates classes and files automagically for you. It is very much inspired from Rails' command line tools.

## Compatibility

This Generators have been tested on macOS. Linux users beware: this might not work for you!

## Installation

You can install the generators using 3 simple steps:

1. Add this Package as a dependency to your project
2. Configure your `Droplet` with the `Generate` command.
3. Build your project

### Step 1. Add this Package to your project

```swift
// In your project's Package.swift file
Package(
    ...
    dependencies: [
        .Package(url: "https://github.com/gtranchedone/VaporGenerators.git", majorVersion: 0),
        ...
    ]
    ...
)
```

### Step 2. Configure your Droplet

```swift
// In your project's main.swift file
let drop = Droplet()
...
drop.commands.append(Generate(console: drop.console))
drop.run()
```

### Step 3. Build your project

```shell
# In a Terminal window
cd /path/to/your/project
swift build
```

## Usage

After you've installed the `Generate` command, you can use the generator from the command line, like so:

```shell
# In a Terminal window
cd /path/to/your/project
vapor run generate [generator-type] [arguments]
vapor build    # or
vapor xcode -y # if you use Xcode or AppCode
```

See the list of generator types below for details of what generators are available and what arguments they accept.

## Available Generators

### model
---

Generates a model class and an associated test class.

For example, running the command `vapor run generate model foo` would produce the classes highlighted by this structure:

```
MyProject
├── ...
├── Sources
|   └── App
|       ├── ...
|       └── Models
|           ├── ...
|           └── Foo.swift
└── Tests
    └── AppTests
        └── Models
            ├── ...
            └── FooTests.swift
```

#### Parameters

##### name (required)

The name of the model. The generator always capitalizes this parameter before using it.

##### properties (optional)

A space separated list of strings in the format `propertyName:propertyType`.

E.g. `vapor run generate model user firstName:string lastName:string` would generate the following:

```swift
import Vapor
import Fluent
import Foundation

final class User: Model {
    
    fileprivate static let tableName = "users"
    
    var id: Node?
    var firstName: String
    var lastName: String
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        firstName = try node.extract("first_name")
        lastName = try node.extract("last_name")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "first_name": firstName,
            "last_name": lastName,
        ])
    }
    
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(User.tableName) {
            $0.id()
            $0.string("first_name")
            $0.string("last_name")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(User.tableName)
    }
}

```

### view
---

Generate Leaf views.

#### Parameters

##### names (required)

A list of names for the views to generate.

##### --useFirstArgumentAsDirectory (optional)

If this flag is passed, the first name in the list is used as a directory name in which all other views are generated.

### controller
---

Generate a controller class. By default the command creates an empty controller. If you pass the `--resource` flag, it creates a controller that conforms to the `Vapor.ResourceRepresentable` protocol instead.

#### Parameters

##### name (required)

The name of the controller. This can be either a _singular_ resource name such as `Post` or a fully formed controller name such as `PostsController`. In both cases, the name `PostsController` is the final name the generator would use.

Example outputs

- "Post" => "PostsController"
- "PostsController" => "SettingsController"
- "Keyboard" => "KeyboardsController"
- "KeyboardController" => "KeyboardController"

##### actions (optional)

A space separated list of strings. By default this represent methods that the generated controller will implement. When the `--resource` flag is passed to the generator, the actions are interpreted as names of the `Vapor.Resource` actions to be implemented.

Examples

The command `vapor run generate controller MyController foo bar` would produce

```swift
import Vapor
import HTTP

final class MyController {
    let droplet: Droplet
    
    init(droplet: Droplet) {
      self.droplet = droplet
    }
    
    func foo(request: request) throws -> ResourceRepresentable {
        return try droplet.view.make("my/foo")
    }
    
    func bar(request: request) throws -> ResourceRepresentable {
        return try droplet.view.make("my/bar")
    }
}
```

### route
---

Generates a route with the specified parameters.

#### Parameters

##### path (required)

The path to created relative to the root.

##### method (optional)

The HTTP method to use when creating the path. Defaults to `get`.

##### handler (optional)

A string representing code to execute as part of the route's handling closure. E.g. `try droplet.view.make("index")`.

_NOTE:_ Although available, you shouldn't really use this method. Simply generate the route and then use your favorite text editor or IDE to change the route's handling implementation.

##### --resource (optional)

When specified, the generator creates resource paths using Vapor's `resource` method and ignores the `method` and `handler` parameters.

#### Examples

```shell
vapor run generate route foo
```

```swift
// In your routes file
droplet.get("foo") { request in
    return JSON([:])
}
```

```shell
vapor run generate route bar --resource
```

```swift
// In your routes file
droplet.resource("bars", BarsController())
...

extension Droplet {
    func pathForBars() -> String {
        return "bars"
    }
    
    func path(for model: _RESOURCE_) throws -> String {
        guard let id = model.id?.int else { throw Abort.badRequest }
        return pathForBars() + "/\(id)"
    }
    
    func pathForCreatingBars() throws -> String {
        return try pathForBars() + "/new"
    }
    
    func path(forEditing model: _RESOURCE_) throws -> String {
        return try path(for: model) + "/edit"
    }
}
```

### resource
---

This produces a Model, Views, a Controller and Routes using the respective generators and passing the arguments along. Additionally, it creates style and script files for the specified resource.

For example, running `vapor run generate resource user index show firstName:string lastName:string` would create the following files:

```
MyProject
├── ...
├── Public
|   ├── scripts
|   |   ├── ...
|   |   └── users.js
|   └── styles
|       ├── ...
|       └── users.css
├── Resources
|   └── Views
|       ├── ...
|       └── users
|           ├── index.leaf
|           └── show.leaf
├── Sources
|   └── App
|       ├── ...
|       ├── Models
|       |   ├── ...
|       |   └── User.swift
|       └── Controllers
|           ├── ...
|           └── UsersController.swift
└── Tests
    └── AppTests
        ├── ...
        ├── Models
        |   ├── ...
        |   └── UserTests.swift
        └── Controllers
            ├── ...
            └── MyControllerTests.swift
```

See the other generator's details to see how each file's content is generated.

#### Parameters

See the parameters accepted by the other generators.

### tests
---

Generates a test class for the passed in class name. It also creates a `LinuxMain.swift` file if one is not found and updates it for each generated test case.

#### Parameters

##### className (required)

The name of the class for which you want to generate tests or a the name of the test class itself. Valid inputs are:

- `MyController` => will produce `MyControllerTests`
- `MyControllerTests` => will produce `MyControllerTests`
- `TestMyController` => will produce `TestMyController`

##### directory (optional)

The path where the test class is to be generated. Defaults to `Tests/AppTests/`. An example input would be `Tests/AppTests/Controllers/`.

## Customization

You can customize the `generate` command to use your own generators like so:

```swift
// In your project's main.swift file
let generateCommand = Generate(console: droplet.console)
generateCommand["model"] = MyModelGenerator.self
generateCommand["my-custom-generator"] = MyCustomGenerator.self
drop.commands.append(generateCommand)
```

To use your custom generators, you would run the same command as before:

```shell
# In a Terminal window
cd /path/to/your/project
vapor run generate model [arguments]
vapor run generate my-custom-generator [arguments]
```

## TODO

- [ ] Test on Linux
- [ ] Add Unit Tests
