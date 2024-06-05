//
//  Drawer.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 09/03/24.
//

import Foundation
import MetalKit
import SwiftUI

final class Drawer {
    var setup: Setup = .init()
    private var polygons: [RegularPolygon] = []
    
    private func addPolygon(poly: RegularPolygon) {
        polygons.append(poly)
    }
    
    @discardableResult
    func drawSquare(
        center: CGPoint,
        sideSize: Float,
        color: Color = .white,
        rotation: Float = 0
    ) -> Self {
        addPolygon(
            poly: RegularPolygon(
                center: center.simdFloat2,
                radius: sqrt(sideSize)/2,
                amountOfSides: 4,
                color: color.toSimdFloat4(),
                rotationAngle: rotation + .pi/4,
                bufferStart: 0
            )
        )
        return self
    }
    
    @discardableResult
    func drawRegularPolygon(
        polygon: RegularPoly
    ) -> Self {
        addPolygon(
            poly: RegularPolygon(
                center: polygon.center.simdFloat2,
                radius: polygon.radius,
                amountOfSides: Int32(polygon.amountOfSides),
                color: polygon.color.toSimdFloat4(),
                rotationAngle: polygon.rotationAngle,
                bufferStart: 0
            )
        )
        return self
    }
    
    @discardableResult
    func drawCircle(
        center: CGPoint,
        radius: Float,
        color: Color = .white
    ) -> Self {
        addPolygon(
            poly: RegularPolygon(
                center: center.simdFloat2,
                radius: radius,
                amountOfSides: 360,
                color: color.toSimdFloat4(),
                rotationAngle: 0,
                bufferStart: 0
            )
        )
        return self
    }
    
    @discardableResult
    func setBackgroundColor(
        color: Color
    ) -> Self {
        let adaptedColor = color.toSimdFloat4()
        setup.backgroundColor = MTLClearColorMake(
            Double(adaptedColor[0]),
            Double(adaptedColor[1]),
            Double(adaptedColor[2]),
            Double(adaptedColor[3] )
        )
        return self
    }
    
    func popPolygons() -> [RegularPolygon] {
        defer {
            polygons = []
        }
        return polygons
    }
}

struct Setup {
    var backgroundColor: MTLClearColor = .init(
        red: 0,
        green: 0,
        blue: 0,
        alpha: 1
    )
}
