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

class SequenceViewModel: ObservableObject {
    private var cancellable: AnyCancellable?
    private let numbers = [5,6,7,8,9,20,20] // Example array of numbers
    private let delaySeconds = Float.random(in: 1.0...10.0) // Delay in seconds between each number
    private let randomSize = Float.random(in: 0.02...0.8)

    @Published var particleSystem = ParticleEmitterComponent()
    @Published var durations: [Double] = []
    @Published var loudness: [Double] = []
    @Published var pitches: [[Double]] = [[]]
    
    // Define a callback variable that will be triggered when a number is updated
    // This is triggered from startSequence
    var numberUpdated: ((Int) -> Void)?

    func setupParticleSystem() {
//        self.particleSystem.timing = .repeating(warmUp: 0, emit:ParticleEmitterComponent.Timing.VariableDuration(duration:1), idle: ParticleEmitterComponent.Timing.VariableDuration(duration: 1))
        self.particleSystem.emitterShape = .sphere
        self.particleSystem.birthLocation = .volume
        self.particleSystem.birthDirection = .normal
        self.particleSystem.emitterShapeSize = [10, 10, 10] * Float.random(in: 0.05...0.80)
        
        self.particleSystem.mainEmitter.birthRate = 300
        self.particleSystem.burstCount = 2000
        self.particleSystem.burstCountVariation = 20
        //particles.mainEmitter.BurstCount = 100
        self.particleSystem.mainEmitter.size = randomSize
        self.particleSystem.mainEmitter.lifeSpan = 2
        self.particleSystem.mainEmitter.color = .evolving(start: .single(.orange), end: .single(.blue))
        self.particleSystem.mainEmitter.spreadingAngle = 1
    }
    
    func burst(){
        self.particleSystem.mainEmitter.color = .evolving(start: .single(UIColor.random()), end: .single(UIColor.random()))
        self.particleSystem.mainEmitter.birthRate = Float.random(in: 50.0...600)
        self.particleSystem.mainEmitter.size = Float.random(in: 0.01...0.5)
        self.particleSystem.mainEmitter.lifeSpan = Double.random(in: 0.1...3.0)
        print("bursted")
    }
    
    // The `startSequence` function takes an array of time intervals (in seconds) as input.
    // It uses the Combine framework to create a sequence of delayed actions. 
    // The Publishers.Sequence publisher emits each time interval to the flatMap operator, which creates a new Just publisher 
    // that emits the time interval and then completes. The Just publisher is delayed by the time interval using the delay(for:scheduler:) operator. 
    // A sequence of actions is created where each action is delayed by the corresponding time interval in the input array.
    // When each time interval elapses, the `burst` function is called to trigger a burst of particles in the particle system.
    func startSequence(times : [Double]) {
        cancellable = Publishers.Sequence(sequence: times)
            .flatMap { number in
                Deferred {
                    Future<Int, Never> { promise in
                        DispatchQueue.main.asyncAfter(deadline: .now() + number) {
                            promise(.success(Int(number)))
                        }
                    }
                }.eraseToAnyPublisher()
            }
            .sink(receiveValue: { [weak self] number in
                self?.numberUpdated?(number) // Call numberUpdated which has been set up as a callback in onAppear of the ImmersiveView
            })
    }
    
    func fetchDataFromEndpoint(urlString: String) {
            let networkManager = NetworkManager()
            networkManager.fetchData(from: urlString) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        do {
                            let decodedData = try JSONDecoder().decode(EndpointData.self, from: data)
                            // Update the model with fetched data
                            self?.durations = decodedData.durations
                            self?.loudness = decodedData.loudness
                            self?.pitches = decodedData.pitches
                            let value = decodedData.loudness.enumerated().map{ (index, element) in
                                if(element > -10){
                                    return decodedData.durations[index]
                                }else{
                                    return nil
                                }
                            }.compactMap{$0}
                           print(value)
                            
                            // Optionally, trigger actions based on the fetched data
                            self?.startSequence(times: value)
                        } catch {
                            print("Failed to decode data: \(error.localizedDescription)")
                        }
                    case .failure(let error):
                        print("Failed to fetch data: \(error.localizedDescription)")
                    }
                }
            }
        }

    // Add a new method to start a sequence based on fetched data
    func startSequenceBasedOnFetchedData() {
        // Example: Use `durations` to control the delay between actions
        // This is just a placeholder to demonstrate how you might proceed
        print("Starting sequence with fetched durations: \(durations)")
        print("Starting sequence with fetched loudness: \(loudness)")
        print("Starting sequence with fetched pitches: \(pitches)")
    }
    
    deinit {
        cancellable?.cancel()
    }
}

struct EndpointData: Decodable {
    let durations: [Double]
    let loudness: [Double]
    let pitches: [[Double]]
}

struct ImmersiveView: View {
    @StateObject private var viewModel = SequenceViewModel()
    @State private var particleModel = ModelEntity()

    var body: some View {
        RealityView { content in
            viewModel.setupParticleSystem()
            particleModel.components.set(viewModel.particleSystem)
            content.add(particleModel)
        }
        .onAppear {
            playSound()
            let urlString = "https://synesthesia-tau.vercel.app/analyze?track_id=4ozN7LaIUodj1ADWdempuv"
            viewModel.fetchDataFromEndpoint(urlString: urlString)
            viewModel.numberUpdated = { number in
                viewModel.burst()
                // Reassign the updated particleSystem to the ModelEntity
                particleModel.components.set(viewModel.particleSystem)
            }
        }
        .onDisappear() {
            player?.stop()
        }
    }
    
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
