import Foundation
import CoreLocation

// MARK: - Astronomical Constants
struct AstronomicalConstants {
    static let J2000 = 2451545.0 // Julian Day for J2000.0 epoch (Jan 1, 2000, 12:00 UTC)
    static let daysPerCentury = 36525.0
    static let degreesPerHour = 15.0
    static let radiansPerDegree = Double.pi / 180.0
    static let degreesPerRadian = 180.0 / Double.pi
    static let obliquityAtJ2000 = 23.43929111 // Earth's axial tilt at J2000
    static let tropicalYear = 365.24219 // days
    static let lunarMonth = 29.530588 // days
    
    // Orbital elements at J2000.0 epoch
    static let planetaryElements: [String: OrbitalElements] = [
        "Mercury": OrbitalElements(
            a0: 0.38709927, a1: 0.00000037,
            e0: 0.20563593, e1: 0.00001906,
            i0: 7.00497902, i1: -0.00594749,
            L0: 252.25032350, L1: 149472.67411175,
            w0: 77.45779628, w1: 0.16047689,
            O0: 48.33076593, O1: -0.12534081
        ),
        "Venus": OrbitalElements(
            a0: 0.72333566, a1: 0.00000390,
            e0: 0.00677672, e1: -0.00004107,
            i0: 3.39467605, i1: -0.00078890,
            L0: 181.97909950, L1: 58517.81538729,
            w0: 131.60246718, w1: 0.00268329,
            O0: 76.67984255, O1: -0.27769418
        ),
        "Earth": OrbitalElements(
            a0: 1.00000261, a1: 0.00000562,
            e0: 0.01671123, e1: -0.00004392,
            i0: -0.00001531, i1: -0.01294668,
            L0: 100.46457166, L1: 35999.37244981,
            w0: 102.93768193, w1: 0.32327364,
            O0: 0.0, O1: 0.0
        ),
        "Mars": OrbitalElements(
            a0: 1.52371034, a1: 0.00001847,
            e0: 0.09339410, e1: 0.00007882,
            i0: 1.84969142, i1: -0.00813131,
            L0: -4.55343205, L1: 19140.30268499,
            w0: -23.94362959, w1: 0.44441088,
            O0: 49.55953891, O1: -0.29257343
        ),
        "Jupiter": OrbitalElements(
            a0: 5.20288700, a1: -0.00011607,
            e0: 0.04838624, e1: -0.00013253,
            i0: 1.30439695, i1: -0.00183714,
            L0: 34.39644051, L1: 3034.74612775,
            w0: 14.72847983, w1: 0.21252668,
            O0: 100.47390909, O1: 0.20469106
        ),
        "Saturn": OrbitalElements(
            a0: 9.53667594, a1: -0.00125060,
            e0: 0.05386179, e1: -0.00050991,
            i0: 2.48599187, i1: 0.00193609,
            L0: 49.95424423, L1: 1222.49362201,
            w0: 92.59887831, w1: -0.41897216,
            O0: 113.66242448, O1: -0.28867794
        ),
        "Uranus": OrbitalElements(
            a0: 19.18916464, a1: -0.00196176,
            e0: 0.04725744, e1: -0.00004397,
            i0: 0.77263783, i1: -0.00242939,
            L0: 313.23810451, L1: 428.48202785,
            w0: 170.95427630, w1: 0.40805281,
            O0: 74.01692503, O1: 0.04240589
        ),
        "Neptune": OrbitalElements(
            a0: 30.06992276, a1: 0.00026291,
            e0: 0.00859048, e1: 0.00005105,
            i0: 1.77004347, i1: 0.00035372,
            L0: -55.12002969, L1: 218.45945325,
            w0: 44.96476227, w1: -0.32241464,
            O0: 131.78422574, O1: -0.00508664
        )
    ]
}

// MARK: - Data Structures
struct OrbitalElements {
    let a0, a1: Double // Semi-major axis (AU)
    let e0, e1: Double // Eccentricity
    let i0, i1: Double // Inclination (degrees)
    let L0, L1: Double // Mean longitude (degrees)
    let w0, w1: Double // Longitude of perihelion (degrees)
    let O0, O1: Double // Longitude of ascending node (degrees)
}

struct EclipticCoordinates {
    let longitude: Double // degrees
    let latitude: Double  // degrees
    let distance: Double  // AU
}

struct EquatorialCoordinates {
    let rightAscension: Double // hours
    let declination: Double    // degrees
}

struct HorizontalCoordinates {
    let azimuth: Double   // degrees from North
    let altitude: Double  // degrees above horizon
}

// MARK: - Core Astronomical Calculations
class AstronomicalCalculator {
    
    // MARK: - Time Conversions
    
    /// Convert date to Julian Day Number
    static func julianDay(from date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let year = Double(components.year!)
        let month = Double(components.month!)
        let day = Double(components.day!)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        
        let a = floor((14 - month) / 12)
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        
        var jd = day + floor((153 * m + 2) / 5) + 365 * y + floor(y / 4) - floor(y / 100) + floor(y / 400) - 32045
        
        // Add fractional day
        jd += (hour - 12) / 24.0 + minute / 1440.0 + second / 86400.0
        
        return jd
    }
    
    /// Convert Julian Day to centuries since J2000.0
    static func centuriesSinceJ2000(julianDay: Double) -> Double {
        return (julianDay - AstronomicalConstants.J2000) / AstronomicalConstants.daysPerCentury
    }
    
    /// Calculate Greenwich Mean Sidereal Time
    static func greenwichMeanSiderealTime(julianDay: Double) -> Double {
        let T = centuriesSinceJ2000(julianDay: julianDay)
        
        // GMST at 0h UT
        var gmst = 280.46061837 + 360.98564736629 * (julianDay - AstronomicalConstants.J2000)
        gmst += T * T * (0.000387933 - T / 38710000.0)
        
        // Normalize to 0-360 degrees
        gmst = normalizeAngle(gmst)
        
        // Convert to hours
        return gmst / AstronomicalConstants.degreesPerHour
    }
    
    /// Calculate Local Sidereal Time
    static func localSiderealTime(julianDay: Double, longitude: Double) -> Double {
        let gmst = greenwichMeanSiderealTime(julianDay: julianDay)
        let lst = gmst + longitude / AstronomicalConstants.degreesPerHour
        return normalizeHour(lst)
    }
    
    // MARK: - Planetary Position Calculations
    
    /// Calculate heliocentric position of a planet
    static func calculatePlanetPosition(planetName: String, julianDay: Double) -> EclipticCoordinates? {
        guard let elements = AstronomicalConstants.planetaryElements[planetName] else { return nil }
        
        let T = centuriesSinceJ2000(julianDay: julianDay)
        
        // Calculate orbital elements at given time
        let a = elements.a0 + elements.a1 * T
        let e = elements.e0 + elements.e1 * T
        let i = elements.i0 + elements.i1 * T
        let L = normalizeAngle(elements.L0 + elements.L1 * T)
        let w = normalizeAngle(elements.w0 + elements.w1 * T)
        let O = normalizeAngle(elements.O0 + elements.O1 * T)
        
        // Calculate mean anomaly
        let M = normalizeAngle(L - w)
        
        // Solve Kepler's equation for eccentric anomaly
        let E = solveKeplersEquation(M: M * AstronomicalConstants.radiansPerDegree, e: e)
        
        // Calculate true anomaly
        let v = 2.0 * atan(sqrt((1 + e) / (1 - e)) * tan(E / 2))
        
        // Calculate distance
        let r = a * (1 - e * cos(E))
        
        // Calculate heliocentric ecliptic coordinates
        let xh = r * (cos(O * AstronomicalConstants.radiansPerDegree) * cos((v + w - O) * AstronomicalConstants.radiansPerDegree) - sin(O * AstronomicalConstants.radiansPerDegree) * sin((v + w - O) * AstronomicalConstants.radiansPerDegree) * cos(i * AstronomicalConstants.radiansPerDegree))
        let yh = r * (sin(O * AstronomicalConstants.radiansPerDegree) * cos((v + w - O) * AstronomicalConstants.radiansPerDegree) + cos(O * AstronomicalConstants.radiansPerDegree) * sin((v + w - O) * AstronomicalConstants.radiansPerDegree) * cos(i * AstronomicalConstants.radiansPerDegree))
        let zh = r * sin((v + w - O) * AstronomicalConstants.radiansPerDegree) * sin(i * AstronomicalConstants.radiansPerDegree)
        
        // Convert to geocentric coordinates if not Earth
        if planetName != "Earth" {
            // Get Earth's position
            guard let earthPos = calculatePlanetPosition(planetName: "Earth", julianDay: julianDay) else { return nil }
            let earthX = earthPos.distance * cos(earthPos.longitude * AstronomicalConstants.radiansPerDegree) * cos(earthPos.latitude * AstronomicalConstants.radiansPerDegree)
            let earthY = earthPos.distance * sin(earthPos.longitude * AstronomicalConstants.radiansPerDegree) * cos(earthPos.latitude * AstronomicalConstants.radiansPerDegree)
            let earthZ = earthPos.distance * sin(earthPos.latitude * AstronomicalConstants.radiansPerDegree)
            
            // Geocentric position
            let xg = xh - earthX
            let yg = yh - earthY
            let zg = zh - earthZ
            
            // Convert to longitude and latitude
            let distance = sqrt(xg * xg + yg * yg + zg * zg)
            let longitude = normalizeAngle(atan2(yg, xg) * AstronomicalConstants.degreesPerRadian)
            let latitude = asin(zg / distance) * AstronomicalConstants.degreesPerRadian
            
            return EclipticCoordinates(longitude: longitude, latitude: latitude, distance: distance)
        } else {
            // For Earth, return heliocentric coordinates
            let longitude = normalizeAngle(atan2(yh, xh) * AstronomicalConstants.degreesPerRadian)
            let latitude = asin(zh / r) * AstronomicalConstants.degreesPerRadian
            return EclipticCoordinates(longitude: longitude, latitude: latitude, distance: r)
        }
    }
    
    /// Calculate Sun position (simplified)
    static func calculateSunPosition(julianDay: Double) -> EclipticCoordinates {
        let T = centuriesSinceJ2000(julianDay: julianDay)
        
        // Mean longitude of Sun
        let L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T
        
        // Mean anomaly of Sun
        let M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
        let M_rad = M * AstronomicalConstants.radiansPerDegree
        
        // Equation of center
        let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(M_rad)
        + (0.019993 - 0.000101 * T) * sin(2 * M_rad)
        + 0.000289 * sin(3 * M_rad)
        
        // True longitude
        let longitude = normalizeAngle(L0 + C)
        
        // Distance in AU
        let e = 0.016708634 - 0.000042037 * T - 0.0000001267 * T * T
        let v = M + C
        let distance = (1.000001018 * (1 - e * e)) / (1 + e * cos(v * AstronomicalConstants.radiansPerDegree))
        
        return EclipticCoordinates(longitude: longitude, latitude: 0.0, distance: distance)
    }
    
    /// Calculate Moon position
    static func calculateMoonPosition(julianDay: Double) -> EclipticCoordinates {
        let T = centuriesSinceJ2000(julianDay: julianDay)
        
        // Moon's mean longitude
        let L = 218.316 + 13.176396 * (julianDay - AstronomicalConstants.J2000)
        
        // Moon's mean anomaly
        let M = 134.963 + 13.064993 * (julianDay - AstronomicalConstants.J2000)
        
        // Moon's mean distance
        let F = 93.272 + 13.229350 * (julianDay - AstronomicalConstants.J2000)
        
        let L_rad = normalizeAngle(L) * AstronomicalConstants.radiansPerDegree
        let M_rad = normalizeAngle(M) * AstronomicalConstants.radiansPerDegree
        let F_rad = normalizeAngle(F) * AstronomicalConstants.radiansPerDegree
        
        // Longitude correction
        let dL = 6.289 * sin(M_rad)
        + 1.274 * sin(2 * F_rad - M_rad)
        + 0.658 * sin(2 * F_rad)
        + 0.214 * sin(2 * M_rad)
        - 0.186 * sin(M_rad - 2 * F_rad)
        - 0.114 * sin(2 * F_rad)
        
        // Latitude correction
        let dB = 5.128 * sin(F_rad)
        + 0.281 * sin(M_rad + F_rad)
        - 0.280 * sin(F_rad - M_rad)
        - 0.173 * sin(F_rad - 2 * F_rad)
        
        let longitude = normalizeAngle(L + dL)
        let latitude = dB
        let distance = 385000.56 / 149597870.7 // Convert km to AU
        
        return EclipticCoordinates(longitude: longitude, latitude: latitude, distance: distance)
    }
    
    // MARK: - Coordinate Transformations
    
    /// Convert ecliptic to equatorial coordinates
    static func eclipticToEquatorial(ecliptic: EclipticCoordinates, julianDay: Double) -> EquatorialCoordinates {
        let T = centuriesSinceJ2000(julianDay: julianDay)
        
        // Mean obliquity of ecliptic
        let epsilon = AstronomicalConstants.obliquityAtJ2000
        - 0.00059 * T
        - 0.00183 * T * T
        
        let epsilon_rad = epsilon * AstronomicalConstants.radiansPerDegree
        let lambda_rad = ecliptic.longitude * AstronomicalConstants.radiansPerDegree
        let beta_rad = ecliptic.latitude * AstronomicalConstants.radiansPerDegree
        
        // Calculate right ascension
        let ra = atan2(
            sin(lambda_rad) * cos(epsilon_rad) - tan(beta_rad) * sin(epsilon_rad),
            cos(lambda_rad)
        )
        
        // Calculate declination
        let dec = asin(
            sin(beta_rad) * cos(epsilon_rad) + cos(beta_rad) * sin(epsilon_rad) * sin(lambda_rad)
        )
        
        let rightAscension = normalizeAngle(ra * AstronomicalConstants.degreesPerRadian) / AstronomicalConstants.degreesPerHour
        let declination = dec * AstronomicalConstants.degreesPerRadian
        
        return EquatorialCoordinates(rightAscension: rightAscension, declination: declination)
    }
    
    /// Convert equatorial to horizontal coordinates
    static func equatorialToHorizontal(equatorial: EquatorialCoordinates, latitude: Double, lst: Double) -> HorizontalCoordinates {
        let ha = (lst - equatorial.rightAscension) * AstronomicalConstants.degreesPerHour
        let ha_rad = ha * AstronomicalConstants.radiansPerDegree
        let dec_rad = equatorial.declination * AstronomicalConstants.radiansPerDegree
        let lat_rad = latitude * AstronomicalConstants.radiansPerDegree
        
        // Calculate altitude
        let alt = asin(
            sin(dec_rad) * sin(lat_rad) + cos(dec_rad) * cos(lat_rad) * cos(ha_rad)
        )
        
        // Calculate azimuth
        let az = atan2(
            -sin(ha_rad),
            tan(dec_rad) * cos(lat_rad) - sin(lat_rad) * cos(ha_rad)
        )
        
        let altitude = alt * AstronomicalConstants.degreesPerRadian
        let azimuth = normalizeAngle(az * AstronomicalConstants.degreesPerRadian + 180.0)
        
        return HorizontalCoordinates(azimuth: azimuth, altitude: altitude)
    }
    
    // MARK: - House Calculations (Placidus System)
    
    /// Calculate house cusps using Placidus system
    static func calculateHouseCusps(julianDay: Double, latitude: Double, longitude: Double) -> [Double] {
        let lst = localSiderealTime(julianDay: julianDay, longitude: longitude)
        let lst_rad = lst * AstronomicalConstants.degreesPerHour * AstronomicalConstants.radiansPerDegree
        let lat_rad = latitude * AstronomicalConstants.radiansPerDegree
        
        // Calculate MC (Medium Coeli) and IC
        let mc = lst * AstronomicalConstants.degreesPerHour
        let ic = normalizeAngle(mc + 180.0)
        
        // Calculate Ascendant
        let tanAsc = -cos(lst_rad) / (sin(lst_rad) * cos(AstronomicalConstants.obliquityAtJ2000 * AstronomicalConstants.radiansPerDegree) + tan(lat_rad) * sin(AstronomicalConstants.obliquityAtJ2000 * AstronomicalConstants.radiansPerDegree))
        let asc = normalizeAngle(atan(tanAsc) * AstronomicalConstants.degreesPerRadian + 180.0)
        let dsc = normalizeAngle(asc + 180.0)
        
        // Calculate intermediate house cusps (simplified Placidus)
        var cusps = [Double](repeating: 0, count: 12)
        
        // Angular houses
        cusps[0] = asc  // 1st house (Ascendant)
        cusps[3] = ic   // 4th house (IC)
        cusps[6] = dsc  // 7th house (Descendant)
        cusps[9] = mc   // 10th house (MC)
        
        // Calculate intermediate cusps using trisection
        // Houses 11, 12
        let arc1 = normalizeAngle(mc - asc)
        cusps[10] = normalizeAngle(asc + arc1 / 3.0)      // 11th house
        cusps[11] = normalizeAngle(asc + 2.0 * arc1 / 3.0) // 12th house
        
        // Houses 2, 3
        let arc2 = normalizeAngle(ic - asc)
        cusps[1] = normalizeAngle(asc + arc2 / 3.0)       // 2nd house
        cusps[2] = normalizeAngle(asc + 2.0 * arc2 / 3.0)  // 3rd house
        
        // Houses 5, 6
        let arc3 = normalizeAngle(dsc - ic)
        cusps[4] = normalizeAngle(ic + arc3 / 3.0)        // 5th house
        cusps[5] = normalizeAngle(ic + 2.0 * arc3 / 3.0)   // 6th house
        
        // Houses 8, 9
        let arc4 = normalizeAngle(mc - dsc)
        cusps[7] = normalizeAngle(dsc + arc4 / 3.0)       // 8th house
        cusps[8] = normalizeAngle(dsc + 2.0 * arc4 / 3.0)  // 9th house
        
        return cusps
    }
    
    /// Determine which house a planet is in
    static func getHousePosition(planetLongitude: Double, houseCusps: [Double]) -> Int {
        let normalizedLongitude = normalizeAngle(planetLongitude)
        
        for i in 0..<12 {
            let currentCusp = houseCusps[i]
            let nextCusp = houseCusps[(i + 1) % 12]
            
            if currentCusp < nextCusp {
                if normalizedLongitude >= currentCusp && normalizedLongitude < nextCusp {
                    return i + 1
                }
            } else {
                // Handle wrap around 0/360 degrees
                if normalizedLongitude >= currentCusp || normalizedLongitude < nextCusp {
                    return i + 1
                }
            }
        }
        
        return 1 // Default to 1st house
    }
    
    // MARK: - Helper Functions
    
    /// Solve Kepler's equation using Newton-Raphson method
    private static func solveKeplersEquation(M: Double, e: Double, tolerance: Double = 1e-8) -> Double {
        var E = M // Initial guess
        var delta = 1.0
        
        while abs(delta) > tolerance {
            delta = (E - e * sin(E) - M) / (1 - e * cos(E))
            E -= delta
        }
        
        return E
    }
    
    /// Normalize angle to 0-360 degrees
    static func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: 360.0)
        if normalized < 0 {
            normalized += 360.0
        }
        return normalized
    }
    
    /// Normalize hour to 0-24
    static func normalizeHour(_ hour: Double) -> Double {
        var normalized = hour.truncatingRemainder(dividingBy: 24.0)
        if normalized < 0 {
            normalized += 24.0
        }
        return normalized
    }
    
    /// Get zodiac sign from ecliptic longitude
    static func getZodiacSign(longitude: Double) -> String {
        let signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
        let index = Int(normalizeAngle(longitude) / 30.0)
        return signs[index]
    }
    
    /// Get degree within sign (0-30)
    static func getDegreeInSign(longitude: Double) -> Double {
        return normalizeAngle(longitude).truncatingRemainder(dividingBy: 30.0)
    }
}

// MARK: - Astronomical Phenomena Calculations

extension AstronomicalCalculator {
    
    /// Calculate planetary aspects
    static func calculateAspects(positions: [String: EclipticCoordinates]) -> [(planet1: String, planet2: String, aspect: String, orb: Double)] {
        let aspectAngles: [(name: String, angle: Double, orb: Double)] = [
            ("Conjunction", 0, 8),
            ("Sextile", 60, 6),
            ("Square", 90, 8),
            ("Trine", 120, 8),
            ("Opposition", 180, 8)
        ]
        
        var aspects: [(planet1: String, planet2: String, aspect: String, orb: Double)] = []
        let planets = Array(positions.keys).sorted()
        
        for i in 0..<planets.count {
            for j in (i+1)..<planets.count {
                let planet1 = planets[i]
                let planet2 = planets[j]
                
                guard let pos1 = positions[planet1], let pos2 = positions[planet2] else { continue }
                
                let angle = abs(pos1.longitude - pos2.longitude)
                let normalizedAngle = min(angle, 360 - angle)
                
                for aspectInfo in aspectAngles {
                    let orb = abs(normalizedAngle - aspectInfo.angle)
                    if orb <= aspectInfo.orb {
                        aspects.append((planet1: planet1, planet2: planet2, aspect: aspectInfo.name, orb: orb))
                        break
                    }
                }
            }
        }
        
        return aspects
    }
    
    /// Check if planet is retrograde
    static func isRetrograde(planetName: String, julianDay: Double) -> Bool {
        // Calculate positions for today and tomorrow
        guard let todayPos = calculatePlanetPosition(planetName: planetName, julianDay: julianDay),
              let tomorrowPos = calculatePlanetPosition(planetName: planetName, julianDay: julianDay + 1) else {
            return false
        }
        
        // If longitude decreases, planet is retrograde
        let motion = tomorrowPos.longitude - todayPos.longitude
        
        // Handle wrap around 360 degrees
        if motion < -180 {
            return false // Direct motion across 0/360
        } else if motion > 180 {
            return true  // Retrograde motion across 0/360
        } else {
            return motion < 0 // Normal case
        }
    }
    
    /// Calculate exact zodiac position with sign, degree, minute
    static func getExactZodiacPosition(longitude: Double) -> (sign: String, degrees: Int, minutes: Int) {
        let sign = getZodiacSign(longitude: longitude)
        let degreeInSign = getDegreeInSign(longitude: longitude)
        let degrees = Int(degreeInSign)
        let minutes = Int((degreeInSign - Double(degrees)) * 60)
        
        return (sign: sign, degrees: degrees, minutes: minutes)
    }
}