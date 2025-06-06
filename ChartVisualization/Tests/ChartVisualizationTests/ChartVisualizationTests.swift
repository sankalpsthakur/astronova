import XCTest
@testable import ChartVisualization
import CoreLocation

final class ChartVisualizationTests: XCTestCase {
    
    func testChartCalculatorCreation() throws {
        let calculator = ChartCalculator()
        XCTAssertNotNil(calculator)
    }
    
    func testBirthChartCalculation() throws {
        let calculator = ChartCalculator()
        let birthData = BirthData(
            date: Date(),
            time: DateComponents(hour: 12, minute: 0, second: 0),
            location: CLLocation(latitude: 40.7128, longitude: -74.0060)
        )
        
        let chart = calculator.calculateChart(for: birthData, type: .siderealBirth)
        
        XCTAssertEqual(chart.chartType, .siderealBirth)
        XCTAssertFalse(chart.planets.isEmpty)
        XCTAssertEqual(chart.houses.count, 12)
        XCTAssertEqual(chart.birthData.birthDate, birthData.date)
    }
    
    func testZodiacSignFromLongitude() throws {
        let planet = ChartPlanet(name: "Sun", symbol: "☉", longitude: 45.0, house: 1)
        XCTAssertEqual(planet.sign, .taurus) // 45° is in Taurus (30-60°)
        XCTAssertEqual(planet.degree, 15.0, accuracy: 0.1) // 45° - 30° = 15°
    }
    
    func testPlanetRetrogradeDetermination() throws {
        let retroPlanet = ChartPlanet(
            name: "Mercury",
            symbol: "☿",
            longitude: 120.0,
            speed: -0.5, // Negative speed indicates retrograde
            isRetrograde: true,
            house: 4
        )
        
        XCTAssertTrue(retroPlanet.isRetrograde)
        XCTAssertEqual(retroPlanet.sign, .leo) // 120° is in Leo (120-150°)
    }
    
    func testHouseCalculation() throws {
        let house = ChartHouse(number: 1, cusp: 0.0) // Ascendant at 0° Aries
        
        XCTAssertEqual(house.number, 1)
        XCTAssertEqual(house.sign, .aries)
        XCTAssertEqual(house.ruler, "Mars")
        XCTAssertEqual(house.interpretation, "Identity & Appearance")
    }
    
    func testAspectCalculation() throws {
        let planet1 = ChartPlanet(name: "Sun", symbol: "☉", longitude: 0.0, house: 1)
        let planet2 = ChartPlanet(name: "Moon", symbol: "☽", longitude: 120.0, house: 5)
        
        let aspect = ChartAspect(
            planet1: planet1,
            planet2: planet2,
            type: .trine,
            orb: 0.0,
            isApplying: true
        )
        
        XCTAssertEqual(aspect.type, .trine)
        XCTAssertTrue(aspect.type.isHarmonious)
        XCTAssertEqual(aspect.type.angle, 120.0)
    }
    
    func testChartManagerInitialization() throws {
        let manager = ChartManager()
        
        XCTAssertNil(manager.currentChart)
        XCTAssertNil(manager.transitPlanets)
        XCTAssertFalse(manager.isCalculating)
        XCTAssertNil(manager.error)
    }
    
    func testChartTypeProperties() throws {
        XCTAssertTrue(ChartType.siderealBirth.isSidereal)
        XCTAssertFalse(ChartType.siderealBirth.isTransitChart)
        XCTAssertFalse(ChartType.siderealBirth.isPremiumFeature)
        
        XCTAssertTrue(ChartType.siderealTransit.isSidereal)
        XCTAssertTrue(ChartType.siderealTransit.isTransitChart)
        XCTAssertTrue(ChartType.siderealTransit.isPremiumFeature)
        
        XCTAssertFalse(ChartType.tropicalBirth.isSidereal)
        XCTAssertFalse(ChartType.tropicalBirth.isTransitChart)
        
        XCTAssertTrue(ChartType.tropicalTransit.isTransitChart)
        XCTAssertTrue(ChartType.tropicalTransit.isPremiumFeature)
    }
    
    func testZodiacSignElements() throws {
        XCTAssertEqual(ZodiacSign.aries.element, .fire)
        XCTAssertEqual(ZodiacSign.taurus.element, .earth)
        XCTAssertEqual(ZodiacSign.gemini.element, .air)
        XCTAssertEqual(ZodiacSign.cancer.element, .water)
    }
    
    func testZodiacSignModalities() throws {
        XCTAssertEqual(ZodiacSign.aries.modality, .cardinal)
        XCTAssertEqual(ZodiacSign.taurus.modality, .fixed)
        XCTAssertEqual(ZodiacSign.gemini.modality, .mutable)
    }
}