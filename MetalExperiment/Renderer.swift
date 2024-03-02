//
//  Renderer.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 22/02/24.
//

import MetalKit

let SIZE: Int32 = 500
var vertexCount1 = 0

final class Renderer: NSObject, MTKViewDelegate {
    
    var metalDevice: MTLDevice?
    var metalCommandQueue: MTLCommandQueue?
    var renderPipelineState: MTLRenderPipelineState?
    var library: MTLLibrary?
    var triangulationPipelineState: MTLComputePipelineState?
    var timer = Timer()
    
    private var clearColor: MTLClearColor  = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
    var game: GameOfLifeRenderer?
    
    init(metalDevice: MTLDevice?) {
        self.metalDevice = metalDevice
        
        super.init()
        self.metalCommandQueue = metalDevice?.makeCommandQueue()
        self.library = metalDevice?.makeDefaultLibrary()
        self.renderPipelineState = makePipelineState()
        let nextStateFunc = library?.makeFunction(name: "getNextState")
        let nextStatePipeline = try? metalDevice?.makeComputePipelineState(function: nextStateFunc!)
        self.game = GameOfLifeRenderer(gridSize: SIZE, nextStatePipeline: nextStatePipeline!)
        let triangulatePolygonsGPUFunc = library?.makeFunction(name: "triangulateRegularPoly")
        self.triangulationPipelineState = try! metalDevice!.makeComputePipelineState(function: triangulatePolygonsGPUFunc!)
        
        game?.initializeRandomState()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    var polygons: [RegularPolygon] = {
        Renderer.makePolys()
    }()
    
    static func makePolys() -> [RegularPolygon] {
        var pols = [RegularPolygon]()
        let step = 2.0 / Float(SIZE)
        let radius: Float = step * 0.5 // Set the radius to half of the step to fit the polygons exactly within the screen
        let amountOfSides: Int32 = 5
        var bufferStart: Int32 = 0
        let color = simd_float4(0, 0, 0, 0)
        
        for i in 0..<SIZE {
            for j in 0..<SIZE {
                // Calculate the center of the polygon
                let centerX = -1.0 + Float(i) * step + step * 0.5
                let centerY = -1.0 + Float(j) * step + step * 0.5
                let center: simd_float2 = [centerX, centerY]
                
                pols.append(
                    RegularPolygon(
                        center: center,
                        radius: radius,
                        amountOfSides: amountOfSides,
                        color: color,
                        rotationAngle: .pi/2,
                        bufferStart: bufferStart
                    )
                )
                
                bufferStart += amountOfSides + 1
            }
        }
        
        return pols
    }

    func draw(in view: MTKView) {
        guard let metalDevice = metalDevice,
              let metalCommandQueue = metalCommandQueue,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderPipelineState = renderPipelineState,
              let triangulationPipelineState = triangulationPipelineState else {
            preconditionFailure("Metal objects not properly initialized")
        }
        
        var vertexCount = Int32.zero
        var indexCount = Int32.zero
        game?.updateCellState(using: metalCommandQueue, device: metalDevice)
        for i in 0..<polygons.count {
            let num = Float(game!.cellState[i])
            polygons[i].color = [num, num, num, 1]
            vertexCount += polygons[i].amountOfSides + 1
            indexCount += polygons[i].amountOfSides * 3
        }
        vertexCount1 = Int(vertexCount)
        
        guard let polygonsBuffer = createPolygonsBuffer(metalDevice),
              let verticesArrayBuffer = createVerticesArrayBuffer(metalDevice, vertexCount: vertexCount),
              let indexArrayBuffer = createIndexBuffer(metalDevice, indexCount: indexCount) else {
            preconditionFailure("Buffer could not be created")
        }
        
        triangulatePolygons(
            polygonsBuffer: polygonsBuffer,
            indexArrayBuffer: indexArrayBuffer,
            verticesArrayBuffer: verticesArrayBuffer,
            triangulationPipelineState: triangulationPipelineState,
            commandQueue: metalCommandQueue
        )
        renderTriangles(
            verticesArrayBuffer: verticesArrayBuffer,
//            verticesArrayLength: Int(vertexCount),
            indexArrayBuffer: indexArrayBuffer,
            indexCount: indexCount,
            renderPipelineState: renderPipelineState,
            renderPassDescriptor: renderPassDescriptor,
            drawable: drawable,
            commandQueue: metalCommandQueue,
            device: metalDevice
        )
    }
    
    
    private func createPolygonsBuffer(_ device: MTLDevice) -> MTLBuffer? {
        return device.makeBuffer(bytes: polygons, length: MemoryLayout<RegularPolygon>.stride * polygons.count)
    }
    private func createIndexBuffer(_ device: MTLDevice, indexCount: Int32) -> MTLBuffer? {
        return device.makeBuffer(length: MemoryLayout<UInt32>.stride * Int(indexCount))
    }

    private func createVerticesArrayBuffer(_ device: MTLDevice, vertexCount: Int32) -> MTLBuffer? {
        let verticesArrayLength =  Int(vertexCount) * MemoryLayout<Vertex>.stride
        return device.makeBuffer(length: verticesArrayLength, options: [])
    }

    private func triangulatePolygons(
        polygonsBuffer: MTLBuffer,
        indexArrayBuffer: MTLBuffer,
        verticesArrayBuffer: MTLBuffer,
        triangulationPipelineState: MTLComputePipelineState,
        commandQueue: MTLCommandQueue
    ) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            preconditionFailure("Failed to create command buffer or command encoder")
        }
        commandEncoder.setComputePipelineState(triangulationPipelineState)
        commandEncoder.setBuffer(polygonsBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(indexArrayBuffer, offset: 0, index: 1)
        commandEncoder.setBuffer(verticesArrayBuffer, offset: 0, index: 2)
        
        let threadsPerGrid = MTLSize(width: polygons.count, height: 1, depth: 1)
        let maxThreadsPerThreadgroup = triangulationPipelineState.maxTotalThreadsPerThreadgroup
        let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1)
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    private func renderTriangles(
        verticesArrayBuffer: MTLBuffer,
//        verticesArrayLength: Int,
        indexArrayBuffer: MTLBuffer,
        indexCount: Int32,
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
        
        if false {
            print(indexCount, "aqui")
            for i in 0..<indexCount {
                print(indexArrayBuffer.contents().assumingMemoryBound(to: UInt32.self).advanced(by: Int(i)).pointee)
            }
            
            print(vertexCount1, "aqui2")
            for i in 0..<vertexCount1 {
                print(verticesArrayBuffer.contents().assumingMemoryBound(to: Vertex.self).advanced(by: Int(i)).pointee)
            }
            a = false
        }
        
        
        renderEncoder.setVertexBuffer(verticesArrayBuffer, offset: 0, index: 0)
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: Int(indexCount), indexType: .uint32, indexBuffer: indexArrayBuffer, indexBufferOffset: 0)
        renderEncoder.endEncoding()
        newCommandBuffer.present(drawable)
        newCommandBuffer.commit()
        newCommandBuffer.waitUntilCompleted()
    }
    
    var a = true
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

class GameOfLifeRenderer {
    var gridSize: Int32
    var cellState: [Int32]
    
    private var nextStatePipeline: MTLComputePipelineState?

    init(gridSize: Int32, nextStatePipeline: MTLComputePipelineState) {
        self.gridSize = gridSize
        self.cellState = Array(repeating: 0, count: Int(gridSize * gridSize))
        self.nextStatePipeline = nextStatePipeline
    }
    
    func initializeRandomState() {
        for i in 0..<Int(gridSize * gridSize) {
            cellState[i] = Int32.random(in: 0...1)
        }
    }
    
    func updateCellState(using commandQueue: MTLCommandQueue, device: MTLDevice) {
        guard let nextStatePipeline = nextStatePipeline else {
            fatalError("Next state pipeline not initialized")
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            preconditionFailure("buffer fué")
        }
        
        let stateBuffer = device.makeBuffer(bytes: cellState,
                                            length: cellState.count * MemoryLayout<Int32>.stride)
        let sizeBuffer = device.makeBuffer(bytes: [gridSize],
                                           length: MemoryLayout<Int32>.stride)
        let resultBuffer = device.makeBuffer(length: cellState.count * MemoryLayout<Int32>.stride)
        
        commandEncoder.setComputePipelineState(nextStatePipeline)
        commandEncoder.setBuffer(stateBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(sizeBuffer, offset: 0, index: 1)
        commandEncoder.setBuffer(resultBuffer, offset: 0, index: 2)
        
        let threadsPerGrid = MTLSize(width: Int(gridSize), height: Int(gridSize), depth: 1)
        let maxThreadsPerThreadgroup = nextStatePipeline.maxTotalThreadsPerThreadgroup
        let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1)
        
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        
        if let contents = resultBuffer?.contents().bindMemory(to: Int32.self, capacity: cellState.count) {
            cellState = Array(UnsafeBufferPointer(start: contents, count: cellState.count))
        } else {
            fatalError("Failed to access result buffer contents")
        }
    }
}
