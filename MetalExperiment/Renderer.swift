//
//  Renderer.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 22/02/24.
//

import MetalKit

final class Renderer: NSObject, MTKViewDelegate {
    
    private let things = Things.shared
    
    private let polygonRenderPipelineState: MTLRenderPipelineState
    private let polygonTriangulationComputePipelineState: MTLComputePipelineState
    
    private var clearColor: MTLClearColor  = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
    
    override init() {
        self.polygonRenderPipelineState = things.makePolygonRenderPipelineState()
        self.polygonTriangulationComputePipelineState = things.makePolygonTriangulationComputePipelineState()
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    var polygons: [RegularPolygon] = [
//        .init(center: [0, 0], radius: 1, amountOfSides: 8, color: [1, 1, 1, 1], rotationAngle: .pi/3, bufferStart: 0),
//        .init(center: [0, 0], radius: 1, amountOfSides: 8, color: [1, 1, 1, 1], rotationAngle: 0, bufferStart: 0)
    ]
    
    func draw(in view: MTKView) {
        if !polygons.isEmpty { drawPolygons(in: view) }
    }
    
    
    private func drawPolygons(in view: MTKView) {
        
        var vertexCount = Int32.zero
        var indexCount = Int32.zero
        for i in 0..<polygons.count {
            polygons[i].bufferStart = vertexCount
            vertexCount += polygons[i].amountOfSides + 1
            indexCount += polygons[i].amountOfSides * 3
        }
        
        guard let polygonsBuffer = createPolygonsBuffer(),
              let verticesArrayBuffer = createVerticesArrayBuffer(vertexCount: vertexCount),
              let indicesArrayBuffer = createIndexBuffer(indexCount: indexCount) else {
            preconditionFailure("Buffer could not be created")
        }
        
        triangulatePolygons(
            polygonsBuffer: polygonsBuffer,
            indicesArrayBuffer: indicesArrayBuffer,
            verticesArrayBuffer: verticesArrayBuffer
        )
        
        renderPolygons(
            verticesArrayBuffer: verticesArrayBuffer,
            indicesArrayBuffer: indicesArrayBuffer,
            indexCount: indexCount,
            drawable: view.currentDrawable,
            renderPassDescriptor: view.currentRenderPassDescriptor
        )
    }

    private func triangulatePolygons(
        polygonsBuffer: MTLBuffer,
        indicesArrayBuffer: MTLBuffer,
        verticesArrayBuffer: MTLBuffer
    ) {
        guard let commandBuffer = things.commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            preconditionFailure("Failed to create command buffer or command encoder")
        }
        commandEncoder.setComputePipelineState(polygonTriangulationComputePipelineState)
        commandEncoder.setBuffer(polygonsBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(indicesArrayBuffer, offset: 0, index: 1)
        commandEncoder.setBuffer(verticesArrayBuffer, offset: 0, index: 2)
        
        let threadsPerGrid = MTLSize(width: polygons.count, height: 1, depth: 1)
        let maxThreadsPerThreadgroup = polygonTriangulationComputePipelineState.maxTotalThreadsPerThreadgroup
        let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1)
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        commandBuffer.commit()
    }
    
    private func renderPolygons(
        verticesArrayBuffer: MTLBuffer,
        indicesArrayBuffer: MTLBuffer,
        indexCount: Int32,
        drawable: CAMetalDrawable?,
        renderPassDescriptor: MTLRenderPassDescriptor?
    ) {
        guard let drawable,
              let renderPassDescriptor,
              let newCommandBuffer = things.commandQueue.makeCommandBuffer(),
              let renderEncoder = newCommandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            preconditionFailure("Failed to create render command encoder")
        }

        renderEncoder.setRenderPipelineState(polygonRenderPipelineState)
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        renderEncoder.setVertexBuffer(verticesArrayBuffer, offset: 0, index: 0)
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: Int(indexCount), indexType: .uint32, indexBuffer: indicesArrayBuffer, indexBufferOffset: 0)
        renderEncoder.endEncoding()
        newCommandBuffer.present(drawable)
        newCommandBuffer.commit()
    }
}

// MARK: Create Buffers
extension Renderer {
    private func createPolygonsBuffer() -> MTLBuffer? {
        return things.device.makeBuffer(bytes: polygons, length: MemoryLayout<RegularPolygon>.stride * polygons.count)
    }
    private func createIndexBuffer(indexCount: Int32) -> MTLBuffer? {
        return things.device.makeBuffer(length: MemoryLayout<UInt32>.stride * Int(indexCount))
    }
    
    private func createVerticesArrayBuffer(vertexCount: Int32) -> MTLBuffer? {
        let verticesArrayLength =  Int(vertexCount) * MemoryLayout<Vertex>.stride
        return things.device.makeBuffer(length: verticesArrayLength)
    }
}
