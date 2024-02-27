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
    vector_float2 position;
    vector_float4 color;
};

struct vec_vertex3 {
    struct Vertex vertices[3];
};

struct RegularPolygon {
    vector_float2 center;
    float radius;
    int amountOfSides;
    vector_float4 color;
    int64_t bufferStart;
    
};



#endif /* definitions_h */

