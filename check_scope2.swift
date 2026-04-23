import Foundation

let file = try! String(contentsOfFile: "/Users/leia/.openclaw/workspace/DailyWrite/DailyWrite/Views/ContentView.swift", encoding: .utf8)
let lines = file.components(separatedBy: .newlines)

var braceCount = 0
var lineNum = 0

for line in lines {
    lineNum += 1
    
    // Count braces, but ignore those inside strings
    var inString = false
    var escaped = false
    var openBraces = 0
    var closeBraces = 0
    
    for char in line {
        if escaped {
            escaped = false
            continue
        }
        if char == "\\" {
            escaped = true
            continue
        }
        if char == "\"" {
            inString = !inString
            continue
        }
        if !inString {
            if char == "{" {
                openBraces += 1
            } else if char == "}" {
                closeBraces += 1
            }
        }
    }
    
    braceCount += openBraces - closeBraces
    
    if lineNum >= 530 {
        print("Line \(lineNum) (count=\(braceCount)): \(line.prefix(50))")
    }
}

print("\nFinal brace count: \(braceCount)")
