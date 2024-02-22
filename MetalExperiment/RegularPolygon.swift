//
//  RegularPolygon.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 22/02/24.
//

import Foundation

struct RegularPolygon {
    let center: vector_float2
    let radius: Float32
    let amountOfSides: Int32
    
    func triangulated() -> [Vertex] {
        var vertices: [Vertex] = []
        
        let deltaAngle = Float32(360 / amountOfSides)
        var currentAngle: Float32 = 0
        var currentPoint: vector_float2 = [radius * cos(0 * Float32.pi / 180) + center[0], radius*sin(0 * Float32.pi / 180) + center[1]]
        
        while currentAngle < 360 {
            let nextPoint: vector_float2 = [radius*cos((currentAngle + deltaAngle) * Float32.pi / 180) + center[0], radius*sin((currentAngle + deltaAngle) * Float32.pi / 180) + center[1]]
            vertices.append(contentsOf: [Vertex(position: currentPoint, color: [0, 0, 0, 1]), Vertex(position: center, color: [0, 0, 0, 1]), Vertex(position: nextPoint, color: [0, 0, 0, 1])])
            currentPoint = nextPoint
            
            currentAngle += deltaAngle
        }
        
        
        return vertices
    }
    
}
