import Foundation
import HealthKit


class ETHealthKit {
    private let healthStore = HKHealthStore()
    
    func sampleResultHandler(query: HKSampleQuery, samples: [HKSample]?, error: Error?) {
        guard let samples = samples else {
            if error != nil {
                print("error \(error!)")
            }
            return
        }
        print("\(ETTools.getHKDataSourceId(objectType: query.objectType!)) samples = \(samples.count)")
        if samples.count > 0 {
            for sample in samples {
                let _sample = sample as! HKQuantitySample
                
                let dataSourceId = ETTools.getHKDataSourceId(objectType: query.objectType!)
                let timestamp = Int64(_sample.endDate.timeIntervalSince1970 * 1000)
                let value = "\(_sample.quantity)"
                
                ETTools.storeData(
                    dataSourceId: dataSourceId,
                    timestamp: timestamp,
                    value: value
                )
                // print("\(dataSourceId), \(timestamp), \(value)")
            }
        }
    }
    
    func requestHealthKitData() {
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -45, to: Date()), // a day ago
            end: Date(), // today
            options: .strictEndDate
        )
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        for dataType in ETTools.getHKDataTypes() {
            if dataType is HKSampleType {
                let query = HKSampleQuery(
                    sampleType: dataType as! HKSampleType,
                    predicate: predicate,
                    limit: Int(HKObjectQueryNoLimit),
                    sortDescriptors: [sortDescriptor],
                    resultsHandler: sampleResultHandler
                )
                healthStore.execute(query)
            }
        }
    }
    func requestHealthKitAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // authorization for what data
        // request authorization
        healthStore.requestAuthorization(
            toShare: [],
            read: Set(ETTools.getHKDataTypes()),
            completion: completion
        )
    }
    func isHealthKitUnauthorized() -> Bool {
        for dataType in ETTools.getHKDataTypes() {
            if healthStore.authorizationStatus(for: dataType) != HKAuthorizationStatus.sharingAuthorized {
                return true
            }
        }
        return false
    }
}
