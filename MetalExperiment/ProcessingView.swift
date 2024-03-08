//
//  ProcessingView.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 06/03/24.
//

import SwiftUI
import MetalKit

extension ProcessingView {
    func setup() {
        setClearColor(color: .gray)
    }
    
    func update() {
        square(center: .init(x: cos(drawer.time) / 2, y: sin(drawer.time) / 2), sideSize: 0.5, color: .green, rotation: Float(drawer.time))
        square(center: .init(x: sin(drawer.time) / 2, y: cos(drawer.time) / 2), sideSize: 0.5, color: .blue, rotation: Float(-drawer.time))
    }
}



struct ProcessingView: View {
    @Environment(\.self)
    var environment
    
    @State
    var drawer: Drawer = Drawer()
    
    var body: some View {
        MetalViewRepresentable(drawer: $drawer)
//            .frame(width: 500, height: 500)
            .onAppear {
                setup()
                drawer.update = self.update
            }
    }
    
    func square(center: CGPoint, sideSize: Float, color: Color, rotation: Float) {
        drawer.addPolygon(poly: RegularPolygon(center: center.toSimdFloat2(), radius: sqrt(sideSize)/2, amountOfSides: 4, color: color.toSimdFloat4(environment), rotationAngle: rotation, bufferStart: 0))
    }
    
    func setClearColor(color: Color) {
        let resolved = color.resolve(in: self.environment)
        drawer.setClearColor(color: (red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue), opacity: Double(resolved.opacity)))
    }
}

//#Preview {
//    ProcessingView()
//}

extension CGPoint {
    func toSimdFloat2() -> simd_float2 {
        [self.x.toFloat(), self.y.toFloat()]
    }
}

extension CGFloat {
    func toFloat() -> Float {
        Float(self)
    }
}

extension Color {
    func toSimdFloat4(_ env: EnvironmentValues) -> simd_float4 {
        let resolved = self.resolve(in: env)
        return [resolved.red, resolved.green, resolved.blue, resolved.opacity]
    }
}
