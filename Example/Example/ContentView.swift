import SwiftUI
import MetalBuilder
import MetalKit
import MetalPerformanceShaders
import FreeTransformGesture

struct Particle: TouchableParticle, RenderableParticle{
    var coord: simd_float2 = [0, 0]
    var size: Float = 0
    var color: simd_float3 = [0, 0, 0]
}

struct QuadVertex: MetalStruct{
    var coord: simd_float2 = [0, 0]
    var uv: simd_float2 = [0, 0]
}

let particlesCount = 3000

var uniformsDesc: UniformsDescriptor{
    UniformsDescriptor()
        .float("size", range: 0...5, value: 5)
}

//Canvas size
var canvasSize: simd_float2 = [200, 300]
//Canvas edge coords
var canvasD: simd_float2{
    canvasSize/2
}

var canvasTextureScaleFactor: Float = 5

let textureDesc = TextureDescriptor()
    .fixedSize(.init(width: Int(canvasSize.x*canvasTextureScaleFactor),
                     height: Int(canvasSize.y*canvasTextureScaleFactor)))
    .pixelFormat(.rgba16Float)

enum DrawMode: String, Equatable, CaseIterable  {
    case texture, particle, edit
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

struct ContentView: View {
    
    let touchDelegate = MyTouchDelegate()
    
    var viewSettings: MetalBuilderViewSettings{
        MetalBuilderViewSettings(framebufferOnly: false,
                                 preferredFramesPerSecond: 60)
    }
    
    @MetalState var particlesCountState = particlesCount
    @MetalState var canvasSizeState = canvasSize
    
    @ObservedObject var transform = TouchTransform(
        translation: CGSize(width: 0,
                            height:0),
        scale: 1,
        rotation: 0,
        scaleRange: 0.1...20,
//        rotationRange: -CGFloat.pi...CGFloat.pi,
//        translationRangeX: -500...500,
//        translationRangeY: -500...500,
        translationXSnapDistance: 10,
        translationYSnapDistance: 10,
        rotationSnapPeriod: .pi/4,
        rotationSnapDistance: .pi/60,
        scaleSnapDistance: 0.1
    )

    @State var drawMode: DrawMode = .texture
    @State var transformActive = false
    
    @State var disableDragging = false
    @State var disableTransform = false
    
    @MetalState var tapped: CGPoint? = nil
    
    @MetalState var drawCircle = false
    
    @MetalState var justStarted = true
    
    @MetalState var oneParticleIsTouched = false
    
    @MetalState var touchedId = 0
    @MetalState var testTouch = false
    
    @MetalBuffer<Particle>(count: particlesCount) var particlesBuffer
    
    @MetalTexture(textureDesc) var drawTexture
    
    @MetalState var particleId = 0
    
    @MetalState var dragging = false
    @MetalState var coordTransformed: simd_float2 = [0, 0]
    @MetalState var drawingCircleSize: Float = 0
    @State var circleSize: CGFloat = 0
    
    @MetalState var touchedParticleInitialCoords: simd_float2 = [0, 0]
    
    @MetalUniforms(uniformsDesc) var uniforms
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack{
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: CGFloat(canvasSize.x), height: CGFloat(canvasSize.y))
                    .transformEffect(transform)
                MetalBuilderView(viewSettings: viewSettings) { context in
                    EncodeGroup(active: $justStarted){
                        ClearRender()
                            .texture(drawTexture)
                            .color(MTLClearColor())
                    }
                    CPUCompute{ device in
                        if justStarted{
                            uniforms.setup(device: device)
                            justStarted = false
                        }
                        
                        var coord: simd_float2
                        //prepare to check if a particle is touched
                        if transform.isTouching &&
                            !transform.isDragging &&
                            !dragging &&
                            !transform.isTransforming {
                            
                            testTouch = true
                            coord = transform.floatFirstTouch
                            
                            //print("firstTouch")
                        }else{
                            testTouch = false
                            coord = transform.floatCurrentTouch
                        }
                        
                        if let tapped = tapped{
                            coord = tapped.simd_float2
                        }
                        
                        //prepare transformed coordinates
                        let coord1: simd_float3 = [coord.x, coord.y, 1]*transform.matrixInveresed
                        let rx: ClosedRange<Float> = -canvasD.x...canvasD.x
                        let ry: ClosedRange<Float> = -canvasD.y...canvasD.y
                        
                        let coordInside = rx.contains(coord1.x) && ry.contains(coord1.y)
                        guard coordInside else {
                            return
                        }
                        coordTransformed = [coord1.x, coord1.y]
                        
                        //prepare to draw
                        if !oneParticleIsTouched &&
                            (transform.isDragging || tapped != nil){
                            
                            switch drawMode {
                            case .texture:
                                drawingCircleSize = uniforms.getFloat("size")! * canvasTextureScaleFactor
                                drawCircle = true
                            case .particle:
                                spawnParticle(coord: [coord1.x, coord1.y],
                                              size: uniforms.getFloat("size")!)
                            case .edit: break
                            }
                        }else{
                            drawCircle = false
                        }
                        
                        self.tapped = nil
                    }
                   EncodeGroup(active: $testTouch){
                        TouchParticle(context: context,
                                      particlesBuffer: particlesBuffer,
                                      touchCoord: $coordTransformed,
                                      particlesCount: $particlesCountState,
                                      touchedId: $touchedId,
                                      isTouched: $oneParticleIsTouched)
                    }
                    CPUCompute{ _ in
                        if !transform.isTouching || drawCircle{
                            oneParticleIsTouched = false
                            dragging = false
                            if drawMode == .edit{
                                disableDragging = true
                            }
                            return
                        }
                        if oneParticleIsTouched{
                            if drawMode == .edit{
                                disableDragging = false
                            }
                            circleSize = CGFloat(particlesBuffer.pointer![touchedId].size)
                            if dragging{
                                let o = transform.floatCurrentTouch
                                let o1 = [o.x, o.y, 1]*transform.matrixInveresed
                                particlesBuffer.pointer![touchedId].coord = [o1.x, o1.y]
                                //print("offset:", o1)
                            }else{
                                touchedParticleInitialCoords = particlesBuffer.pointer![touchedId].coord
                                dragging = true
                                testTouch = false
                            }
                            
                        }else{
                            circleSize = CGFloat(uniforms.getFloat("size")!)
                        }
                    }
                    RenderParticles(context: context,
                                    particlesBuffer: particlesBuffer,
                                    transform: transform)
                    EncodeGroup(active: $drawCircle){
                        DrawCircle(context: context,
                                   texture: drawTexture,
                                   touchCoord: $coordTransformed,
                                   circleSize: $drawingCircleSize,
                                   canvasSize: $canvasSizeState)
                    }
                    
                    QuadRenderer(context: context,
                                 toTexture: nil,
                                 sampleTexture: drawTexture,
                                 transformMatrix: $transform.matrix)
                        
                }
                .freeTransformGesture(transform: transform,
                                      draggingDisabled: disableDragging,
                                      transformDisabled: disableTransform,
                                      touchDelegate: touchDelegate,
                                      active: true){
                    if !oneParticleIsTouched && drawMode != .edit{
                        tapped = $0
                    }
                }
                if transform.isTouching && drawMode != .edit && !disableDragging{
                    Circle()
                        .stroke(transform.isDragging ? Color.white : Color.gray)
                        .frame(width: transform.scale*circleSize)
                        .position(transform.firstTouch)
                        .offset(transform.offset)
                }
                if transform.isTransforming{
                    Rectangle()
                        .fill(Color.clear)
                        .border(Color.white, width: transform.scaleSnapped ? 2 : 1)
                        .frame(width: CGFloat(canvasSize.x), height: CGFloat(canvasSize.y))
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
            .hapticsEffects(transform)
            VStack{
                HStack{
                    Picker("", selection: $drawMode) {
                        ForEach(DrawMode.allCases, id: \.self) { value in
                            Text(value.localizedName)
                                .tag(value)
                        }
                    }.pickerStyle(.segmented)
                        .onChange(of: drawMode) { newValue in
                            if newValue != .edit{
                                disableDragging = false
                            }
                        }
                    Button {
                        clearCanvas()
                        justStarted = true
                    } label: {
                        Text("clear")
                    }
                    Button {
                        transform.reset()
                    } label: {
                        Text("reset")
                    }

                }
                UniformsView(uniforms)
                    .frame(height: 120)
                Toggle("Dragging/Drawing Disabled:", isOn: $disableDragging)
                    .disabled(true)
                Toggle("Disable Transforming:", isOn: $disableTransform)
            }
            .padding([.top, .bottom])
            .background(Color.black)
        }
    }

    func checkForPoint(point: CGPoint) -> Bool{
        true
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
        //print(coord)
        let size = size ?? Float.random(in: 0.03...0.05)
        let color = simd_float3.random(in: 0.1...1)
        let p = Particle(coord: [coord.x, coord.y],
                         size: size,
                         color: color)
        particlesBuffer.pointer![particleId] = p
        particleId = (particleId+1) % particlesCount
    }
}
