//
//  SourceEditorCommand.swift
//  ImportOrderExtension
//
//  Created by Petro Kolesnikov on 3/10/18.
//  Copyright © 2018 Petro. All rights reserved.
//

import Foundation
import XcodeKit

class SortImportsCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        let lines = invocation.buffer.lines
        
        var localImports = [ImportLine]()
        var pathImports = [String : [ImportLine]]()
        let importIndexes = NSMutableIndexSet()
        var firstImportIndex : Int?
        
        lines.enumerateObjects { (line, index, stop) in
            if let lineString = line as? String {
                if isImport(line: lineString) {
                    
                    if firstImportIndex == nil {
                        firstImportIndex = index
                    }
                    
                    let importLine = ImportLine(line: lineString)
                    if importLine.isLocal {
                        localImports.append(importLine)
                    } else {
                        if pathImports[importLine.moduleName] == nil {
                            pathImports[importLine.moduleName] = []
                        }
                        pathImports[importLine.moduleName]?.append(importLine)
                    }
                    
                    importIndexes.add(index)
                } else if lineString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if importIndexes.contains(index - 1) {
                        importIndexes.add(index)
                    }
                } else {
                    
                }
            }
        }
        
        lines.removeObjects(at: importIndexes as IndexSet)
        
        
        if var index = firstImportIndex {
            index = append(imports: localImports, to: lines, from: index)
            let sortedKeys = pathImports.keys.sorted(by: {$0.localizedStandardCompare($1) == .orderedAscending})
            
            for key in sortedKeys {
                index = append(imports: pathImports[key]!, to: lines, from: index)
            }
        }
        
        completionHandler(nil)
    }
    
    // MARK: Private
    
    func append(imports : [ImportLine], to lines: NSMutableArray, from index: Int) -> Int {
        var newIndex = index
        imports.sorted(by: { (line1, line2) -> Bool in
            return line1.fileName.localizedStandardCompare(line2.fileName) == .orderedAscending
        }).forEach {
            lines.insert($0.importString, at: newIndex)
            newIndex += 1
        }
        lines.insert("", at: newIndex)
        newIndex += 1
        return newIndex
    }
    
    func isImport(line: String) -> Bool {
        let regexp = try? NSRegularExpression(pattern: "#import[ ]+([<\"].+[>\"])", options: [])
        let match = regexp?.firstMatch(in: line, options: [], range: NSMakeRange(0, line.count))
        return match != nil
    }
}

class ImportLine {
    let moduleName : String
    let fileName : String
    
    let isLocal: Bool
    
    init(line: String) {
        isLocal = line.contains("\"")
        
        let regexp = try? NSRegularExpression(pattern: "#import[ ]+[<\"](.+)[>\"]", options: [])
        let first = regexp?.firstMatch(in: line, options: [], range: NSMakeRange(0, line.count))
        let importPath = NSString(string: ((line as NSString).substring(with: first!.range(at: 1))))
        
        fileName = importPath.lastPathComponent
        moduleName = importPath.deletingLastPathComponent
    }
    
    var importString : String {
    
        let importPath = (moduleName as NSString).appendingPathComponent(fileName)
        if isLocal {
            return "#import \"\(importPath)\""
        } else {
            return "#import <\(importPath)>"
        }
    }
}


