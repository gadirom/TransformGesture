import SwiftUI
import MetalBuilder
import MetalKit
import MetalPerformanceShaders
import FreeTransformGesture

struct Particle: TouchableParticle{
    var coord: simd_float2 = [0, 0]
    var size: Float = 0
    var color: simd_float3 = [0, 0, 0]
}

struct QuadVertex: MetalStruct{
    var coord: simd_float2 = [0, 0]
    var uv: simd_float2 = [0, 0]
}

var uniformsDesc: UniformsDescriptor{
    var desc = UniformsDescriptor()
    DrawCircle.addUniforms(&desc)
    return desc
        .float("size", range: 0...100, value: 100)
        .float("bright", range: 0...5, value: 2.7)
}

let particlesCount = 3000

let textureDesc = TextureDescriptor()
    .fixedSize(.init(width: 1000, height: 1000))
    .pixelFormat(.rgba16Float)

enum DrawMode: String, Equatable, CaseIterable  {
    case texture, particle
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

struct ContentView: View {
    
    var viewSettings: MetalBuilderViewSettings{
        MetalBuilderViewSettings(framebufferOnly: false,
                                 preferredFramesPerSecond: 60)
    }

    var pipColorDesc: MTLRenderPipelineColorAttachmentDescriptor{
        let desc = MTLRenderPipelineColorAttachmentDescriptor()
        desc.isBlendingEnabled = true
        desc.rgbBlendOperation = .add
        desc.alphaBlendOperation = .add
        desc.sourceRGBBlendFactor = .sourceAlpha
        desc.sourceAlphaBlendFactor = .one
        desc.destinationRGBBlendFactor = .one
        desc.destinationAlphaBlendFactor = .one
        return desc
    }
    
    @MetalState var particlesCountState = particlesCount
    
    @Environment(\.scenePhase) var scenePhase
    
    @ObservedObject var transform = TouchTransform(
        translation: CGSize(width: 0,
                            height:0),
        scale: 1,
        rotation: 0,
        scaleRange: 0.1...200,
//        rotationRange: -CGFloat.pi...CGFloat.pi,
//        translationRangeX: -500...500,
//        translationRangeY: -500...500,
        translationXSnapDistance: 10,
        translationYSnapDistance: 10,
        rotationSnapPeriod: .pi/4,
        rotationSnapDistance: .pi/60,
        scaleSnapDistance: 0.1
    )
    
    let hapticsEngine = HapticsEngine()

    @State var drawMode: DrawMode = .texture
    @State var transformActive = false
    
    @MetalState var tapped: CGPoint? = nil
    
    @MetalState var drawCircle = false
    
    @MetalState var justStarted = true
    
    @MetalState var oneParticleIsTouched = false
    
    @MetalState var touchedId = 0
    
    @MetalBuffer<Particle>(count: particlesCount) var particlesBuffer
    
    @MetalBuffer<QuadVertex>(count: 6, metalName: "quadBuffer") var quadBuffer
    
    @MetalTexture(textureDesc) var drawTexture
    
    @MetalState var particleId = 0
    
    @MetalState var dragging = false
    @MetalState var coordTransformed: simd_float2 = [0, 0]
    
    @MetalUniforms(uniformsDesc) var uniforms
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack{
                Rectangle()
                    .fill(Color.indigo)
                    .frame(width: 200, height: 200)
                    .transformEffect(transform)
                MetalBuilderView(viewSettings: viewSettings) { context in
                    EncodeGroup(active: $justStarted){
                        ClearRender()
                            .texture(drawTexture)
                            .color(.black)
                    }
                    CPUCompute{_ in
                        justStarted = false
                        
                        if transform.isTouching{
                            var matrix = transform.matrix
                            matrix = matrix.inverse
                            let coord = transform.floatCurrentTouch
                            let coord1: simd_float3 = [coord.x, coord.y, 1]*matrix
                            coordTransformed = [coord1.x, coord1.y]
                        }
                        
                        
                        if !oneParticleIsTouched &&
                            (transform.isDragging || tapped != nil){
                            var matrix = transform.matrix
                            matrix = matrix.inverse
                            let coord: simd_float2
                            if let tapped = tapped{
                                coord = tapped.simd_float2
                                self.tapped = nil
                            }else{
                                coord = transform.floatCurrentTouch
                            }
                            let coord1: simd_float3 = [coord.x, coord.y, 1]*matrix
                            let r: ClosedRange<Float> = -100...100
                            
                            drawCircle = r.contains(coord1.x) && r.contains(coord1.y) && drawMode == .texture
                            if drawCircle{
                                coordTransformed = [coord1.x, -coord1.y]
                            }else{
                                if r.contains(coord1.x) && r.contains(coord1.y){
                                        spawnParticle(coord: [coord1.x, coord1.y],
                                                      size: uniforms.getFloat("size")!)
                                }
                            }
                        }else{
                            drawCircle = false
                        }
                    }
                   /*EncodeGroup(active: $transform.isTouching){
                        TouchParticle(context: context,
                                      particlesBuffer: particlesBuffer,
                                      touchCoord: $coordTransformed,
                                      particlesCount: $particlesCountState,
                                      touchedId: $touchedId,
                                      isTouched: $oneParticleIsTouched)
                    }
                    CPUCompute{ _ in
                        if !transform.isTouching {
                            oneParticleIsTouched = false
                            return
                        }
                        if oneParticleIsTouched{
                            print("particle touched:", touchedId)
                            particlesBuffer.pointer![touchedId].color = [1,1,1]
                        }
                    }*/
                    Render(type: .point, count: particlesCount)
                        .vertexBuf(particlesBuffer, name: "particles")
                        .vertexBytes($transform.matrix, type: "float3x3", name: "transform")
                        .vertexBytes(context.$viewportToDeviceTransform)
                        .vertexBytes($transform.floatScale, type: "float", name: "scale")
                        .uniforms(uniforms, name: "u")
                        .pipelineColorAttachment(pipColorDesc)
                        .colorAttachement(
                            loadAction: .clear,
                            clearColor: .clear)
                        .vertexShader(VertexShader("vertexShader", vertexOut:"""
                        struct VertexOut{
                            float4 position [[position]];
                            float size [[point_size]];
                            float3 color;
                        };
                        """, body:"""
                          VertexOut out;
                          Particle p = particles[vertex_id];
                          float3 pos = float3(p.coord.xy, 1);
                          pos *= transform;
                    
                          pos *= viewportToDeviceTransform;
                    
                          out.position = float4(pos.xy, 0, 1);
                          out.size = p.size*scale;
                          out.color = p.color*u.bright;
                          return out;
                    """))
                        .fragmentShader(FragmentShader("fragmentShader",
                                                       source:
                    """
                        fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                                       float2 p [[point_coord]]){
                            float mask = smoothstep(.5, .45, length(p-.5));
                            if (mask==0) discard_fragment();
                            return float4((in.color+.5)*pow((0.5-length(p-.5))*2.,.5), mask);
                        }
                    """))
                    EncodeGroup(active: $drawCircle){
                        DrawCircle(context: context,
                                   texture: drawTexture,
                                   touchCoord: $coordTransformed,
                                   uniforms: uniforms)
                    }
                    
                    Render(type: .triangle, count: 6)
                        .vertexBuf(quadBuffer)
                        .fragTexture(drawTexture, argument: .init(type: "float", access: "sample", name: "inTexture"))
                        .vertexBytes($transform.matrix, type: "float3x3", name: "transform")
                        .vertexBytes(context.$viewportToDeviceTransform)
                        //.uniforms(uniforms, name: "u")
                        .pipelineColorAttachment(pipColorDesc)
                        .colorAttachement(
                            loadAction: .load,
                            clearColor: .clear)
                        .vertexShader(VertexShader("quadVertexShader", vertexOut:"""
                        struct QuadVertexOut{
                            float4 position [[position]];
                            float2 uv;
                        };
                        """, body:"""
                          QuadVertexOut out;
                          QuadVertex p = quadBuffer[vertex_id];
                          float3 pos = float3(p.coord.xy, 1);
                          pos *= transform;
                          pos *= viewportToDeviceTransform;
                    
                          out.position = float4(pos.xy, 0, 1);
                          out.uv = p.uv;
                          return out;
                    """))
                        .fragmentShader(FragmentShader("quadFragmentShader",
                                                       returns: "float4",
                                                       body:
                    """
                        constexpr sampler s(address::clamp_to_border, filter::linear,  border_color::opaque_white);
                        float mask = inTexture.sample(s, in.uv).r;
                        return float4(float3(1), 0.5*mask);
                    """))
                        
                }
                .onResize{ size in
                    createQuad()
                }
                .freeTransformGesture(transform: transform,
                                      transformMode: .auto,
                                      active: true){
                    tapped = $0
                }
                if transform.isTouching{
                    Circle()
                        .stroke(transform.isDragging ? Color.white : Color.gray)
                        .frame(width: 100, height: 100)
                        .position(transform.firstTouch)
                        .offset(transform.offset)
                }
                if transform.isTransforming{
                    Rectangle()
                        .fill(Color.clear)
                        .border(Color.white, width: transform.scaleSnapped ? 2 : 1)
                        .frame(width: 200, height: 200)
                        .transformEffect(transform)
                    let offset = CGSize(width: transform.centerPoint.x,
                                        height: transform.centerPoint.y)
                    ZStack{
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 1)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 1)
                    }
                    //.opacity(0.5)
                    .frame(width: 20, height: 20)
                    .rotationEffect(Angle(radians: transform.rotation))
                    .offset(offset)
                    if transform.translationXSnapped{
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 0.5)
                    }
                    if transform.translationYSnapped{
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 0.5)
                    }
                }
            }
            .onChange(of: transform.translationXSnapped) { newValue in
                hapticsEngine.onSnap()
            }
            .onChange(of: transform.translationYSnapped) { newValue in
                hapticsEngine.onSnap()
            }
            .onChange(of: transform.rotationSnapped) { newValue in
                hapticsEngine.onSnap()
            }
            .onChange(of: transform.scaleSnapped) { newValue in
                hapticsEngine.onSnap()
            }
            .onChange(of: scenePhase) { newValue in
                if newValue == .active{
                    hapticsEngine.start()
                }
            }
            VStack{
                HStack{
                    Picker("", selection: $drawMode) {
                        ForEach(DrawMode.allCases, id: \.self) { value in
                            Text(value.localizedName)
                                .tag(value)
                        }
                    }.pickerStyle(.segmented)
                    Button {
                        clearCanvas()
                        justStarted = true
                    } label: {
                        Text("clear")
                    }

                }
                UniformsView(uniforms)
                    .frame(height: 120)
            }
            .padding([.top, .bottom])
            .background(Color.black)
        }
    }
    func createQuad(){
        let p = quadBuffer.pointer!
        p[0] = .init(coord: [-100, -100], uv: [0,0])
        p[1] = .init(coord: [100, -100], uv: [1,0])
        p[2] = .init(coord: [100, 100], uv: [1,1])
        
        p[3] = .init(coord: [-100, 100], uv: [0,1])
        p[4] = .init(coord: [-100, -100], uv: [0,0])
        p[5] = .init(coord: [100, 100], uv: [1,1])
    }
    func clearCanvas(){
        particleId = 0
        for _ in 0..<particlesCount{
            spawnParticle(coord: [1000, 1000],
                          size: 0
            )
        }
    }
    func spawnParticle(coord: simd_float2, size: Float? = nil){
        let size = size ?? Float.random(in: 0.03...0.05)
        let color = simd_float3.random(in: 0.1...0.2)
        let p = Particle(coord: [coord.x, coord.y],
                         size: size,
                         color: color)
        particlesBuffer.pointer![particleId] = p
        particleId = (particleId+1) % particlesCount
    }
}
