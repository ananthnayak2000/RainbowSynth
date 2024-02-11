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
import AVFoundation
var player: AVAudioPlayer?

func playSound() {
    guard let path = Bundle.main.path(forResource: "czt", ofType:"wav") else {
        return
    }
    let url = URL(fileURLWithPath: path)

    do {
        player = try AVAudioPlayer(contentsOf: url)
        player?.play()
        
    } catch let error {
        print(error.localizedDescription)
    }
}

class SequenceViewModel: ObservableObject {
    private var cancellable: AnyCancellable?
    private let numbers = [5,6,7,8,9,20,20] // Example array of numbers
    private let delaySeconds = 10.0 // Delay in seconds between each number

    @Published var particleSystem = ParticleEmitterComponent()

    // Define a callback variable
    var numberUpdated: ((Int) -> Void)?
    func setupParticleSystem() {
//        self.particleSystem.timing = .repeating(warmUp: 0, emit:ParticleEmitterComponent.Timing.VariableDuration(duration:1), idle: ParticleEmitterComponent.Timing.VariableDuration(duration: 1))
        self.particleSystem.emitterShape = .sphere
        self.particleSystem.birthLocation = .volume
        self.particleSystem.birthDirection = .normal
        self.particleSystem.emitterShapeSize = [10, 10, 10] * 0.05
        
        self.particleSystem.mainEmitter.birthRate = 300
        self.particleSystem.burstCount = 2000
        self.particleSystem.burstCountVariation = 0
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
                    .delay(for: .seconds(number), scheduler: RunLoop.main)
            }
            .sink(receiveValue: { [weak self] number in
                self?.burst()
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
           
            
            viewModel.setupParticleSystem()
            particleModel.components.set(viewModel.particleSystem)
            content.add(particleModel)
            viewModel.startSequence()
        }.onAppear {
            
            playSound()// Setup the callback
        }
    }
    
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
