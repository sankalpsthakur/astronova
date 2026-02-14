# Astronova Documentation

This directory contains comprehensive documentation for the Astronova iOS app and Flask backend.

## 📁 Documentation Structure

```
docs/
├── architecture/          # System design and API documentation
├── features/             # Feature specifications and status
├── planning/             # Implementation backlogs and scope documents
├── testing/              # Test reports and accuracy benchmarks
├── ux/                   # UX analysis and journey documentation
└── development.md        # Development guide and setup instructions
```

## 🏗️ Architecture & API

Detailed system design, data flow, and API specifications.

| Document | Description |
|----------|-------------|
| [Architecture](./architecture/architecture.md) | System architecture, component overview, and data flow diagrams |
| [API Reference](./architecture/api-reference.md) | Complete REST API endpoint documentation with request/response examples |

## ✨ Features

Feature specifications and implementation status.

| Document | Description |
|----------|-------------|
| [Compatibility Design Spec](./features/compatibility-design-spec.md) | Relationship compatibility feature design and algorithms |
| [Temple Feature Status](./features/TEMPLE_FEATURE_STATUS.md) | Pooja booking and video session feature implementation status |
| **Gamification System** (Phase 4) | Seeker progression (Seeker → Alchemist → Oracle), XP economy, daily streaks, Sigils/Arcana cards, weekly challenges (Love/Career/Calm/Focus), journey milestones |
| **Time Travel Swarm Overlay** | Motion-reactive particle system with scrub-velocity feedback and dark-to-light visual bridge for immersive page transitions |
| **Temple Redesign** (Feb 2026) | Self-service spiritual tools: Temple Bell (rings with haptics), DIY Pooja builder, Muhurat calculator, Vedic Library. Replaced astrologer consultation/booking model |

## 📋 Planning & Backlogs

Implementation plans, scope of work, and task breakdowns.

| Document | Description |
|----------|-------------|
| [Accessibility Scope of Work](./planning/ACCESSIBILITY_SCOPE_OF_WORK.md) | Accessibility improvements and WCAG compliance plan |
| [Internationalization Scope of Work](./planning/INTERNATIONALIZATION_SCOPE_OF_WORK.md) | i18n/L10n implementation plan and requirements |
| [Compatibility Implementation Backlog](./planning/compatibility-implementation-backlog.md) | Detailed task breakdown for compatibility features |
| [Internationalization Implementation Backlog](./planning/internationalization-implementation-backlog.md) | i18n implementation task tracking |

## 🧪 Testing & Quality

Test reports, benchmarks, and quality assurance documentation.

| Document | Description |
|----------|-------------|
| [Test Report](./testing/TEST_REPORT.md) | Comprehensive test results and coverage reports |
| [E2E Test Report](./testing/E2E_TEST_REPORT.md) | End-to-end testing results and findings |
| [Fresh Build Test Report](./testing/FRESH_BUILD_TEST_REPORT.md) | Fresh build testing verification (latest) |
| [Astrology Accuracy](./testing/astrology-accuracy.md) | Quantitative accuracy benchmarks against Swiss Ephemeris |
| [Run Findings](./testing/run-findings.md) | Runtime testing findings and observations |

## 🎨 User Experience

UX analysis, journey mapping, and issue tracking.

| Document | Description |
|----------|-------------|
| [UX Gap Analysis](./ux/UX_GAP_ANALYSIS.md) | User experience analysis and improvement recommendations |
| [UX Journey E2E](./ux/ux-journey-e2e/) | User journey documentation with screenshots and issue logs |

## 🚀 Development

| Document | Description |
|----------|-------------|
| [Development Guide](./development.md) | Setup instructions, testing procedures, and contribution guidelines |

## 🔧 Operations

| Document | Description |
|----------|-------------|
| **Post-Deploy Verification** | Automated deployment health check via `scripts/deploy-post-push-check.sh` — validates API, auth, and core endpoints after Render deploy |

## 📚 Related Documentation

Key documentation files:

- [README.md](../README.md) — Project overview and quick start guide
- [CLAUDE.md](../CLAUDE.md) — Short index for AI assistants (full guide: `docs/claude/CLAUDE_FULL.md`)
- [CONTRIBUTING.md](./CONTRIBUTING.md) — Contribution guidelines and PR process

## 🏁 Getting Started

**For new contributors:**

1. **Start here**: [Development Guide](./development.md) for environment setup and build instructions
2. **Understand the system**: [Architecture](./architecture/architecture.md) for system design overview
3. **API development**: [API Reference](./architecture/api-reference.md) when working on endpoints
4. **Code conventions**: `docs/claude/CLAUDE_FULL.md`
5. **Testing**: [Test Report](./testing/TEST_REPORT.md) to understand test coverage and approach

**For product/design:**

1. [UX Gap Analysis](./ux/UX_GAP_ANALYSIS.md) — Current UX state and recommendations
2. [Feature Specifications](./features/) — Detailed feature designs and status
3. [Planning Documents](./planning/) — Upcoming work and scope definitions

**For QA/testing:**

1. [Test Reports](./testing/) — All test results and coverage metrics
2. [E2E Test Report](./testing/E2E_TEST_REPORT.md) — End-to-end test scenarios
3. [Astrology Accuracy](./testing/astrology-accuracy.md) — Accuracy benchmarks
