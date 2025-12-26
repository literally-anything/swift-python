// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

import Foundation
import RegexBuilder

func findExecutableInPath(executableName: String) -> String? {
    guard let path = ProcessInfo.processInfo.environment["PATH"] else {
        print("PATH environment variable not found.")
        return nil
    }

    let pathComponents = path.split(separator: ":").map(String.init)

    for directory in pathComponents {
        let fullPath = (directory as NSString).appendingPathComponent(executableName)
        if FileManager.default.isExecutableFile(atPath: fullPath) {
            return fullPath
        }
    }
    return nil
}

func findPythonInfo() -> (cFlags: [String], linkerFlags: [String], extSuffix: String, versionStr: String)? {
    let pythonConfigExecutable = findExecutableInPath(executableName: "python3-config")
    guard let pythonConfigExecutable else {
        return nil
    }

    func getOutput(_ arguments: [String]) -> [String]? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: pythonConfigExecutable)
        task.arguments = arguments
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
        } catch {
            print(error)
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else {
            return nil
        }
        return output.split(separator: "\n").compactMap { $0.isEmpty ? nil : $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    func getArgs(_ output: String?) -> [String]? {
        return output?.split(separator: " ").compactMap { $0.isEmpty ? nil : $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    let outputs = getOutput(["--cflags", "--ldflags", "--extension-suffix", "--prefix"])
    guard let outputs else {
        return nil
    }

    let cFlags = getArgs(outputs[0])
    guard let cFlags else {
        return nil
    }
    let ldFlags = getArgs(outputs[1])
    guard let ldFlags else {
        return nil
    }
    let extSuffix = outputs[2]

    let libDir = outputs[3] + "/lib"
    let files = try? FileManager.default.contentsOfDirectory(atPath: libDir)
    guard let files else {
        fatalError("Failed to list dir: \(libDir)")
    }
    var versionStr: String? = nil
    for file in files {
        let regex = Regex {
            "libpython"
            Capture {
                "3."
                OneOrMore {
                    CharacterClass.digit
                }
            }
            "."
            ChoiceOf {
                "dylib"
                "so"
            }
        }
        if let match = file.wholeMatch(of: regex) {
            versionStr = String(match.output.1)
        }
    }
    guard let versionStr else {
        fatalError("Could not find python version. Found no binary in \(libDir).")
    }

    return (cFlags, ldFlags, extSuffix, versionStr)
}

let swiftArgs: [SwiftSetting] = [
    .interoperabilityMode(.Cxx)
]
var cArgs: [CSetting] = [
    .unsafeFlags(["-Wno-module-import-in-extern-c"])
]
var cxxArgs: [CXXSetting] = []
var linkerArgs: [LinkerSetting] = []

if let pythonInfo = findPythonInfo() {
    cArgs.append(.unsafeFlags(pythonInfo.cFlags))
    cxxArgs.append(.unsafeFlags(pythonInfo.cFlags))
    linkerArgs.append(.unsafeFlags(pythonInfo.linkerFlags))

    let oldExtSuffix = try? String(contentsOfFile: ".extension_name", encoding: .utf8)
    if oldExtSuffix == nil || pythonInfo.extSuffix != oldExtSuffix {
        try pythonInfo.extSuffix.write(toFile: ".extension_name", atomically: true, encoding: .utf8)
    }

    linkerArgs.append(.linkedLibrary("python\(pythonInfo.versionStr)"))
}

let package = Package(
    name: "SwiftPython",
    platforms: [.macOS(.v26)],
    products: [
        .library(
            name: "SwiftPython",
            targets: ["SwiftPython", "CPython"]
        ),
        .library(name: "example.cpython-314-darwin", type: .dynamic, targets: ["Example"]),

        .plugin(name: "SwiftPythonPlugin", targets: ["SwiftPythonPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "602.0.0"),
        .package(url: "https://github.com/apple/swift-docc-symbolkit.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "CPython",
            cSettings: cArgs,
            cxxSettings: cxxArgs,
            swiftSettings: swiftArgs,
            linkerSettings: linkerArgs
        ),
        .target(
            name: "SwiftPython",
            dependencies: [
                "CPython",
                .product(name: "BasicContainers", package: "swift-collections")
            ],
            cSettings: cArgs,
            cxxSettings: cxxArgs,
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes")
            ] + swiftArgs,
            linkerSettings: linkerArgs
        ),

        .executableTarget(
            name: "SwiftPythonTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SymbolKit", package: "swift-docc-symbolkit"),
                .product(name: "SwiftBasicFormat", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
        .plugin(
            name: "SwiftPythonPlugin",
            capability: .command(
                intent: .custom(verb: "swift-python-gen", description: "Generate python bindings for a target."),
                permissions: [.writeToPackageDirectory(reason: "To output the bindings.")]
            ),
            dependencies: [
                "SwiftPythonTool"
            ]
        ),
        // This is temporary. It's just a bit easier to test quickly with this here.
        .target(name: "Example", dependencies: ["SwiftPython", "CPython"], path: "Samples/Example", cSettings: cArgs, cxxSettings: cxxArgs, swiftSettings: swiftArgs, linkerSettings: linkerArgs)
    ]
)
