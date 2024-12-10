//
//  BubbleNode.swift
//  ArCar
//
//  Created by mac on 11/28/24.
//


import SceneKit

class BubbleNode: SCNNode {
    static let name = String(describing: BubbleNode.self) // For identification in hit tests

    private let bubbleDepth: CGFloat = 0.1 // Depth of the 3D text
    private let hiddenGeometry = SCNSphere(radius: 0.15) // Invisible geometry for hit-testing

    init(text: String) {
        super.init()

        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y

        // Create 3D Text Bubble
        let bubbleText = SCNText(string: text, extrusionDepth: bubbleDepth)
        bubbleText.font = UIFont(name: "Helvetica", size: 0.15)
        bubbleText.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        bubbleText.firstMaterial?.diffuse.contents = UIColor.orange
        bubbleText.firstMaterial?.specular.contents = UIColor.white
        bubbleText.firstMaterial?.isDoubleSided = true
        bubbleText.chamferRadius = CGFloat(bubbleDepth)

        // Create Bubble Node
        let (minBound, maxBound) = bubbleText.boundingBox
        let bubbleNode = SCNNode(geometry: bubbleText)
        bubbleNode.pivot = SCNMatrix4MakeTranslation((maxBound.x - minBound.x) / 2, minBound.y, Float(bubbleDepth) / 2)
        bubbleNode.scale = SCNVector3(0.2, 0.2, 0.2) // Scale down the text

        // Create Center Sphere (Anchor Point)
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)

        // Add Hidden Geometry for Interaction
        let hiddenNode = SCNNode(geometry: hiddenGeometry)
        hiddenNode.name = Self.name
        hiddenNode.geometry?.materials.first?.transparency = 0

        // Assemble the Node
        addChildNode(bubbleNode) // Text
        addChildNode(sphereNode) // Anchor Sphere
        addChildNode(hiddenNode) // Hidden Geometry
        bubbleNode.constraints = [billboardConstraint]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
