//
//  Generator.swift
//  Mapper
//
//  Created by LZephyr on 2017/9/26.
//  Copyright © 2017年 LZephyr. All rights reserved.
//

import Foundation

/// 遍历AST并生成dot
class DotGenerator {
    
    // MARK: - Public
    
    /// 在当前位置生成类图
    static func generate(_ nodes: [ClassNode], filePath: String) {
        let dot = DotGenerator()
        var nodesSet = Set<String>()
        
        dot.begin(name: "Inheritance")
        
        for cls in nodes {
            // 类节点
            if !nodesSet.contains(cls.className) {
                nodesSet.insert(cls.className)
                
                var name = ""
                if cls.protocols.count != 0 {
                    name = "{\(cls.className)|\\<\(cls.protocols.joined(separator: ", "))\\>}"
                } else {
                    name = "\(cls.className)"
                }
                dot.append(cls, label: name)
            }
            
            // 协议不单独作为节点显示, 避免图片过于混乱
//            for proto in cls.protocols {
//                if !nodesSet.contains(proto) {
//                    nodesSet.insert(proto)
//                    dot.append(proto, label: proto)
//                }
//                dot.point(from: cls, to: proto, emptyArrow: true, dashed: true)
//            }
            
            // 父类
            if let superCls = cls.superCls?.className {
                if !nodesSet.contains(superCls) {
                    nodesSet.insert(superCls)
                    dot.append(superCls, label: superCls)
                }
                dot.point(from: cls, to: superCls, emptyArrow: true)
            }
        }
        
        dot.end()
        
        create(dot: dot.dot, to: filePath)
    }
    
    /// 在当前位置生成调用关系图
    static func generate(_ methods: [ObjcMethodNode], filePath: String) {
        // 生成Dot描述
        let dot = DotGenerator()
        dot.begin(name: "CallGraph")
        
        var nodesSet = Set<Int>()
        var relationSet = Set<String>() // 避免重复连线
        for method in methods {
            // 添加节点定义
            if !nodesSet.contains(method.hashValue) {
                dot.append(method, label: method.description)
                nodesSet.insert(method.hashValue)
            }
            
            for invoke in method.invokes {
                if !nodesSet.contains(invoke.hashValue) {
                    dot.append(invoke, label: invoke.description)
                    nodesSet.insert(invoke.hashValue)
                }
                
                let relation = "\(method.hashValue)\(invoke.hashValue)"
                if !relationSet.contains(relation) && method.hashValue != invoke.hashValue {
                    dot.point(from: method, to: invoke)
                    relationSet.insert(relation)
                }
            }
        }
        
        dot.end()
        
        create(dot: dot.dot, to: filePath)
    }
    
    // MARK: - Private
    
    fileprivate var dot: String = ""
    
    fileprivate static func create(dot code: String, to filePath: String) {
        // 写入文件
        let filename = URL(fileURLWithPath: filePath).lastPathComponent
        let dotFile = "./\(filename).dot"
        let target = "./\(filename).png"
        
        // 创建Dot文件
        if FileManager.default.fileExists(atPath: dotFile) {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: dotFile))
        }
        _ = FileManager.default.createFile(atPath: dotFile, contents: code.data(using: .utf8), attributes: nil)
        
        // 生成png
        Executor.execute("dot", "-T", "png", dotFile, "-o", "\(target)")
        
        // 删除.dot文件
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: dotFile))
    }
}

// MARK: - Dot Generate Method

fileprivate extension DotGenerator {
    
    func begin(name: String) {
        dot.append(contentsOf: "digraph \(name) { node [shape=\"record\"];")
    }
    
    func end() {
        dot.append(contentsOf: "}")
    }
    
    func append<T: Hashable>(_ node: T, label: String) {
        dot.append(contentsOf: "\(node.hashValue) [label=\"\(label)\"];")
    }
    
    func point<T: Hashable, A: Hashable>(from: T, to: A, emptyArrow: Bool = false, dashed: Bool = false) {
        var style = ""
        if emptyArrow {
            style.append(contentsOf: "arrowhead = \"empty\" ")
        }
        if dashed {
            style.append(contentsOf: "style=\"dashed\"")
        }
        
        if !style.isEmpty {
            dot.append(contentsOf: "\(from.hashValue)->\(to.hashValue) [\(style)];")
        } else {
            dot.append(contentsOf: "\(from.hashValue)->\(to.hashValue);")
        }
    }
}
