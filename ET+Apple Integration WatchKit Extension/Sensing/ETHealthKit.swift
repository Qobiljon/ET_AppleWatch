import Foundation
import HealthKit


let HK_DATA_SOURCE_IDS: [HKQuantityType:Int32] = [
    // activity
    HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)! : 70,
    HKQuantityType.quantityType(forIdentifier: .distanceCycling)! : 69,
    HKQuantityType.quantityType(forIdentifier: .appleStandTime)! : 68,
    HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)! : 67,
    HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)! : 66,
    
    // hearing
    HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)! : 65,
    HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure)! : 64,
    
    // heart (vital)
    HKQuantityType.quantityType(forIdentifier: .heartRate)! : 63,
    HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)! : 62,
    HKQuantityType.quantityType(forIdentifier: .restingHeartRate)! : 61,
    HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage)! : 60,
    
    // mobility
    HKQuantityType.quantityType(forIdentifier: .stepCount)! : 59,
    HKQuantityType.quantityType(forIdentifier: .walkingSpeed)! : 58,
    HKQuantityType.quantityType(forIdentifier: .walkingStepLength)! : 57,
    
    // other data
    HKQuantityType.quantityType(forIdentifier: .numberOfTimesFallen)! : 56,
]
let HK_DATA_TYPES = Array(HK_DATA_SOURCE_IDS.keys)
func getHKDataSourceId(_ quantityType: HKQuantityType) -> Int32? {
    if let res = HK_DATA_SOURCE_IDS[quantityType] {
        return res
    }
    return nil
}

class ETHealthKit {
    private var healthStore: HKHealthStore?
    private var workout: (HKWorkoutSession, WorkoutSessionDelegate)?
    
    
    // singleton
    private static var instance: ETHealthKit?
    static func getInstance() -> ETHealthKit? {
        if instance == nil {
            instance = ETHealthKit()
        }
        return instance
    }
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    
    func requestHealthKitAuthorization() {
        guard let healthStore = self.healthStore else { return }
        healthStore.requestAuthorization(toShare: nil, read: Set(HK_DATA_TYPES)) { (success, error) in
            if error != nil {
                print("healthkit authorization error")
            } else {
                // print("healthkit authorization request success = \(success)")
            }
        }
    }
    func startHealthKitAcquisition() {
        guard let healthStore = self.healthStore else { return }
        requestHealthKitAuthorization()
        
        if workout == nil {
            // trigger a workout session
            let workoutConfiguration = HKWorkoutConfiguration()
            workoutConfiguration.activityType = .other
            workoutConfiguration.locationType = .indoor
            
            do {
                let session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
                let delegate = WorkoutSessionDelegate(healthStore)
                session.delegate = delegate
                session.startActivity(with: Date())
                workout = (session, delegate)
                print("workout session created")
            } catch {
                print("workout session creation error")
            }
        }
    }
    func stopHealthKitAcquisition() {
        if workout != nil {
            let delegate = workout!.1
            delegate.cancelCurrentQueries()
            workout = nil
        }
    }
    
    private class WorkoutSessionDelegate : NSObject, HKWorkoutSessionDelegate {
        private let healthStore: HKHealthStore
        private var currentQueries: [HKQuery]
        
        init(_ healthStore: HKHealthStore) {
            self.healthStore = healthStore
            self.currentQueries = []
        }
        
        func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
            print("workout session update")
            if toState == .running {
                makeQueries(date)
            } else if toState == .ended {
                cancelCurrentQueries()
            } else {
                print("unknown workout state \(toState)")
            }
        }
        func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
            print("workout session error")
        }
        
        func queryResultHandler(query: HKAnchoredObjectQuery, samples: [HKSample]?, _: [HKDeletedObject]?, _: HKQueryAnchor?, error: Error?) {
            guard let samples = samples else { return }
            guard let acquisitionFile = ETwatchOSAcquisitionFile.getInstance() else { return }
            guard let dataSourceId = getHKDataSourceId(query.objectType as! HKQuantityType) else { return }
            
            if error != nil {
                print("healthkit query error \(error!)")
            } else if samples.count == 0 {
                // print("\(query.objectType!) empty samples")
            } else {
                for sample in samples {
                    if sample is HKQuantitySample {
                        let quantitySample = sample as! HKQuantitySample
                        let timestamp = Int64(quantitySample.endDate.timeIntervalSince1970 * 1000)
                        let value = "\(quantitySample.quantity)"
                        
                        do {
                            try acquisitionFile.storeDataSample(
                                dataSourceId: dataSourceId,
                                timestamp: timestamp,
                                value: value
                            )
                        } catch {
                            print("error storing healthkit data sample \(error)")
                        }
                    }
                }
            }
        }
        private func makeQueries(_ date: Date) {
            let now = Date()
            let predicate = HKQuery.predicateForSamples(
                withStart: Calendar.current.date(byAdding: .day, value: -1, to: now),
                end: now,
                options: .strictEndDate
            )
            for quantityType in HK_DATA_TYPES {
                let query = HKAnchoredObjectQuery(
                    type: quantityType,
                    predicate: predicate,
                    anchor: nil,
                    limit: Int(HKObjectQueryNoLimit),
                    resultsHandler: queryResultHandler
                )
                healthStore.execute(query)
                currentQueries.append(query)
            }
        }
        func cancelCurrentQueries() {
            for query in currentQueries {
                healthStore.stop(query)
            }
            currentQueries.removeAll()
        }
    }
}
