import CloudKit
import Foundation

/// CloudKit Test Data Population
/// Run this from your iOS app to populate CloudKit with test records
class CloudKitTestData {
    private let container = CKContainer(identifier: "iCloud.com.sankalp.AstronovaApp")
    private var privateDatabase: CKDatabase {
        return container.privateCloudDatabase
    }
    
    /// Test all CloudKit record types with sample data
    func populateTestData() async {
        print("🧪 Starting CloudKit Test Data Population...")
        
        do {
            let userProfileRecord = try await createTestUserProfile()
            let userId = userProfileRecord.recordID.recordName
            
            // Create test records for each type
            await createTestChatMessages(userId: userId)
            await createTestHoroscopes(userId: userId)
            await createTestKundaliMatches(userId: userId)
            await createTestBirthCharts(userId: userId)
            await createTestBookmarkedReadings(userId: userId)
            
            print("✅ CloudKit test data population complete!")
        } catch {
            print("❌ CloudKit test data population failed: \\(error)")
        }
    }
    
    // MARK: - UserProfile Test Data
    
    private func createTestUserProfile() async throws -> CKRecord {
        let record = CKRecord(recordType: "UserProfile")
        
        record["fullName"] = "Sankalp Thakur" as CKRecordValue
        record["birthDate"] = dateFromString("1995-03-15") as CKRecordValue
        record["birthLocation"] = "New Delhi, India" as CKRecordValue
        record["birthTime"] = "14:30" as CKRecordValue
        record["preferredLanguage"] = "en" as CKRecordValue
        record["sunSign"] = "Pisces" as CKRecordValue
        record["moonSign"] = "Cancer" as CKRecordValue
        record["risingSign"] = "Virgo" as CKRecordValue
        record["bio"] = "Software developer and astrology enthusiast" as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        
        // Add location for birth coordinates
        let birthCoordinates = CLLocation(latitude: 28.6139, longitude: 77.2090)
        record["birthCoordinates"] = birthCoordinates as CKRecordValue
        record["timezone"] = "Asia/Kolkata" as CKRecordValue
        
        let savedRecord = try await privateDatabase.save(record)
        print("✅ UserProfile record created: \\(savedRecord.recordID.recordName)")
        return savedRecord
    }
    
    // MARK: - ChatMessage Test Data
    
    private func createTestChatMessages(userId: String) async {
        let messages = [
            ("Hi! Can you tell me about my horoscope for today?", true, "question"),
            ("Hello Sankalp! As a Pisces with Cancer moon and Virgo rising, today brings beautiful energy for emotional healing and practical matters...", false, "response"),
            ("That sounds wonderful! What about my love compatibility?", true, "follow_up"),
            ("Your water-fire combination creates passionate dynamics. Focus on open communication...", false, "response")
        ]
        
        for (content, isUser, messageType) in messages {
            let record = CKRecord(recordType: "ChatMessage")
            record["userProfileId"] = userId as CKRecordValue
            record["conversationId"] = "conv_astro_reading_001" as CKRecordValue
            record["content"] = content as CKRecordValue
            record["isUser"] = (isUser ? 1 : 0) as CKRecordValue
            record["timestamp"] = Date() as CKRecordValue
            record["messageType"] = messageType as CKRecordValue
            
            do {
                let savedRecord = try await privateDatabase.save(record)
                print("✅ ChatMessage record created: \\(savedRecord.recordID.recordName)")
            } catch {
                print("❌ Failed to save ChatMessage: \\(error)")
            }
        }
    }
    
    // MARK: - Horoscope Test Data
    
    private func createTestHoroscopes(userId: String) async {
        // Personal horoscope
        let personalHoroscope = CKRecord(recordType: "Horoscope")
        personalHoroscope["userProfileId"] = userId as CKRecordValue
        personalHoroscope["date"] = Date() as CKRecordValue
        personalHoroscope["type"] = "daily" as CKRecordValue
        personalHoroscope["content"] = "Your Pisces intuition is heightened today. With Cancer moon energy supporting your emotional depths and Virgo rising bringing practical clarity, this is perfect for manifestation work." as CKRecordValue
        personalHoroscope["sign"] = "pisces" as CKRecordValue
        personalHoroscope["createdAt"] = Date() as CKRecordValue
        
        // Lucky elements as JSON data
        let luckyElements = [
            "luckyNumbers": [7, 14, 23],
            "luckyColors": ["sea blue", "silver", "lavender"],
            "luckyStone": "moonstone"
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: luckyElements),
           let asset = CKAsset(data: jsonData) {
            personalHoroscope["luckyElements"] = asset
        }
        
        do {
            let savedRecord = try await privateDatabase.save(personalHoroscope)
            print("✅ Horoscope record created: \\(savedRecord.recordID.recordName)")
        } catch {
            print("❌ Failed to save Horoscope: \\(error)")
        }
    }
    
    // MARK: - KundaliMatch Test Data
    
    private func createTestKundaliMatches(userId: String) async {
        let match = CKRecord(recordType: "KundaliMatch")
        match["userProfileId"] = userId as CKRecordValue
        match["partnerName"] = "Emma Watson" as CKRecordValue
        match["partnerBirthDate"] = dateFromString("1990-04-15") as CKRecordValue
        match["partnerLocation"] = "Paris, France" as CKRecordValue
        match["compatibilityScore"] = 87 as CKRecordValue
        match["createdAt"] = Date() as CKRecordValue
        
        // Detailed analysis as JSON
        let analysis = [
            "overallScore": 87,
            "vedicScore": 92,
            "chineseScore": 84,
            "strengths": ["Strong emotional connection", "Complementary communication"],
            "challenges": ["Different life paces", "Career priorities may clash"]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: analysis),
           let asset = CKAsset(data: jsonData) {
            match["detailedAnalysis"] = asset
        }
        
        do {
            let savedRecord = try await privateDatabase.save(match)
            print("✅ KundaliMatch record created: \\(savedRecord.recordID.recordName)")
        } catch {
            print("❌ Failed to save KundaliMatch: \\(error)")
        }
    }
    
    // MARK: - BirthChart Test Data
    
    private func createTestBirthCharts(userId: String) async {
        let chart = CKRecord(recordType: "BirthChart")
        chart["userProfileId"] = userId as CKRecordValue
        chart["chartType"] = "natal" as CKRecordValue
        chart["systems"] = ["western", "vedic"] as CKRecordValue
        chart["createdAt"] = Date() as CKRecordValue
        
        // Planetary positions as JSON
        let positions = [
            [
                "planet": "Sun",
                "sign": "Pisces",
                "degree": 24.5,
                "house": 7
            ],
            [
                "planet": "Moon", 
                "sign": "Cancer",
                "degree": 15.2,
                "house": 11
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: positions),
           let asset = CKAsset(data: jsonData) {
            chart["planetaryPositions"] = asset
        }
        
        // Birth data as JSON
        let birthData = [
            "birthDate": "1995-03-15",
            "birthTime": "14:30",
            "latitude": 28.6139,
            "longitude": 77.2090,
            "timezone": "Asia/Kolkata"
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: birthData),
           let asset = CKAsset(data: jsonData) {
            chart["birthData"] = asset
        }
        
        do {
            let savedRecord = try await privateDatabase.save(chart)
            print("✅ BirthChart record created: \\(savedRecord.recordID.recordName)")
        } catch {
            print("❌ Failed to save BirthChart: \\(error)")
        }
    }
    
    // MARK: - BookmarkedReading Test Data
    
    private func createTestBookmarkedReadings(userId: String) async {
        let bookmark = CKRecord(recordType: "BookmarkedReading")
        bookmark["userProfileId"] = userId as CKRecordValue
        bookmark["readingType"] = "horoscope" as CKRecordValue
        bookmark["title"] = "Powerful Pisces Daily Reading - March 15, 2025" as CKRecordValue
        bookmark["content"] = "Your Pisces intuition is heightened today. With Cancer moon energy supporting your emotional depths and Virgo rising bringing practical clarity, this is perfect for manifestation work." as CKRecordValue
        bookmark["originalDate"] = dateFromString("2025-03-15") as CKRecordValue
        bookmark["bookmarkedAt"] = Date() as CKRecordValue
        
        do {
            let savedRecord = try await privateDatabase.save(bookmark)
            print("✅ BookmarkedReading record created: \\(savedRecord.recordID.recordName)")
        } catch {
            print("❌ Failed to save BookmarkedReading: \\(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func dateFromString(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - Usage

/*
To use this in your iOS app:

1. Add this file to your Xcode project
2. Call from any view or view controller:

Task {
    let testData = CloudKitTestData()
    await testData.populateTestData()
}

3. Check CloudKit Dashboard to see the records!
*/