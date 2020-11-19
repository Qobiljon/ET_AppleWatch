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
                
                let dataSourceId = getDataSourceId(objectType: query.objectType!)
                let timestamp = Int64(_sample.endDate.timeIntervalSince1970 * 1000)
                let value = "\(_sample.quantity)".data(using: .utf8)!
                
                ETSensor.submitData(
                    dataSourceId: dataSourceId,
                    timestamp: timestamp,
                    value: value
                )
                // print("\(dataSourceId), \(timestamp), \(value)")
            }
        }
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
    func stopSensing() {
    }
    
    
    // utility functions
    private func requestHealthKitAuthorization(healthStore: HKHealthStore, completion: @escaping (Bool, Error?) -> Void) {
        // authorization for what data
        // request authorization
        healthStore.requestAuthorization(toShare: [], read: sampleTypes, completion: completion)
    }
    private func getDataSourceId(objectType: HKObjectType) -> Int32 {
        switch objectType {
        // activity
        case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!:
            return 70
        case HKQuantityType.quantityType(forIdentifier: .distanceCycling)!:
            return 69
        case HKQuantityType.quantityType(forIdentifier: .appleStandTime)!:
            return 68
        case HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!:
            return 67
        case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!:
            return 66
        // hearing
        case HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)!:
            return 65
        case HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure)!:
            return 64
        // heart (vital)
        case HKQuantityType.quantityType(forIdentifier: .heartRate)!:
            return 63
        case HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!:
            return 62
        case HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!:
            return 61
        case HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage)!:
            return 60
        // mobility
        case HKQuantityType.quantityType(forIdentifier: .stepCount)!:
            return 59
        case HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!:
            return 58
        case HKQuantityType.quantityType(forIdentifier: .walkingStepLength)!:
            return 57
        // other data
        case HKQuantityType.quantityType(forIdentifier: .numberOfTimesFallen)!:
            return 56
        default:
            return -1
        }
    }
}
