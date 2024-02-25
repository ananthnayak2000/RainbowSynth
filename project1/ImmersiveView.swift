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

// ViewModel for the first particle system - Jochen
class SequenceViewModel: ObservableObject {
    // This is triggered from startSequence
    var sequenceAction: ((Int) -> Void)?
    private var cancellable: AnyCancellable?
    var color: UIColor
    @Published var particleSystem = ParticleEmitterComponent()
    
    init(color: UIColor) {
        self.color = color
        particleSystem = ParticleEmitterComponent()
        ParticleSystemManager.setupParticleSystem(&particleSystem, color: color)
    }
    
    func burst() {
        ParticleSystemManager.burst(&self.particleSystem)
    }
    // The `startSequence` function takes an array of time intervals and creates a sequence of actions.
    // Each action is delayed by the corresponding time interval in the input array.
    // When each time interval elapses, the `burst` function is called to trigger a color update to the particles in the particle system.
    func startSequence(times : [Double]) {
        cancellable = Publishers.Sequence(sequence: times)
        // flatMap is used to transform the elements emitted by an upstream publisher into a new publisher. The new publishers are then merged into a single publisher.
            .flatMap { number in
                // Deferred waits until it receives a subscriber before it creates its upstream publisher.
                // Deferred is used to create a new Future publisher each time a value is emitted by the Publishers.Sequence publisher.
                Deferred {
                    // The Future publisher emits a single value after a delay.
                    // By using Deferred, the Future publisher and the delay are not created until a subscriber is attached. This ensures that the delay starts at the time of subscription,
                    // not at the time of creation of the Future publisher.
                    // The Future initializer takes a closure that takes a Promise as its parameter.
                    Future<Int, Never> { promise in
                        // The DispatchQueue.main.asyncAfter function is a part of Grand Central Dispatch (GCD) in Swift.
                        // This function schedules a block of code to be executed on the main queue after a certain period of time.
                        // The deadline: .now() + number parameter specifies when the block of code should be executed. .now() + number calculates a date that is number seconds from now.
                        DispatchQueue.main.asyncAfter(deadline: .now() + number) {
                            promise(.success(Int(number)))
                        }
                    }
                }
                // It's used to erase the type of a publisher and return it as an AnyPublisher instance.
                // In Combine, publishers are often chained together, with each operator in the chain potentially
                // changing the publisher's output type, failure type, or both. This can lead to complex, hard-to-read type signatures.
                // The eraseToAnyPublisher method erases all type information about the publisher's output type and failure type, and returns an
                // AnyPublisher that publishes the same output type and has the same failure type. This can make your code easier to read and write,
                // especially when dealing with complex publisher chains. In the context of the startSequence(times:) function in the SequenceViewModel class,
                // eraseToAnyPublisher is used to erase the type of the publisher created by the flatMap operator.
                // This allows the flatMap operator to return a single type of publisher, regardless of the types of the publishers created inside the flatMap closure.
                .eraseToAnyPublisher()
            }
            .sink(receiveValue: { [weak self] number in
                self?.sequenceAction?(number) // Call numberUpdated which has been set up as a callback in onAppear of the ImmersiveView
            })
    }
   func initSequence(randomSeed: Float) {
       let values = [
           1.5, 1.0, 0.5, 0.2
       ]
       // multiply each value by the randomSeed
       let scaledValues = values.map { $0 * Double(randomSeed) }
       // let value = [18.04871, 22.22698, 25.87306, 27.67265, 28.7059, 33.62753, 33.82517, 33.97646, 34.13338, 34.22082, 34.3946, 34.66798, 34.7878,
           // 34.91025, 35.02127, 35.17823, 35.3702, 35.5673, 35.68857, 35.81052, 36.07796, 36.21152, 40.0849,]
       print("scaledValues: \(scaledValues) ssed: \(randomSeed)")
       self.startSequence(times: scaledValues)
   }

    deinit {
        cancellable?.cancel()
    }
}

// SwiftUI View
struct ImmersiveView: View {
    @StateObject private var originalParticleViewModel = SequenceViewModel(color: UIColor.red)
    @StateObject private var sequenceViewModel_1 = SequenceViewModel(color: UIColor.blue)
    @StateObject private var sequenceViewModel_2 = SequenceViewModel(color: UIColor.green)

    @State private var currentParticleSize: Float = 0.1
    @State private var currentParticleLifeSpan: Float = 0.5
    @State private var currentParticleSpeed: Float = 0.01


    private var originalParticleModel = ModelEntity()
    private var sequenceParticleModel = ModelEntity()
    private var timerParticleModel = ModelEntity()

    // timer to drive sequenceParticleModel
    // This could be cool if we know the tempo of the music then this can emit in time with the music
    let timer_1 = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    let timer_2 = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        RealityView { content in
            originalParticleModel.components.set(originalParticleViewModel.particleSystem)
            content.add(originalParticleModel)
            sequenceParticleModel.components.set(sequenceViewModel_1.particleSystem)
            content.add(sequenceParticleModel)
            timerParticleModel.components.set(sequenceViewModel_2.particleSystem)
            content.add(timerParticleModel)
        }
        .onAppear {
            playSound()
            originalParticleViewModel.initSequence(randomSeed: Float.random(in: 0.7...2))
            let times_1 = [2.0, 4.0, 6.0] // Example time intervals for bursts
            sequenceViewModel_1.startSequence(times: times_1)
            let times_2 = [1.0, 5.0] // Example time intervals for bursts
            sequenceViewModel_2.startSequence(times: times_2)
            originalParticleViewModel.sequenceAction = { number in
                // Reassign the updated particleSystem to the ModelEntity
                originalParticleModel.components.set(originalParticleViewModel.particleSystem)
                // Trigger a burst of particles afer model is updated
                originalParticleViewModel.burst()
                let randomSeed = 1.0// Float.random(in: 0.7...2)
                originalParticleViewModel.initSequence(randomSeed: Float(randomSeed))
            }
        }
        .onReceive(timer_1) { _ in
            updateParticleSystem(size: currentParticleSize == 0.003 ? 0.05 : 0.092,
                                 lifeSpan: currentParticleLifeSpan == 1.0 ? 10.0 : 1.0,
                                 speed: currentParticleSpeed == 0.01 ? 1.0 : 0.01)
            sequenceParticleModel.components.set(sequenceViewModel_1.particleSystem)
        }
        .onReceive(timer_2) { _ in
            updateParticleSystem(size: currentParticleSize == 0.0055 ? 0.001 : 0.012,
                                 lifeSpan: currentParticleLifeSpan == 1.0 ? 10.0 : 1.0,
                                 speed: currentParticleSpeed == 0.01 ? 1.0 : 0.01)
            sequenceParticleModel.components.set(sequenceViewModel_2.particleSystem)
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
        particles.emitterShapeSize = [0.2, 0.2, 0.2]
        particles.speed = speed
        
        particles.mainEmitter.birthRate = 500
        particles.mainEmitter.size = size
        particles.mainEmitter.lifeSpan = Double(lifeSpan)
        particles.mainEmitter.color = .evolving(start: .single(.orange), end: .single(.blue))

        return particles
    }

    // Function to update the second particle system properties
    private func updateParticleSystem(size: Float, lifeSpan: Float, speed: Float) {
        // to update particle system in this way tha variable has to be declared as a state variable
        currentParticleSize = size
        currentParticleLifeSpan = lifeSpan
        currentParticleSpeed = speed

        if var particles = sequenceParticleModel.components[ParticleEmitterComponent.self] {
            particles.mainEmitter.size = size
            particles.mainEmitter.lifeSpan = Double(lifeSpan)
            particles.speed = speed
            sequenceParticleModel.components.set(particles)
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
