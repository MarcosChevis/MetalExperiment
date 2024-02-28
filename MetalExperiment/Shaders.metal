//
//  Shaders.metal
//  MetalExperiment
//
//  Created by Marcos Chevis on 16/02/24.
//

#include <metal_stdlib>
#include <metal_math>
using namespace metal;

#include "definitions.h"

struct Fragment {
    simd_float4 position [[position]];
    simd_float4 color;
};

vertex Fragment vertexShader(const device Vertex *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    Vertex input = vertexArray[vid];
    
    Fragment output;
    //x,y,z,w
    output.position = float4(input.position.x, input.position.y, 0, 1);
    output.color = input.color;
    
    return output;
}

fragment float4 fragmentShader(Fragment input [[stage_in]]) {
    return input.color;
}


kernel void triangulateRegularPoly(constant RegularPolygon *polygonsArr [[buffer(0)]],
                                   device Vertex *resultArr [[buffer(1)]],
                                   uint index [[thread_position_in_grid]]) {
    
    float deltaAngle = 2.0 * M_PI_F / polygonsArr[index].amountOfSides;
    float currentAngle = polygonsArr[index].rotationAngle; // Use rotation angle from RegularPolygon
    
    simd_float2 center = polygonsArr[index].center;
    float radius = polygonsArr[index].radius;
    simd_float4 color = polygonsArr[index].color;
    
    for (int i = 0; i < polygonsArr[index].amountOfSides; ++i) {
        simd_float2 currentPoint = vector_float2(radius * cos(currentAngle), radius * sin(currentAngle)) + center;
        simd_float2 nextPoint = vector_float2(radius * cos(currentAngle + deltaAngle), radius * sin(currentAngle + deltaAngle)) + center;
        
        Vertex v1, v2, v3;
        v1.position = currentPoint;
        v2.position = center;
        v3.position = nextPoint;
        
        v1.color = v2.color = v3.color = color;
        
        int startIndex = polygonsArr[index].bufferStart + (i * 3);
        resultArr[startIndex] = v1;
        resultArr[startIndex + 1] = v2;
        resultArr[startIndex + 2] = v3;
        
        currentAngle += deltaAngle;
    }
}


kernel void getNextState(constant int *state [[buffer(0)]],
                         constant int *size [[buffer(1)]],
                         device int *newState [[buffer((2))]],
                         uint2 index [[thread_position_in_grid]]) {
    
    const int gridSize = size[0];
       
       int aliveNeighbors = 0;
       
       for (int x = -1; x <= 1; x++) {
           for (int y = -1; y <= 1; y++) {
               if (!(x == 0 && y == 0)) {
                   int newRow = (int(index.x) + x + gridSize) % gridSize;
                   int newCol = (int(index.y) + y + gridSize) % gridSize;
                   aliveNeighbors += state[newRow * gridSize + newCol];
               }
           }
       }
       
       int currentState = state[int(index.x) * gridSize + int(index.y)];
       
       if (currentState == 1) {
           newState[int(index.x) * gridSize + int(index.y)] = (aliveNeighbors == 2 || aliveNeighbors == 3) ? 1 : 0;
       } else {
           newState[int(index.x) * gridSize + int(index.y)] = (aliveNeighbors == 3) ? 1 : 0;
       }
    
}
