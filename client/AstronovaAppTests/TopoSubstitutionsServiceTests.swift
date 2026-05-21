//
//  TopoSubstitutionsServiceTests.swift
//  AstronovaAppTests
//
//  Verifies the Codable contract + UTC-day cache behavior of the
//  TopoSubstitutionsService that feeds TerrainComputer.substitute with
//  Swiss-Ephemeris-derived values from /api/v1/ephemeris/topo-substitutions.
//

import XCTest
@testable import AstronovaApp

final class TopoSubstitutionsServiceTests: XCTestCase {

    func test_decodes_server_response_with_snake_case_keys() throws {
        // Mirror of a real production response — verify CodingKeys map.
        let json = """
        {
          "void_end_time_iso": "2026-05-23T06:57:00Z",
          "void_end_time": "6:57 AM",
          "aspect_partner": "Mercury",
          "aspect_type": "sextile",
          "aspect_angle": "60°",
          "aspect_orb_degrees": 0.82,
          "eclipse_distance_days": 83,
          "computed_at_iso": "2026-05-21T20:23:46Z"
        }
        """.data(using: .utf8)!

        let subs = try JSONDecoder().decode(TopoSubstitutions.self, from: json)
        XCTAssertEqual(subs.voidEndTimeIso, "2026-05-23T06:57:00Z")
        XCTAssertEqual(subs.voidEndTime, "6:57 AM")
        XCTAssertEqual(subs.aspectPartner, "Mercury")
        XCTAssertEqual(subs.aspectType, "sextile")
        XCTAssertEqual(subs.aspectAngle, "60°")
        XCTAssertEqual(subs.aspectOrbDegrees, 0.82, accuracy: 0.0001)
        XCTAssertEqual(subs.eclipseDistanceDays, 83)
        XCTAssertEqual(subs.computedAtIso, "2026-05-21T20:23:46Z")
    }

    func test_decodes_empty_aspect_when_no_major_aspect_in_orb() throws {
        // Server returns "" for all aspect fields when Moon makes no major
        // aspect within orb. Make sure the client accepts that shape.
        let json = """
        {
          "void_end_time_iso": "2026-05-23T06:57:00Z",
          "void_end_time": "6:57 AM",
          "aspect_partner": "",
          "aspect_type": "",
          "aspect_angle": "",
          "aspect_orb_degrees": 0.0,
          "eclipse_distance_days": 83,
          "computed_at_iso": "2026-05-21T20:23:46Z"
        }
        """.data(using: .utf8)!

        let subs = try JSONDecoder().decode(TopoSubstitutions.self, from: json)
        XCTAssertEqual(subs.aspectPartner, "")
        XCTAssertEqual(subs.aspectType, "")
        XCTAssertEqual(subs.aspectAngle, "")
    }

    func test_roundtrip_through_userdefaults_via_encoder() throws {
        // The cache writes via JSONEncoder and reads back via JSONDecoder.
        // Make sure a Codable roundtrip is lossless.
        let original = TopoSubstitutions(
            voidEndTimeIso: "2026-05-23T06:57:00Z",
            voidEndTime: "6:57 AM",
            aspectPartner: "Saturn",
            aspectType: "trine",
            aspectAngle: "120°",
            aspectOrbDegrees: 1.5,
            eclipseDistanceDays: 80,
            computedAtIso: "2026-05-21T20:23:46Z"
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TopoSubstitutions.self, from: encoded)
        XCTAssertEqual(original, decoded)
    }

    func test_current_returns_nil_when_cache_empty() {
        // Clear any pre-existing cache.
        UserDefaults.standard.removeObject(forKey: "topo.substitutions.cache.v1")
        UserDefaults.standard.removeObject(forKey: "topo.substitutions.dateKey.v1")
        XCTAssertNil(TopoSubstitutionsService.shared.current,
                     "current should be nil with no cached payload")
    }

    func test_current_returns_nil_when_cached_for_different_utc_day() throws {
        // Seed the cache with yesterday's date key. The service must reject it.
        let subs = TopoSubstitutions(
            voidEndTimeIso: "2026-05-23T06:57:00Z",
            voidEndTime: "6:57 AM",
            aspectPartner: "Sun",
            aspectType: "conjunction",
            aspectAngle: "0°",
            aspectOrbDegrees: 0.5,
            eclipseDistanceDays: 50,
            computedAtIso: "2026-05-21T20:23:46Z"
        )
        let data = try JSONEncoder().encode(subs)
        UserDefaults.standard.set(data, forKey: "topo.substitutions.cache.v1")
        UserDefaults.standard.set("1999-01-01", forKey: "topo.substitutions.dateKey.v1")

        XCTAssertNil(TopoSubstitutionsService.shared.current,
                     "current must reject cache from a different UTC day")
    }
}
