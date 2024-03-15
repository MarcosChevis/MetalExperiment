//
//  CGPoint+toSimdFloat2.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 09/03/24.
//

import Foundation

extension CGPoint {
    var simdFloat2: simd_float2 {
        [self.x.float, self.y.float]
    }
}
