//
//  Color+toSimdFloat4.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 09/03/24.
//

import SwiftUI
#if os(iOS)
import UIKit
typealias AppColor = UIColor
#elseif os(macOS)
import AppKit
typealias AppColor = NSColor
#endif

extension Color {
    func toSimdFloat4() -> simd_float4 {
        guard let resolved = AppColor(self).cgColor.components else { return .init(Float.zero, Float.zero, Float.zero, Float.zero) }
        return [resolved[0].float, resolved[1].float, resolved[2].float, resolved[3].float]
    }
}
