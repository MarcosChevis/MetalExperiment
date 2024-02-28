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
    var renderPipelineState: MTLRenderPipelineState?
    var library: MTLLibrary?
    var triangulationPipelineState: MTLComputePipelineState?
    
    var vertices: [Vertex] = []
    private var clearColor: MTLClearColor  = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
    
    init(metalDevice: MTLDevice?) {
        self.metalDevice = metalDevice
        super.init()
        self.metalCommandQueue = metalDevice?.makeCommandQueue()
        self.renderPipelineState = makePipelineState()
        let triangulatePolygonsGPUFunc = library?.makeFunction(name: "triangulateRegularPoly")
        self.triangulationPipelineState = try! metalDevice!.makeComputePipelineState(function: triangulatePolygonsGPUFunc!)
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    var polygons: [RegularPolygon] = {
        var pols = [RegularPolygon]()
        let gridSize = 100 // Number of polygons per row and column
        var bufferStart: Int32 = 0
        
        let minValue: Float = -1.0 + 0.01 // Adjusted to leave space for the edge squares
        let maxValue: Float = 1.0 - 0.01 // Adjusted to leave space for the edge squares
        let step: Float = 2.0 / Float(gridSize - 1)
        
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                let x = minValue + step * Float(i)
                let y = minValue + step * Float(j)
                let center: simd_float2 = [x, y]
                let radius: Float = 0.01
                let amountOfSides: Int32 = 4 // Change the number of sides for each polygon
                let color: simd_float4 = [1, 1, 1, 1] // Change the color for each polygon
                
                let polygon = RegularPolygon(center: center, radius: radius, amountOfSides: amountOfSides, color: color, rotationAngle: .pi/4, bufferStart: bufferStart)
                pols.append(polygon)
                
                // Update bufferStart for the next polygon
                bufferStart += Int32(Int(amountOfSides) * 3) // Assuming each polygon will have 3 vertices per side
            }
        }
        return pols
    }()

    func draw(in view: MTKView) {
        guard let metalDevice = metalDevice,
              let metalCommandQueue = metalCommandQueue,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderPipelineState = renderPipelineState,
              let triangulationPipelineState = triangulationPipelineState else {
            preconditionFailure("Metal objects not properly initialized")
        }
        
        guard let polygonsBuffer = createPolygonsBuffer(metalDevice),
              let resultArrayBuffer = createResultArrayBuffer(metalDevice) else {
            preconditionFailure("Buffer could not be created")
        }
        
        triangulatePolygons(
            polygonsBuffer: polygonsBuffer,
            resultArrayBuffer: resultArrayBuffer,
            triangulationPipelineState: triangulationPipelineState, 
            commandQueue: metalCommandQueue
        )
        renderTriangles(
            resultArrayBuffer: resultArrayBuffer,
            renderPipelineState: renderPipelineState,
            renderPassDescriptor: renderPassDescriptor,
            drawable: drawable,
            commandQueue: metalCommandQueue,
            device: metalDevice
        )
    }

    private func createPolygonsBuffer(_ device: MTLDevice) -> MTLBuffer? {
        return device.makeBuffer(bytes: polygons, length: MemoryLayout<RegularPolygon>.stride * polygons.count, options: [])
    }

    private func createResultArrayBuffer(_ device: MTLDevice) -> MTLBuffer? {
        let resultArrayLength = polygons.reduce(0) { $0 + Int($1.amountOfSides) } * MemoryLayout<Vertex>.stride * 3
        return device.makeBuffer(length: resultArrayLength, options: [])
    }

    private func triangulatePolygons(
        polygonsBuffer: MTLBuffer,
        resultArrayBuffer: MTLBuffer,
        triangulationPipelineState: MTLComputePipelineState,
        commandQueue: MTLCommandQueue
    ) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            preconditionFailure("Failed to create command buffer or command encoder")
        }
        commandEncoder.setComputePipelineState(triangulationPipelineState)
        commandEncoder.setBuffer(polygonsBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(resultArrayBuffer, offset: 0, index: 1)
        let threadsPerGrid = MTLSize(width: polygons.count, height: 1, depth: 1)
        let maxThreadsPerThreadgroup = triangulationPipelineState.maxTotalThreadsPerThreadgroup
        let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1)
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    private func renderTriangles(
        resultArrayBuffer: MTLBuffer,
        renderPipelineState: MTLRenderPipelineState,
        renderPassDescriptor: MTLRenderPassDescriptor,
        drawable: CAMetalDrawable,
        commandQueue: MTLCommandQueue,
        device: MTLDevice
    ) {
        guard let newCommandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = newCommandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            preconditionFailure("Failed to create render command encoder")
        }
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        let resultArrayLength = polygons.reduce(0) { $0 + Int($1.amountOfSides) } * MemoryLayout<Vertex>.stride * 3
        let vertexBuffer = device.makeBuffer(bytesNoCopy: resultArrayBuffer.contents(), length: resultArrayLength, options: [], deallocator: nil)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: resultArrayLength / MemoryLayout<Vertex>.stride)
        renderEncoder.endEncoding()
        newCommandBuffer.present(drawable)
        newCommandBuffer.commit()
        newCommandBuffer.waitUntilCompleted()
    }
}

// MARK: Pipeline State
extension Renderer {
    private func makePipelineState() -> MTLRenderPipelineState? {
        guard let library = metalDevice?.makeDefaultLibrary() else { preconditionFailure("could not get default library") }
        self.library = library
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        guard let pipelineState = try? metalDevice?.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            preconditionFailure("could not get pipeline state")
        }
        return pipelineState
    }
}
