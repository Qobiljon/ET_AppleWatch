import Foundation
import HealthKit


class ETHealthKit {
    // variables
    private var healthStore: HKHealthStore?
    private let sampleTypes: Set<HKSampleType> = [
        // activity
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
        HKQuantityType.quantityType(forIdentifier: .appleStandTime)!,
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        
        // hearing
        HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)!,
        HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure)!,
        
        // heart (vital)
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
        HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage)!,
        
        // mobility
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!,
        HKQuantityType.quantityType(forIdentifier: .walkingStepLength)!,
        
        // other data
        HKQuantityType.quantityType(forIdentifier: .numberOfTimesFallen)!,
    ]
    
    
    // init function
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
            
            guard let healthStore = self.healthStore else { return }
            for sampleType in self.sampleTypes {
                if healthStore.authorizationStatus(for: sampleType) != HKAuthorizationStatus.sharingAuthorized {
                    requestHealthKitAuthorization(healthStore: healthStore) { (success, error) in
                        print("requestPermission success \(success)")
                        guard let error = error else {
                            return
                        }
                        print("error \(error)")
                    }
                    break
                }
            }
        }
    }
    
    
    // event handler (listener)
    func sampleResultHandler(query: HKSampleQuery, samples: [HKSample]?, error: Error?) {
        guard let samples = samples else {
            if error != nil {
                print("error \(error!)")
            }
            return
        }
        if samples.count > 0 {
            for sample in samples {
                let _sample = sample as! HKQuantitySample
                let sampleType = query.objectType!
                let timestamp = _sample.endDate.timeIntervalSince1970 * 1000
                let value = _sample.quantity
                
                print("\(sampleType), \(timestamp), \(value)")
            }
        }
    }
    
    
    // permission check
    private func requestHealthKitAuthorization(healthStore: HKHealthStore, completion: @escaping (Bool, Error?) -> Void) {
        // authorization for what data
        // request authorization
        healthStore.requestAuthorization(toShare: [], read: sampleTypes, completion: completion)
    }
    
    
    // sensing start/stop functions
    func startSensing() -> Bool {
        guard let healthStore = self.healthStore else { return false }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .month, value: -1, to: Date()), // a month ago
            end: Date(), // today
            options: .strictEndDate
        )
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        for sampleType in self.sampleTypes {
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: Int(HKObjectQueryNoLimit),
                sortDescriptors: [sortDescriptor],
                resultsHandler: sampleResultHandler
            )
            healthStore.execute(query)
        }
        return true
    }
    func stopSensing() -> Bool {
        return false
    }
}
