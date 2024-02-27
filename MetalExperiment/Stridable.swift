//
//  Stridable.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 21/02/24.
//

import Foundation

protocol Stridable {
    func getStride() -> Int
}

extension Stridable {
    func getStride() -> Int {
        MemoryLayout<Self>.stride
    }
}

extension Vertex: Stridable {}
extension RegularPolygon: Stridable {}
extension Int: Stridable {}

extension Array: Stridable where Element: Stridable {
    func getStride() -> Int {
        count * (first?.getStride() ?? 0)
    }
}
