import UIKit
import ARKit
import Vision

class ARSCNViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate, SCNSceneRendererDelegate {
    var wheelDetectionService = WheelDetectionService()
    var isLoopShouldContinue = true
    var lastBoundingBoxes: [CGRect] = []
    var sceneView: ARSCNView!
    var usdzFilePath: String?
    var existingWheelNodes: [UUID: SCNNode] = [:] // Track nodes by UUID for persistent matching
    private var debugLabel: UILabel!
    private var selectedNode: SCNNode?
    var isWheelOnePlaced = false
    var isWheelTwoPlaced = false
    var lastLocation: SCNVector3?
    var occlusionNodeCache: [UUID: SCNNode] = [:] // Cache for occlusion nodes

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize and set up the scene view
        setupSceneView()
        setupDebugLabel()
        
        guard let sceneView = sceneView else {
            fatalError("sceneView is not initialized!")
        }
        
        // Configure sceneView properties
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.rendersCameraGrain = true
        sceneView.rendersMotionBlur = true
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = UIScreen.main.scale
        sceneView.scene = SCNScene()

        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin, .showPhysicsFields]

        checkUSDZFileSupportsOcclusion()

        // Start detection loop
        loopWheelDetection()
        
        // Add gesture recognizer for double-tap
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
    }

    func createOcclusionNode(from meshAnchor: ARMeshAnchor) -> SCNNode? {
        // Check cache first
        if let cachedNode = occlusionNodeCache[meshAnchor.identifier] {
            return cachedNode
        }

        // Create geometry from the mesh anchor
        guard let geometry = createMeshGeometry(from: meshAnchor) else {
            print("Error: Could not create geometry from mesh anchor.")
            return nil
        }

        // Create occlusion node
        let occlusionNode = SCNNode(geometry: geometry)
        applyOcclusionMaterial(to: occlusionNode) // Apply depth-only material

        // Cache and return
        occlusionNodeCache[meshAnchor.identifier] = occlusionNode
        return occlusionNode
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let meshAnchor = anchor as? ARMeshAnchor {
            if let occlusionNode = createOcclusionNode(from: meshAnchor) {
                node.addChildNode(occlusionNode)
            } else {
                print("Failed to create occlusion node.")
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let meshAnchor = anchor as? ARMeshAnchor {
            node.childNodes.forEach { $0.removeFromParentNode() } // Remove old geometry
            if let occlusionNode = createOcclusionNode(from: meshAnchor) {
                node.addChildNode(occlusionNode)
            } else {
                print("Failed to update occlusion node for mesh anchor.")
            }
        }
    }

    func applyOcclusionMaterial(to modelNode: SCNNode) {
        guard let geometry = modelNode.geometry else { return }
        let occlusionMaterial = SCNMaterial()
        // Depth-only material for environment mesh
        occlusionMaterial.colorBufferWriteMask = []
        occlusionMaterial.writesToDepthBuffer = true
        occlusionMaterial.readsFromDepthBuffer = true
        occlusionMaterial.isDoubleSided = true
        geometry.materials = [occlusionMaterial]
    }

    func createMeshGeometry(from meshAnchor: ARMeshAnchor) -> SCNGeometry? {
        let vertices = meshAnchor.geometry.vertices
        let normals = meshAnchor.geometry.normals
        let faces = meshAnchor.geometry.faces

        // Validate buffers
        guard vertices.count > 0, normals.count > 0, faces.count > 0 else {
            print("Error: One or more buffers are empty. Vertices: \(vertices.count), Normals: \(normals.count), Faces: \(faces.count)")
            return nil
        }

        // Ensure buffer size is valid for vertices
        let expectedVertexBufferSize = vertices.count * MemoryLayout<simd_float3>.stride
        if vertices.buffer.length < expectedVertexBufferSize {
            print("Error: Vertex buffer size mismatch.")
            return nil
        }

        // Access vertex buffer safely
        let vertexBuffer = vertices.buffer.contents()
        let vertexPointer = vertexBuffer.assumingMemoryBound(to: simd_float3.self)
        let vertexCount = vertices.count
        var vertexArray: [SCNVector3] = []
        for i in 0..<vertexCount {
            let vertex = vertexPointer[i]
            vertexArray.append(SCNVector3(vertex.x, vertex.y, vertex.z))
        }

        // Access normal buffer safely
        let normalBuffer = normals.buffer.contents()
        let normalPointer = normalBuffer.assumingMemoryBound(to: simd_float3.self)
        var normalArray: [SCNVector3] = []
        for i in 0..<vertexCount {
            let normal = normalPointer[i]
            normalArray.append(SCNVector3(normal.x, normal.y, normal.z))
        }

        // Validate face buffer size
        let expectedFaceBufferSize = faces.count * MemoryLayout<UInt32>.stride * 3
        if faces.buffer.length < expectedFaceBufferSize {
            print("Error: Face buffer size mismatch.")
            return nil
        }

        // Access face buffer safely
        let faceBuffer = faces.buffer.contents()
        let facePointer = faceBuffer.assumingMemoryBound(to: UInt32.self)
        let faceCount = faces.count
        var faceArray: [UInt32] = []
        for i in 0..<faceCount * 3 {
            faceArray.append(facePointer[i])
        }

        guard faceArray.count > 0 else {
            print("Error: No valid face data found.")
            return nil
        }

        let vertexSource = SCNGeometrySource(vertices: vertexArray)
        let normalSource = SCNGeometrySource(normals: normalArray)
        let faceData = Data(bytes: faceArray, count: faceArray.count * MemoryLayout<UInt32>.size)

        let faceElement = SCNGeometryElement(
            data: faceData,
            primitiveType: .triangles,
            primitiveCount: faceCount,
            bytesPerIndex: MemoryLayout<UInt32>.size
        )

        return SCNGeometry(sources: [vertexSource, normalSource], elements: [faceElement])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopARSession()
    }

    private func setupSceneView() {
        sceneView = ARSCNView()
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupDebugLabel() {
        debugLabel = UILabel()
        debugLabel.translatesAutoresizingMaskIntoConstraints = false
        debugLabel.textColor = .white
        debugLabel.numberOfLines = 0
        debugLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        debugLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        debugLabel.layer.cornerRadius = 5
        debugLabel.layer.masksToBounds = true
        debugLabel.textAlignment = .center
        debugLabel.text = "Debug Info"
        view.addSubview(debugLabel)
        NSLayoutConstraint.activate([
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            debugLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            debugLabel.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic

        // Enable depth-based occlusion
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }

        // Enable mesh reconstruction
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    private func stopARSession() {
        sceneView.session.pause()
    }

    func loopWheelDetection() {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self, self.isLoopShouldContinue else { return }
            self.performWheelDetection()
            self.loopWheelDetection()
        }
    }

    func performWheelDetection() {
        guard let pixelBuffer = sceneView.session.currentFrame?.capturedImage else {
            updateDebugLabel(with: "No frame available for detection.")
            return
        }

        wheelDetectionService.detect(on: .init(pixelBuffer: pixelBuffer)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let responses):
                let boundingBoxes = responses.map { $0.boundingBox }
                self.handleDetection(boundingBoxes)
            case .failure(let error):
                self.updateDebugLabel(with: "Wheel detection failed: \(error)")
            }
        }
    }

    func calculateScaleFactor(for boundingBox: CGRect, modelNode: SCNNode) -> Float {
        let realWorldWidth = calculateRealWorldWidth(from: boundingBox)
        let modelWidth = modelNode.boundingBox.max.x - modelNode.boundingBox.min.x
        return realWorldWidth / modelWidth
    }

    func calculateRealWorldWidth(from boundingBox: CGRect) -> Float {
        let leftPoint = CGPoint(x: boundingBox.minX * sceneView.bounds.width, y: boundingBox.midY * sceneView.bounds.height)
        let rightPoint = CGPoint(x: boundingBox.maxX * sceneView.bounds.width, y: boundingBox.midY * sceneView.bounds.height)

        guard let leftRaycast = performRaycast(for: leftPoint),
              let rightRaycast = performRaycast(for: rightPoint) else {
            return 0.6 // Fallback to typical wheel size in meters
        }

        let realWorldDistance = (rightRaycast - leftRaycast).length()
        return max(realWorldDistance, 0.6)
    }

    func debugScaleInfo(realWorldWidth: Float, modelWidth: Float, scaleFactor: Float) {
        print("Real-World Width: \(realWorldWidth)m")
        print("Model Width: \(modelWidth)m")
        print("Calculated Scale Factor: \(scaleFactor)")
    }

    func smoothUpdateUSDZModel(at position: SCNVector3, withBoundingBox boundingBox: CGRect, existingNode: SCNNode) {
        let scaleFactor = calculateScaleFactor(for: boundingBox, modelNode: existingNode)
        print("ScaleFactor when updating Width: \(scaleFactor)m")
        let scaleAction = SCNAction.scale(to: CGFloat(scaleFactor), duration: 0.5)
        let moveAction = SCNAction.move(to: position, duration: 0.5)
        let groupAction = SCNAction.group([scaleAction, moveAction])
        existingNode.runAction(groupAction)
    }

    func placeUSDZModelWithAnchor(at position: SCNVector3, withBoundingBox boundingBox: CGRect, uuid: UUID) {
        guard let usdzFilePath = usdzFilePath else { return }
        let fileName = (usdzFilePath as NSString).lastPathComponent.replacingOccurrences(of: ".usdz", with: "")
        guard let usdzURL = Bundle.main.url(forResource: fileName, withExtension: "usdz") else { return }

        do {
            let modelScene = try SCNScene(url: usdzURL, options: nil)
            guard let modelNode = modelScene.rootNode.childNodes.first else { return }

            // Apply a normal visible material to the wheel model
            let material = SCNMaterial()
            material.readsFromDepthBuffer = false
            material.writesToDepthBuffer = true
            modelNode.geometry?.materials = [material]

            // Ensure the wheel is rendered on top of occlusion
            modelNode.renderingOrder = 2000

            // Calculate and apply scale
            let scaleFactor = calculateScaleFactor(for: boundingBox, modelNode: modelNode)
            modelNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)

            // Set up AR anchor directly at the raycast position (no offset)
            let anchorTransform = simd_float4x4(SCNMatrix4MakeTranslation(position.x, position.y, position.z))
            let anchor = ARAnchor(name: uuid.uuidString, transform: anchorTransform)
            sceneView.session.add(anchor: anchor)

            // Attach to anchor node
            let anchorNode = SCNNode()
            anchorNode.simdTransform = anchor.transform
            anchorNode.name = uuid.uuidString
            modelNode.position = SCNVector3(0, 0, 0)
            anchorNode.addChildNode(modelNode)

            // Add to scene
            existingWheelNodes[uuid] = anchorNode
            sceneView.scene.rootNode.addChildNode(anchorNode)

        } catch {
            print("Error loading USDZ model: \(error)")
        }
    }

    func handleDetection(_ boundingBoxes: [CGRect]) {
        DispatchQueue.main.async { [self] in
            let sortedBoxes = boundingBoxes.sorted { $0.width * $0.height > $1.width * $1.height }
            let boxesToPlace = sortedBoxes.prefix(2)

            if boxesToPlace.isEmpty { return }

            for (index, boundingBox) in boxesToPlace.enumerated() {
                let point = CGPoint(x: boundingBox.midX * self.sceneView.bounds.width,
                                    y: (1 - boundingBox.midY) * self.sceneView.bounds.height)

                if let position = performRaycast(for: point) {
                    let uuid: UUID
                    if index == 0 {
                        uuid = UUID(uuidString: "wheel_one") ?? UUID()
                        if let existingNode = existingWheelNodes[uuid] {
                            smoothUpdateUSDZModel(at: position, withBoundingBox: boundingBox, existingNode: existingNode)
                        } else if !isWheelOnePlaced {
                            placeUSDZModelWithAnchor(at: position, withBoundingBox: boundingBox, uuid: uuid)
                            isWheelOnePlaced = true
                        }
                    } else if index == 1 {
                        uuid = UUID(uuidString: "wheel_two") ?? UUID()
                        if let existingNode = existingWheelNodes[uuid] {
                            smoothUpdateUSDZModel(at: position, withBoundingBox: boundingBox, existingNode: existingNode)
                        } else if !isWheelTwoPlaced {
                            placeUSDZModelWithAnchor(at: position, withBoundingBox: boundingBox, uuid: uuid)
                            isWheelTwoPlaced = true
                        }
                    }
                }
            }
        }
    }

    func performRaycast(for point: CGPoint) -> SCNVector3? {
        guard let raycastQuery = sceneView.raycastQuery(from: point, allowing: .existingPlaneGeometry, alignment: .any),
              let result = sceneView.session.raycast(raycastQuery).first else {
            updateDebugLabel(with: "Raycast failed for point: \(point)")
            return nil
        }

        return SCNVector3(result.worldTransform.columns.3.x,
                          result.worldTransform.columns.3.y,
                          result.worldTransform.columns.3.z)
    }

    func updateDebugLabel(with text: String) {
        DispatchQueue.main.async {
            self.debugLabel.text = text
        }
    }

    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        for (_, node) in existingWheelNodes {
            node.removeFromParentNode()
        }
        existingWheelNodes.removeAll()
        isWheelOnePlaced = false
        isWheelTwoPlaced = false
        loopWheelDetection()
    }
    
    func checkUSDZFileSupportsOcclusion() {
        guard let usdzFilePath = usdzFilePath else { return }
        let fileName = (usdzFilePath as NSString).lastPathComponent.replacingOccurrences(of: ".usdz", with: "")
        guard let usdzURL = Bundle.main.url(forResource: fileName, withExtension: "usdz") else { return }

        do {
            let modelScene = try SCNScene(url: usdzURL, options: nil)
            print("USDZ file loaded successfully.")

            func checkNode(_ node: SCNNode) {
                if let geometry = node.geometry {
                    print("Geometry found in node: \(node.name ?? "Unnamed Node")")
                    print("Vertex count: \(geometry.sources.first(where: { $0.semantic == .vertex })?.vectorCount ?? 0)")
                    print("Geometry element count: \(geometry.elements.count)")
                }
                for child in node.childNodes {
                    checkNode(child)
                }
            }

            checkNode(modelScene.rootNode)

        } catch {
            print("Error loading USDZ file: \(error)")
        }
    }
}

extension SCNVector3 {
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }

    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }

    func length() -> Float {
        return sqrt(x * x + y * y + z * z)
    }

    func withYOffset(_ offset: Float) -> SCNVector3 {
        return SCNVector3(x, y + offset, z)
    }
}
