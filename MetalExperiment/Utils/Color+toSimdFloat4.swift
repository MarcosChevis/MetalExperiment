//
//  Color+toSimdFloat4.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 09/03/24.
//

import SwiftUI

extension Color {
    func toSimdFloat4(_ env: EnvironmentValues) -> simd_float4 {
        let resolved = self.resolve(in: env)
        return [resolved.red, resolved.green, resolved.blue, resolved.opacity]
    }
}
