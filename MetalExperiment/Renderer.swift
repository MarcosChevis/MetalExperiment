//
//  Renderer.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 22/02/24.
//
import MetalKit

final class Renderer: NSObject, MTKViewDelegate {
    
    var metalDevice: MTLDevice?
    var metalCommandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    
    private var clearColor: MTLClearColor  = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
    
    var polygons: [RegularPolygon] =  {
        var pols = [RegularPolygon]()
        let numberOfPolygons = 1000
        
        let minValue: Float = -1.0
        let maxValue: Float = 1.0

        let vector = (0..<numberOfPolygons).map { index in
            let t = Float(index) / Float(numberOfPolygons - 1)
            return (1 - t) * minValue + t * maxValue
        }
        
        for i in 0..<numberOfPolygons {
            let center: simd_float2 = [vector[i], 0]
            let radius: Float = 0.1
            let amountOfSides: Int32 = 100
            let color: simd_float4 = [0, 0, 0, 1]
            
            let polygon = RegularPolygon(center: center, radius: radius, amountOfSides: amountOfSides)
            pols.append(polygon)
        }
        return pols
    }()
    
    init(metalDevice: MTLDevice?) {
        self.metalDevice = metalDevice
        super.init()
        self.metalCommandQueue = metalDevice?.makeCommandQueue()
        self.pipelineState = makePipelineState()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let metalDevice = self.metalDevice,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = metalCommandQueue?.makeCommandBuffer(),
              let pipelineState = self.pipelineState else {
            preconditionFailure("Could not draw")
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            preconditionFailure("Could not create render encoder")
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        let vertices = polygons.flatMap { $0.triangulated() }
        let vertexBuffer = metalDevice.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: Pipeline State
extension Renderer {
    
    private func makePipelineState() -> MTLRenderPipelineState? {
        guard let library = metalDevice?.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            preconditionFailure("Could not get shader functions")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            return try metalDevice?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            preconditionFailure("Could not create pipeline state: \(error)")
        }
    }
}
