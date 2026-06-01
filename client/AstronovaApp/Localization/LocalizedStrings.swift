import Foundation

/// Centralized localization keys for type-safe access.
enum L10n {
    private static func tr(_ key: String, _ value: String, _ comment: String) -> String {
        NSLocalizedString(key, value: value, comment: comment)
    }

    enum Brand {
        static let name = tr("brand.name", "Astronova", "App name")
    }

    enum Tabs {
        static let discover = tr("tabs.discover", "Discover", "Discover tab title")
        static let timeTravel = tr("tabs.timeTravel", "Timeline", "Timeline tab title")
        static let connect = tr("tabs.connect", "Connect", "Connect tab title")
        static let profile = tr("tabs.self", "Self", "Self/profile tab title")

        static func positionHint(_ index: Int, _ total: Int) -> String {
            let format = tr("tabs.positionHint", "Tab %d of %d", "Tab position hint")
            return String.localizedStringWithFormat(format, index, total)
        }
    }

    enum Actions {
        static let save = tr("actions.save", "Save", "Save button")
        static let cancel = tr("actions.cancel", "Cancel", "Cancel button")
        static let delete = tr("actions.delete", "Delete", "Delete button")
        static let edit = tr("actions.edit", "Edit", "Edit button")
        static let done = tr("actions.done", "Done", "Done button")
        static let next = tr("actions.next", "Next", "Next button")
        static let back = tr("actions.back", "Back", "Back button")
        static let close = tr("actions.close", "Close", "Close button")
        static let continueLabel = tr("actions.continue", "Continue", "Continue button")
        static let ok = tr("actions.ok", "OK", "OK button")
        static let gotIt = tr("actions.gotIt", "Got it", "Acknowledgement button")
        static let dismiss = tr("actions.dismiss", "Dismiss", "Dismiss button")
        static let dismissHint = tr(
            "actions.dismissHint",
            "Dismisses this message",
            "Dismiss accessibility hint"
        )
    }

    enum Onboarding {
        static let progressTitle = tr(
            "onboarding.progress.title",
            "Creating Your Cosmic Profile",
            "Profile setup progress title"
        )
        static func progressStep(_ step: Int, _ total: Int) -> String {
            let format = tr("onboarding.progress.step", "Step %d of %d", "Profile setup step counter")
            return String.localizedStringWithFormat(format, step, total)
        }

        enum Actions {
            static let beginJourney = tr("onboarding.actions.beginJourney", "Begin Journey", "Onboarding start CTA")
            static let createProfile = tr("onboarding.actions.createProfile", "Create My Profile", "Profile creation CTA")
            static let skipForNow = tr("onboarding.actions.skipForNow", "Skip for Now", "Skip optional step")
        }

        enum Welcome {
            static let title = tr("onboarding.welcome.title", "Build your map", "Onboarding welcome title")
            static let subtitle = tr(
                "onboarding.welcome.subtitle",
                "Add just enough birth context to keep today's advice personal and recoverable.",
                "Onboarding welcome subtitle"
            )
        }

        enum Name {
            static let title = tr("onboarding.name.title", "What should we call you?", "Onboarding name title")
            static let subtitle = tr(
                "onboarding.name.subtitle",
                "Your name helps us create a personal connection with your cosmic journey.",
                "Onboarding name subtitle"
            )
            static let placeholder = tr("onboarding.name.placeholder", "Enter your name", "Onboarding name placeholder")
            static func success(_ firstName: String) -> String {
                let format = tr(
                    "onboarding.name.success",
                    "Perfect! The cosmos recognizes you, %@.",
                    "Onboarding name success message"
                )
                return String.localizedStringWithFormat(format, firstName)
            }
            static let errorTooShort = tr(
                "onboarding.name.error.tooShort",
                "Name must be at least 2 characters long",
                "Name validation error"
            )
            static let errorTooLong = tr(
                "onboarding.name.error.tooLong",
                "Name cannot exceed 50 characters",
                "Name validation error"
            )
            static let errorInvalidCharacters = tr(
                "onboarding.name.error.invalidCharacters",
                "Name can only contain letters, spaces, hyphens, and apostrophes",
                "Name validation error"
            )
            static let errorConsecutiveSpaces = tr(
                "onboarding.name.error.consecutiveSpaces",
                "Name cannot contain multiple consecutive spaces",
                "Name validation error"
            )
        }

        enum BirthDate {
            static let title = tr("onboarding.birthDate.title", "When were you born?", "Onboarding birth date title")
            static let subtitle = tr(
                "onboarding.birthDate.subtitle",
                "Your birth date reveals your sun sign and unlocks the cosmic blueprint of your personality.",
                "Onboarding birth date subtitle"
            )
            static func selected(_ date: String) -> String {
                let format = tr("onboarding.birthDate.selected", "Selected: %@", "Selected birth date label")
                return String.localizedStringWithFormat(format, date)
            }
            static let quickStart = tr("onboarding.birthDate.quickStart", "Quick Start", "Quick start CTA")
            static let skipDetails = tr("onboarding.birthDate.skipDetails", "Skip Details", "Skip details CTA")
            static let quickStartHint = tr(
                "onboarding.birthDate.quickStart.hint",
                "Start exploring with just your birth date. You can add birth time and location later for more precise readings.",
                "Quick start hint"
            )
            static let errorFuture = tr(
                "onboarding.birthDate.error.future",
                "Birth date cannot be in the future",
                "Birth date validation error"
            )
            static let errorTooOld = tr(
                "onboarding.birthDate.error.tooOld",
                "Birth date cannot be more than 120 years ago",
                "Birth date validation error"
            )
        }

        enum BirthTime {
            static let title = tr("onboarding.birthTime.title", "What time were you born?", "Onboarding birth time title")
            static let subtitle = tr(
                "onboarding.birthTime.subtitle",
                "Birth time improves rising sign and house calculations. If unknown, we'll assume 12:00 noon and mark some insights as approximate.",
                "Onboarding birth time subtitle"
            )
            static let unknownToggle = tr(
                "onboarding.birthTime.unknownToggle",
                "I don't know my birth time",
                "Birth time unknown toggle"
            )
            static let whyTitle = tr(
                "onboarding.birthTime.whyTitle",
                "Why birth time matters",
                "Birth time explanation title"
            )
            static let whyMessage = tr(
                "onboarding.birthTime.whyMessage",
                "Birth time helps calculate your rising sign and houses. If you don't know it, we'll default to 12:00 noon, and some insights may be approximate.",
                "Birth time explanation message"
            )
            static let assumedNoon = tr(
                "onboarding.birthTime.assumedNoon",
                "We'll assume 12:00 noon (approximate)",
                "Birth time default text"
            )
            static func selected(_ time: String) -> String {
                let format = tr("onboarding.birthTime.selected", "Selected: %@", "Selected birth time label")
                return String.localizedStringWithFormat(format, time)
            }
        }

        enum BirthPlace {
            static let title = tr("onboarding.birthPlace.title", "Where were you born?", "Onboarding birth place title")
            static let subtitle = tr(
                "onboarding.birthPlace.subtitle",
                "Your birth location helps us calculate precise celestial positions. You can add this later if you prefer to skip for now.",
                "Onboarding birth place subtitle"
            )
            static let placeholder = tr(
                "onboarding.birthPlace.placeholder",
                "City, State/Country",
                "Birth place placeholder"
            )
            static let validated = tr(
                "onboarding.birthPlace.validated",
                "Perfect! Location validated with coordinates.",
                "Birth place validated message"
            )
            static let dropdownHint = tr(
                "onboarding.birthPlace.dropdownHint",
                "Select a location from the dropdown for best results, or skip to add later.",
                "Birth place dropdown hint"
            )
            static let optionalHint = tr(
                "onboarding.birthPlace.optionalHint",
                "Birth location is optional - you can always add it later in your profile.",
                "Birth place optional hint"
            )
            static let searchPrompt = tr(
                "onboarding.birthPlace.searchPrompt",
                "Search for a city",
                "Birth place search prompt"
            )
            static let selectLocationTitle = tr(
                "onboarding.birthPlace.selectLocationTitle",
                "Select Location",
                "Birth place select location title"
            )
        }

        enum Insights {
            static let analyzingTitle = tr(
                "onboarding.insights.analyzingTitle",
                "Analyzing Your Cosmic Blueprint",
                "Onboarding analysis title"
            )
            static let analyzingSubtitle = tr(
                "onboarding.insights.analyzingSubtitle",
                "Reading planetary positions and celestial influences...",
                "Onboarding analysis subtitle"
            )
            static let profileCreated = tr(
                "onboarding.insights.profileCreated",
                "Profile Created!",
                "Profile created title"
            )
            static let welcomeGeneric = tr(
                "onboarding.insights.welcomeGeneric",
                "Welcome!",
                "Welcome without name"
            )
            static func welcomeName(_ name: String) -> String {
                let format = tr(
                    "onboarding.insights.welcomeName",
                    "Welcome, %@!",
                    "Welcome with name"
                )
                return String.localizedStringWithFormat(format, name)
            }
            static let startJourney = tr(
                "onboarding.insights.startJourney",
                "Start Your Journey",
                "Onboarding continue CTA"
            )
        }

        enum QuickStart {
            static func introWithName(_ name: String, _ birthDate: String) -> String {
                let format = tr(
                    "onboarding.quickStart.withName",
                    "%@, based on your birth date of %@, this is a starter insight. Add your birth time and place to unlock your full chart.",
                    "Quick start insight with name"
                )
                return String.localizedStringWithFormat(format, name, birthDate)
            }
            static func introWithoutName(_ birthDate: String) -> String {
                let format = tr(
                    "onboarding.quickStart.noName",
                    "Based on your birth date of %@, this is a starter insight. Add your birth time and place to unlock your full chart.",
                    "Quick start insight without name"
                )
                return String.localizedStringWithFormat(format, birthDate)
            }
        }

        enum Personalized {
            static let welcomeGeneric = tr(
                "onboarding.personalized.welcomeGeneric",
                "Welcome to your cosmic journey!",
                "Personalized insight welcome without name"
            )
            static func welcome(_ name: String) -> String {
                let format = tr(
                    "onboarding.personalized.welcome",
                    "Welcome to your cosmic journey, %@!",
                    "Personalized insight welcome with name"
                )
                return String.localizedStringWithFormat(format, name)
            }
            static func locationSuffix(_ location: String) -> String {
                let format = tr(
                    "onboarding.personalized.locationSuffix",
                    " in %@",
                    "Location suffix for personalized insight"
                )
                return String.localizedStringWithFormat(format, location)
            }
            static func birthDetails(_ date: String, _ time: String, _ location: String) -> String {
                let format = tr(
                    "onboarding.personalized.birthDetails",
                    "Born on %@ at %@%@, the stars reveal fascinating insights about your celestial blueprint.",
                    "Personalized insight birth details"
                )
                return String.localizedStringWithFormat(format, date, time, location)
            }
            static func sunMoon(_ sun: String, _ moon: String) -> String {
                let format = tr(
                    "onboarding.personalized.sunMoon",
                    "Your Sun in %@ illuminates your core identity, while your Moon in %@ reflects your emotional nature. This unique combination creates a personality that is both dynamic and deeply intuitive.",
                    "Personalized insight sun/moon summary"
                )
                return String.localizedStringWithFormat(format, sun, moon)
            }
            static let talents = tr(
                "onboarding.personalized.talents",
                "The planetary positions at your birth moment suggest you possess natural talents for leadership and creativity, with a special gift for understanding others' perspectives.",
                "Personalized insight talent summary"
            )
            static func offlineMessage(_ date: String, _ time: String, _ location: String) -> String {
                let format = tr(
                    "onboarding.personalized.offlineMessage",
                    "Your birth data has been recorded: %@ at %@%@. Connect to the internet to receive your personalized cosmic insights based on actual planetary positions at your time of birth.",
                    "Offline personalized insight message"
                )
                return String.localizedStringWithFormat(format, date, time, location)
            }
        }

        enum Errors {
            static func saveProfile(_ details: String) -> String {
                let format = tr(
                    "onboarding.errors.saveProfile",
                    "Failed to save profile: %@",
                    "Profile save error"
                )
                return String.localizedStringWithFormat(format, details)
            }
        }
    }

    enum Home {
        static let cosmicWeatherTitle = tr(
            "home.cosmicWeather.title",
            "Today's Cosmic Weather",
            "Daily cosmic weather card title"
        )

        static func cosmicWeatherDate(_ date: String) -> String {
            String.localizedStringWithFormat(
                tr(
                    "home.cosmicWeather.date",
                    "for %@",
                    "Cosmic weather date format"
                ),
                date
            )
        }

        enum Domains {
            static let personal = tr("home.domains.personal", "Personal", "Personal domain")
            static let love = tr("home.domains.love", "Love", "Love domain")
            static let career = tr("home.domains.career", "Career", "Career domain")
            static let wealth = tr("home.domains.wealth", "Wealth", "Wealth domain")
            static let health = tr("home.domains.health", "Health", "Health domain")
            static let family = tr("home.domains.family", "Family", "Family domain")
            static let spiritual = tr("home.domains.spiritual", "Spiritual", "Spiritual domain")
        }
    }

    enum Oracle {
        static let title = tr("oracle.title", "Oracle", "Oracle feature title")
        static let inputPlaceholder = tr(
            "oracle.input.placeholder",
            "Ask Oracle about your cosmic journey...",
            "Chat input placeholder"
        )
        static let sendButton = tr("oracle.send", "Send", "Send message button")
        static let typingIndicator = tr("oracle.typing", "Oracle is typing...", "Typing indicator")
        static let welcomeMessage = tr(
            "oracle.welcome",
            "The stars are aligned. What guidance do you seek?",
            "Oracle welcome message"
        )
        static let dailyLimitReached = tr(
            "oracle.limit.dailyComplete",
            "Daily reading complete",
            "Oracle daily limit reached"
        )
        static let signInRequired = tr(
            "oracle.signInRequired",
            "Sign in to ask the Oracle.",
            "Oracle sign-in required"
        )
        static let signInMessage = tr(
            "oracle.signInMessage",
            "Get personalized answers and save your readings.",
            "Oracle sign-in required message"
        )

        enum Packages {
            static let title = tr("oracle.packages.title", "Chat Packages", "Chat packages sheet title")

            static func messagesRemaining(_ count: Int) -> String {
                let format = tr(
                    "oracle.packages.remaining",
                    "%d messages remaining",
                    "Messages remaining format"
                )
                return String.localizedStringWithFormat(format, count)
            }
        }

        enum Prompts {
            static let energyToday = tr(
                "oracle.prompts.energyToday",
                "What energy surrounds me today?",
                "Oracle prompt"
            )
            static let highestPath = tr(
                "oracle.prompts.highestPath",
                "How can I align with my highest path?",
                "Oracle prompt"
            )
            static let influences = tr(
                "oracle.prompts.influences",
                "What planetary influences affect me?",
                "Oracle prompt"
            )
            static let focusNow = tr(
                "oracle.prompts.focusNow",
                "Where should I focus my energy now?",
                "Oracle prompt"
            )
        }

        enum Depth {
            static let quick = tr("oracle.depth.quick", "Quick", "Oracle depth: quick")
            static let deep = tr("oracle.depth.deep", "Deep", "Oracle depth: deep")
            static let quickDescription = tr(
                "oracle.depth.quickDescription",
                "Direct insight",
                "Oracle depth description"
            )
            static let deepDescription = tr(
                "oracle.depth.deepDescription",
                "Detailed analysis + timing",
                "Oracle depth description"
            )
            static let depthHint = tr(
                "oracle.depth.hint",
                "Double tap to choose depth",
                "Oracle depth accessibility hint"
            )
        }

        enum Accessibility {
            static let conversationLabel = tr(
                "oracle.accessibility.conversationLabel",
                "Chat conversation with Oracle",
                "Oracle chat accessibility label"
            )
            static let conversationHint = tr(
                "oracle.accessibility.conversationHint",
                "Scroll to view message history",
                "Oracle chat accessibility hint"
            )
            static let inputLabel = tr(
                "oracle.accessibility.inputLabel",
                "Message input field",
                "Oracle input accessibility label"
            )
            static let inputHint = tr(
                "oracle.accessibility.inputHint",
                "Type your question for the Oracle",
                "Oracle input accessibility hint"
            )
            static let sendHint = tr(
                "oracle.accessibility.sendHint",
                "Sends your question to the Oracle",
                "Oracle send accessibility hint"
            )
            static let depthLabel = tr(
                "oracle.accessibility.depthLabel",
                "Reading depth",
                "Oracle depth accessibility label"
            )
            static func messageLabel(isUser: Bool, message: String) -> String {
                let format = isUser
                    ? tr(
                        "oracle.accessibility.userMessage",
                        "You said: %@",
                        "Oracle user message accessibility label"
                    )
                    : tr(
                        "oracle.accessibility.oracleMessage",
                        "Oracle replied: %@",
                        "Oracle reply accessibility label"
                    )
                return String.localizedStringWithFormat(format, message)
            }
            static func promptLabel(_ prompt: String) -> String {
                let format = tr(
                    "oracle.accessibility.promptLabel",
                    "Suggested prompt: %@",
                    "Oracle prompt accessibility label"
                )
                return String.localizedStringWithFormat(format, prompt)
            }
            static let promptHint = tr(
                "oracle.accessibility.promptHint",
                "Inserts this prompt into the input field",
                "Oracle prompt accessibility hint"
            )
            static let typingLabel = tr(
                "oracle.accessibility.typingLabel",
                "Oracle is composing a response",
                "Oracle typing accessibility label"
            )
            static let closeHint = tr(
                "oracle.accessibility.closeHint",
                "Dismisses the Oracle",
                "Oracle close accessibility hint"
            )
        }

        enum Quota {
            static let dailyComplete = tr(
                "oracle.quota.dailyComplete",
                "Daily reading complete",
                "Oracle quota banner title"
            )
            static func nextInsight(_ countdown: String) -> String {
                let format = tr(
                    "oracle.quota.nextInsight",
                    "New insight in %@",
                    "Oracle quota countdown"
                )
                return String.localizedStringWithFormat(format, countdown)
            }
            static let getCredits = tr("oracle.quota.getCredits", "Get Credits", "Oracle quota CTA")
            static let unlockAll = tr("oracle.quota.unlockAll", "Unlock All", "Oracle quota CTA")
            static let getCreditsHint = tr(
                "oracle.quota.getCreditsHint",
                "Opens chat credit options",
                "Oracle quota CTA hint"
            )
            static let unlockAllHint = tr(
                "oracle.quota.unlockAllHint",
                "Opens the Pro subscription options",
                "Oracle quota CTA hint"
            )
        }
    }

    enum Connect {
        static let title = tr("connect.title", "Connect", "Connect tab title")
        static let addRelationship = tr("connect.add", "Add Relationship", "Add relationship button")
        static let emptyState = tr("connect.empty", "No relationships yet", "Empty state message")

        enum Compatibility {
            static func score(_ score: Int) -> String {
                let format = tr(
                    "connect.compatibility.score",
                    "%d%% compatibility",
                    "Compatibility score format"
                )
                return String.localizedStringWithFormat(format, score)
            }

            enum Pulse {
                static let flowing = tr("connect.pulse.flowing", "Flowing", "Relationship pulse: flowing")
                static let electric = tr("connect.pulse.electric", "Electric", "Relationship pulse: electric")
                static let magnetic = tr("connect.pulse.magnetic", "Magnetic", "Relationship pulse: magnetic")
                static let grounded = tr("connect.pulse.grounded", "Grounded", "Relationship pulse: grounded")
                static let friction = tr("connect.pulse.friction", "Friction", "Relationship pulse: friction")
            }
        }
    }

    enum Astrology {
        enum Signs {
            static let aries = tr("astrology.signs.aries", "Aries", "Zodiac sign: Aries")
            static let taurus = tr("astrology.signs.taurus", "Taurus", "Zodiac sign: Taurus")
            static let gemini = tr("astrology.signs.gemini", "Gemini", "Zodiac sign: Gemini")
            static let cancer = tr("astrology.signs.cancer", "Cancer", "Zodiac sign: Cancer")
            static let leo = tr("astrology.signs.leo", "Leo", "Zodiac sign: Leo")
            static let virgo = tr("astrology.signs.virgo", "Virgo", "Zodiac sign: Virgo")
            static let libra = tr("astrology.signs.libra", "Libra", "Zodiac sign: Libra")
            static let scorpio = tr("astrology.signs.scorpio", "Scorpio", "Zodiac sign: Scorpio")
            static let sagittarius = tr("astrology.signs.sagittarius", "Sagittarius", "Zodiac sign: Sagittarius")
            static let capricorn = tr("astrology.signs.capricorn", "Capricorn", "Zodiac sign: Capricorn")
            static let aquarius = tr("astrology.signs.aquarius", "Aquarius", "Zodiac sign: Aquarius")
            static let pisces = tr("astrology.signs.pisces", "Pisces", "Zodiac sign: Pisces")
        }

        enum Planets {
            static let sun = tr("astrology.planets.sun", "Sun", "Planet: Sun")
            static let moon = tr("astrology.planets.moon", "Moon", "Planet: Moon")
            static let mercury = tr("astrology.planets.mercury", "Mercury", "Planet: Mercury")
            static let venus = tr("astrology.planets.venus", "Venus", "Planet: Venus")
            static let mars = tr("astrology.planets.mars", "Mars", "Planet: Mars")
            static let jupiter = tr("astrology.planets.jupiter", "Jupiter", "Planet: Jupiter")
            static let saturn = tr("astrology.planets.saturn", "Saturn", "Planet: Saturn")
            static let rahu = tr("astrology.planets.rahu", "Rahu", "Planet: Rahu (North Node)")
            static let ketu = tr("astrology.planets.ketu", "Ketu", "Planet: Ketu (South Node)")
        }

        enum Dasha {
            static let mahadasha = tr("astrology.dasha.mahadasha", "Mahadasha", "Major period in Vimshottari Dasha")
            static let antardasha = tr(
                "astrology.dasha.antardasha",
                "Antardasha",
                "Sub-period in Vimshottari Dasha"
            )
            static let pratyantardasha = tr(
                "astrology.dasha.pratyantardasha",
                "Pratyantardasha",
                "Sub-sub-period in Vimshottari Dasha"
            )

            static func yearsFormat(_ years: Int) -> String {
                let format = tr("astrology.dasha.years", "%d years", "Dasha duration in years")
                return String.localizedStringWithFormat(format, years)
            }
        }

        enum Aspects {
            static let conjunction = tr("astrology.aspects.conjunction", "Conjunction", "Aspect: Conjunction")
            static let sextile = tr("astrology.aspects.sextile", "Sextile", "Aspect: Sextile")
            static let square = tr("astrology.aspects.square", "Square", "Aspect: Square")
            static let trine = tr("astrology.aspects.trine", "Trine", "Aspect: Trine")
            static let opposition = tr("astrology.aspects.opposition", "Opposition", "Aspect: Opposition")
        }
    }

    enum Errors {
        static let generic = tr(
            "errors.generic",
            "Something went wrong. Please try again.",
            "Generic error message"
        )
        static let network = tr(
            "errors.network",
            "Unable to connect. Check your internet connection.",
            "Network error"
        )
        static let noInternet = tr(
            "errors.noInternet",
            "No internet connection. Please try again.",
            "No internet error"
        )
        static let timeout = tr(
            "errors.timeout",
            "Request timed out. Please try again.",
            "Request timeout error"
        )
        static func serverError(_ code: Int) -> String {
            let format = tr(
                "errors.serverError",
                "Server error (%d). Please try again.",
                "Server error with status code"
            )
            return String.localizedStringWithFormat(format, code)
        }
        static let connectionInterrupted = tr(
            "errors.connectionInterrupted",
            "Connection interrupted",
            "Connection interrupted error"
        )
        static func accessibilityLabel(_ message: String) -> String {
            let format = tr(
                "errors.accessibilityLabel",
                "Error: %@",
                "Accessibility error label"
            )
            return String.localizedStringWithFormat(format, message)
        }
        static let unauthorized = tr("errors.unauthorized", "Please sign in to continue.", "Unauthorized error")
        static let notFound = tr("errors.notFound", "The requested resource was not found.", "Not found error")
    }

    enum DateTime {
        static let today = tr("datetime.today", "Today", "Today")
        static let tomorrow = tr("datetime.tomorrow", "Tomorrow", "Tomorrow")
        static let yesterday = tr("datetime.yesterday", "Yesterday", "Yesterday")
    }
}
