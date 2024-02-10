//
//  ImmersiveView.swift
//  project1
//
//  Created by Ananth Nayak on 2/8/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            let particleModel = ModelEntity()
            particleModel.components.set(particleSystem())
            content.add(particleModel)
        }
    }
    func particleSystem() -> ParticleEmitterComponent {
        var particles = ParticleEmitterComponent()
        particles.timing = .repeating(warmUp: 0, emit:ParticleEmitterComponent.Timing.VariableDuration(duration:1), idle: ParticleEmitterComponent.Timing.VariableDuration(duration: 1))
        particles.emitterShape = .sphere
        particles.birthLocation = .volume
        particles.birthDirection = .normal
        particles.emitterShapeSize = [10, 10, 10] * 0.05
        
        particles.mainEmitter.birthRate = 300
        //particles.mainEmitter.BurstCount = 100
        particles.mainEmitter.size = 0.02
        particles.mainEmitter.lifeSpan = 5
        particles.mainEmitter.color = .evolving(start: .single(.orange), end: .single(.blue))
        particles.mainEmitter.spreadingAngle = 1
        
        return particles
        
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
