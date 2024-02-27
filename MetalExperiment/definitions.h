//
//  definitions.h
//  MetalExperiment
//
//  Created by Marcos Chevis on 16/02/24.
//

#ifndef definitions_h
#define definitions_h

#include <simd/simd.h>


struct Vertex {
    simd_float2 position;
    simd_float4 color;
};

struct vec_vertex3 {
    struct Vertex vertices[3];
};

struct RegularPolygon {
    simd_float2 center;
    float radius;
    int amountOfSides;
    simd_float4 color;
    int bufferStart;
    
};



#endif /* definitions_h */

