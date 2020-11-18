import Foundation
import HealthKit


class ETHealthKit {
    // variables
    private var healthStore: HKHealthStore?
    private let dataTypes: Set<HKObjectType> = [
        // activity
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceCycling)!,
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.appleStandTime)!,
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.appleExerciseTime)!,
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
        
        // hearing
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.environmentalAudioExposure)!,
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.headphoneAudioExposure)!,
        
        // heart (vital)
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!,
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate)!,
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.walkingHeartRateAverage)!,
        
        // mobility
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.walkingSpeed)!,
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.walkingStepLength)!,
        
        // other data
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.numberOfTimesFallen)!,
    ]
    
    
    // init function
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
            
            guard let healthStore = self.healthStore else { return }
            for dataType in self.dataTypes {
                if healthStore.authorizationStatus(for: dataType) != HKAuthorizationStatus.sharingAuthorized {
                    requestHealthKitAuthorization(healthStore: healthStore) { (success, error) in
                        print("requestPermission success \(success)")
                        guard let error = error else { return }
                        print("error \(error)")
                    }
                    break
                }
            }
        }
    }
    
    
    // permission check
    private func requestHealthKitAuthorization(healthStore: HKHealthStore, completion: @escaping (Bool, Error?) -> Void) {
        // authorization for what data
        // request authorization
        healthStore.requestAuthorization(toShare: [], read: dataTypes, completion: completion)
    }
    
    
    // sensor start/stop functions
    func startSensing() {
        guard let healthStore = self.healthStore else { return }
        
        for dataType in self.dataTypes {
            if healthStore.authorizationStatus(for: dataType) != HKAuthorizationStatus.sharingAuthorized {
                return
            }
        }
        
        
    }
    func stopSensing() {
        
    }
}
