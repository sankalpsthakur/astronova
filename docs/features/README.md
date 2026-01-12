# Feature Documentation

Detailed specifications and implementation status for Astronova features.

## Features

### [Compatibility Design Spec](./compatibility-design-spec.md)
Comprehensive design specification for the relationship compatibility feature including:
- Synastry calculations and algorithms
- Relationship pulse scoring
- Aspect analysis (conjunction, trine, square, opposition, sextile)
- Transit impact on relationships
- UI/UX design for compatibility views

**Status**: Implemented ✅

### [Temple Feature Status](./TEMPLE_FEATURE_STATUS.md)
Implementation status and details for the Temple/Pooja booking system:
- Pooja type catalog
- Pandit enrollment and management
- Booking workflow
- Video session integration
- Contact filtering and safety features
- Payment integration

**Status**: Implemented ✅

## Future Features

See [Planning Documents](../planning/) for upcoming feature work and backlogs.

## Implementation Resources

- **Compatibility**: `server/routes/compatibility.py`, `client/AstronovaApp/Features/Connect/`
- **Temple**: `server/routes/temple.py`, `client/AstronovaApp/Features/Temple/`
- **API Services**: `client/AstronovaApp/APIServices.swift`
