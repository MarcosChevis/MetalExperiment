//
//  RegularPolygon.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 22/02/24.
//

import Foundation

extension RegularPolygon {
//    var center: vector_float2
//    let radius: Float32
//    let amountOfSides: Int32
//    let color: vector_float4
    
    func triangulated() -> [Vertex] {
        var vertices: [Vertex] = []
        
        let deltaAngle = Float32(360 / amountOfSides)
        var currentAngle: Float32 = 0
        var currentPoint: vector_float2 = [radius * cos(0 * Float32.pi / 180) + center[0], radius*sin(0 * Float32.pi / 180) + center[1]]
        
        while currentAngle < 360 {
            let nextPoint: vector_float2 = [radius*cos((currentAngle + deltaAngle) * Float32.pi / 180) + center[0], radius*sin((currentAngle + deltaAngle) * Float32.pi / 180) + center[1]]
            vertices.append(contentsOf: [Vertex(position: currentPoint, color: color), Vertex(position: center, color: color), Vertex(position: nextPoint, color: color)])
            currentPoint = nextPoint
            
            currentAngle += deltaAngle
        }
        
        
        return vertices
    }
    
}
