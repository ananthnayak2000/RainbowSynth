//
//  ImmersiveView.swift
//  project1
//
//  Created by Ananth Nayak on 2/8/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Combine

class SequenceViewModel: ObservableObject {
    private var cancellable: AnyCancellable?
    private let numbers = [1, 2, 3, 4, 5, 9] // Example array of numbers
    private let delaySeconds = 10.0 // Delay in seconds between each number

    @Published var particleSystem = ParticleEmitterComponent()

    // Define a callback variable
    var numberUpdated: ((Int) -> Void)?
    func setupParticleSystem() {
        self.particleSystem.timing = .repeating(warmUp: 0, emit:ParticleEmitterComponent.Timing.VariableDuration(duration:1), idle: ParticleEmitterComponent.Timing.VariableDuration(duration: 1))
        self.particleSystem.emitterShape = .sphere
        self.particleSystem.birthLocation = .volume
        self.particleSystem.birthDirection = .normal
        self.particleSystem.emitterShapeSize = [10, 10, 10] * 0.05
        
        self.particleSystem.mainEmitter.birthRate = 300
        self.particleSystem.burstCount = 300
        //particles.mainEmitter.BurstCount = 100
        self.particleSystem.mainEmitter.size = 0.02
        self.particleSystem.mainEmitter.lifeSpan = 5
        self.particleSystem.mainEmitter.color = .evolving(start: .single(.orange), end: .single(.blue))
        self.particleSystem.mainEmitter.spreadingAngle = 1
        
        
    }
    
    func burst(){
        self.particleSystem.burst()
        print("bursted")
    }
    func startSequence() {
        cancellable = Publishers.Sequence(sequence: numbers)
            .flatMap { number in
                Just(number)
                    .delay(for: .seconds(self.delaySeconds), scheduler: RunLoop.main)
            }
            .sink(receiveValue: { [weak self] number in
                // Instead of setting a published property, call the callback with the current number
                self?.numberUpdated?(number)
                print("Current number: \(number)")
            })
    }

    deinit {
        cancellable?.cancel()
    }
}
struct ImmersiveView: View {
    @StateObject private var viewModel = SequenceViewModel()

    var body: some View {
        RealityView { content in
            let particleModel = ModelEntity()
           
            
            particleModel.components.set(viewModel.particleSystem)
            content.add(particleModel)
            viewModel.startSequence()
        }.onAppear {
            // Setup the callback
            viewModel.setupParticleSystem()
            viewModel.numberUpdated = { number in
                viewModel.burst()            }
        }
    }
    
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
