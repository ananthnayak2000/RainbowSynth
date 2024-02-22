//
//  ImmersiveView.swift
//  project1
//
//  Created by Ananth Nayak on 2/8/24.
//
//This is the particle merge file. particle system 1 - Jochen  particle system 2 - Ananth. Particle system 1 for some reason doesn't change anymore!

import SwiftUI
import RealityKit
import Combine
import AVFoundation

// Audio Player
var player: AVAudioPlayer?

func playSound() {
    guard let path = Bundle.main.path(forResource: "czt", ofType:"mp3") else {
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

// Extension for random UIColor
extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red: CGFloat(drand48()),
            green: CGFloat(drand48()),
            blue: CGFloat(drand48()),
            alpha: CGFloat(drand48())
        )
    }
}

// ViewModel for the first particle system - Jochen
class SequenceViewModel: ObservableObject {
    private var cancellable: AnyCancellable?
    @Published var particleSystem = ParticleEmitterComponent()
    
    func setupParticleSystem() {
        self.particleSystem.emitterShape = .sphere
        self.particleSystem.birthLocation = .volume
        self.particleSystem.birthDirection = .normal
        self.particleSystem.emitterShapeSize = [10, 10, 10] * Float.random(in: 0.05...0.80)
        self.particleSystem.mainEmitter.birthRate = 300
        self.particleSystem.burstCount = 2000
        self.particleSystem.burstCountVariation = 20
        self.particleSystem.mainEmitter.size = Float.random(in: 0.02...0.8)
        self.particleSystem.mainEmitter.lifeSpan = 2
        self.particleSystem.mainEmitter.color = .evolving(start: .single(.orange), end: .single(.blue))
        self.particleSystem.mainEmitter.spreadingAngle = 1
    }
    
    func burst() {
        DispatchQueue.main.async {
            // Create a new particle system with updated properties
                        var newParticleSystem = self.particleSystem
                        newParticleSystem.mainEmitter.color = .evolving(start: .single(UIColor.random()), end: .single(UIColor.random()))
                        newParticleSystem.mainEmitter.birthRate = Float.random(in: 50.0...600)
                        newParticleSystem.mainEmitter.size = Float.random(in: 0.01...0.5)
                        newParticleSystem.mainEmitter.lifeSpan = Double.random(in: 0.1...3.0)

                        // This is to update the view. But I don't think it's working
                        self.particleSystem = newParticleSystem
        }
    }

    func startSequence(times: [Double]) {
        cancellable = Publishers.Sequence(sequence: times)
            .flatMap { number in
                Deferred {
                    Future<Int, Never> { promise in
                        DispatchQueue.main.asyncAfter(deadline: .now() + number) {
                            self.burst()
                            promise(.success(Int(number)))
                        }
                    }
                }.eraseToAnyPublisher()
            }
            .sink(receiveValue: { _ in })
    }

    deinit {
        cancellable?.cancel()
    }
}

// SwiftUI View
struct ImmersiveView: View {
    @StateObject private var sequenceViewModel = SequenceViewModel()
    @State private var currentParticleSize: Float = 0.5
    @State private var currentParticleLifeSpan: Float = 1.0
    @State private var currentParticleSpeed: Float = 0.01
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var sequenceParticleModel = ModelEntity()
    private var timerParticleModel = ModelEntity()

    var body: some View {
        RealityView { content in
            if sequenceParticleModel.components[ParticleEmitterComponent.self] == nil {
                sequenceViewModel.setupParticleSystem()
                sequenceParticleModel.components.set(sequenceViewModel.particleSystem)
                content.add(sequenceParticleModel)
            } else {
                // Apply the updated particle system to the ModelEntity
                sequenceParticleModel.components.set(sequenceViewModel.particleSystem)
            }
            if timerParticleModel.components[ParticleEmitterComponent.self] == nil {
                timerParticleModel.components.set(particleSystem(size: currentParticleSize, lifeSpan: currentParticleLifeSpan, speed: currentParticleSpeed))
                content.add(timerParticleModel)
            }
        }
        .onAppear {
            playSound()
            let times = [2.0, 4.0, 6.0] // Example time intervals for bursts
            sequenceViewModel.startSequence(times: times)
        }
        .onReceive(timer) { _ in
            updateParticleSystem(size: currentParticleSize == 0.5 ? 0.1 : 0.5,
                                 lifeSpan: currentParticleLifeSpan == 1.0 ? 10.0 : 1.0,
                                 speed: currentParticleSpeed == 0.01 ? 1.0 : 0.01)
        }
        .onDisappear() {
            player?.stop()
        }
    }

    // Function for the second particle system
    func particleSystem(size: Float, lifeSpan: Float, speed: Float) -> ParticleEmitterComponent {
        var particles = ParticleEmitterComponent()
        particles.timing = .repeating(warmUp: 0,
                                      emit: ParticleEmitterComponent.Timing.VariableDuration(duration: 1),
                                      idle: ParticleEmitterComponent.Timing.VariableDuration(duration: 10))
        
        particles.emitterShape = .sphere
        particles.birthLocation = .surface
        particles.birthDirection = .normal
        particles.emissionDirection = SIMD3<Float>(x: 0, y: 1, z: 0)
        particles.emitterShapeSize = [0.1, 0.1, 0.1]
        particles.speed = speed
        
        particles.mainEmitter.birthRate = 500
        particles.mainEmitter.size = size
        particles.mainEmitter.lifeSpan = Double(lifeSpan)
        particles.mainEmitter.color = .evolving(start: .single(.orange), end: .single(.blue))
        
        return particles
    }

    // Function to update the second particle system properties
    private func updateParticleSystem(size: Float, lifeSpan: Float, speed: Float) {
        currentParticleSize = size
        currentParticleLifeSpan = lifeSpan
        currentParticleSpeed = speed

        if var particles = timerParticleModel.components[ParticleEmitterComponent.self] as? ParticleEmitterComponent {
            particles.mainEmitter.size = size
            particles.mainEmitter.lifeSpan = Double(lifeSpan)
            particles.speed = speed
            timerParticleModel.components.set(particles)
        }
        print("Updated second particle system with new size, lifespan, and speed")
    }
}

// Preview
#if DEBUG
struct ImmersiveView_Previews: PreviewProvider {
    static var previews: some View {
        ImmersiveView()
            .previewLayout(.sizeThatFits)
    }
}
#endif
