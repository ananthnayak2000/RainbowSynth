//
//  ParticleSystemManager.swift
//  project1
//
//  Created by Jochen Hagenström on 2/22/24.
//


import RealityKit
import RealityKitContent
import Foundation
import SwiftUI

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red: CGFloat(drand48()),
            green: CGFloat(drand48()),
            blue: CGFloat(drand48()),
            alpha: CGFloat(drand48())
        )
    }
    static func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha/255)
    }
}

struct ParticleSystemManager {
    static func setupParticleSystem(_ particleSystem: inout ParticleEmitterComponent) {
        particleSystem.emitterShape = .sphere
        particleSystem.birthLocation = .volume
        particleSystem.birthDirection = .normal
        particleSystem.emitterShapeSize = [10, 10, 10] * Float.random(in: 0.05...0.80)
        
        particleSystem.mainEmitter.birthRate = 300
        particleSystem.burstCount = 2000
        particleSystem.burstCountVariation = 20
        //particles.mainEmitter.BurstCount = 100
        particleSystem.mainEmitter.size = Float.random(in: 0.02...0.8)
        particleSystem.mainEmitter.lifeSpan = 2
        particleSystem.mainEmitter.color = .evolving(start: .single(.orange), end: .single(.blue))
        particleSystem.mainEmitter.spreadingAngle = 1
    }
    
    static func burst(_ particleSystem: inout ParticleEmitterComponent) {
        let randomSeed = 1.0 //Float.random(in: 0.2...2)
        let parameters = generateRandomParameters(randomSeed: Float(randomSeed))
        // original parameters
        particleSystem.mainEmitter.birthRate = parameters["birthRate"] as! Float
        particleSystem.mainEmitter.size = parameters["size"] as! Float
        particleSystem.mainEmitter.lifeSpan = (parameters["lifeSpan"]) as! Double
        let colorStart = parameters["colorStart"] as! [CGFloat]
        let colorEnd = parameters["colorStart"] as! [CGFloat]
        particleSystem.mainEmitter.color = .evolving(
            start: .single(UIColor.rgba(colorStart[0], colorStart[1], colorStart[2], colorStart[3])),
            end: .single(UIColor.rgba(colorEnd[0], colorEnd[1], colorEnd[2], colorEnd[3]))
        )
        
        // experimental params added
        let acceleration = parameters["acceleration"] as! [Float]
        particleSystem.mainEmitter.acceleration = [acceleration[0], acceleration[1], acceleration[2]]
//        setEmitterShape(&particleSystem, parameters)

        // params that are not used to maintain some predictability
        // particleSystem.emitterShapeSize = [Float.random(in: 1...10), Float.random(in: 1...10), Float.random(in: 1...10)] * Float.random(in: 0.1...1.0)
        // particleSystem.burstCount = parameters["burstCount"] as! Int
        // particleSystem.burstCountVariation = parameters["burstCountVariation"] as! Int
        // particleSystem.mainEmitter.spreadingAngle = parameters["spreadingAngle"] as! Float

        print("burst updated with parameters:")
        print(parameters)
    }

    static func generateRandomParameters(randomSeed: Float) -> [String: Any] {
        let parameters: [String: Any] = [
            "randomSeed":  randomSeed,
            "birthRate": Float.random(in: 50.0...600) * randomSeed,
            "size": Float.random(in: 0.01...0.5),
            "lifeSpan": Double.random(in: 0.1...3.0),
            "emitterShape": Int.random(in: 1...7),
            "acceleration": [
                Float.random(in: 0.005...0.05) * randomSeed,
                Float.random(in: 0.005...0.05) * randomSeed,
                Float.random(in: 0.005...0.05) * randomSeed,
            ],
            "colorStart": [
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 100...255),
            ],
            "colorEnd": [
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 100...255),
            ],
//             "emitterShapeSize": [
//                 Float.random(in: 0.8...5) ,
//                 Float.random(in: 0.8...5) ,
//                 Float.random(in: 0.8...5)
//             ],
//             "burstCount": Int.random(in: 1000...3000),
//             "burstCountVariation": Int.random(in: 0...500),
//
//             "spreadingAngle": Float.random(in: 0...2) * randomSeed,
        ]
        return parameters
    }
}
