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
    @Published var durations: [Double] = []
    @Published var loudness: [Double] = []
    @Published var pitches: [[Double]] = [[]]
    
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
                            
                            // Optionally, trigger actions based on the fetched data
                            self?.startSequenceBasedOnFetchedData()
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

    var body: some View {
        RealityView { content in
            let particleModel = ModelEntity()
           
            
            particleModel.components.set(viewModel.particleSystem)
            content.add(particleModel)
            viewModel.startSequence()
        }.onAppear {
            let urlString = "http://127.0.0.1:3000/analyze?track_id=4ozN7LaIUodj1ADWdempuv"
            viewModel.fetchDataFromEndpoint(urlString: urlString)
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
