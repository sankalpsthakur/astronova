"""Constants for Vedic (sidereal) astrology calculations.

These are used for generating report-ready outputs with plain-language summaries.
"""

from __future__ import annotations

from services.dasha.constants import NAKSHATRA_RULERS

# Sidereal (Vedic) sign names (Lahiri ayanamsha).
VEDIC_SIGNS: list[str] = [
    "Mesha",
    "Vrishabha",
    "Mithuna",
    "Karka",
    "Simha",
    "Kanya",
    "Tula",
    "Vrischika",
    "Dhanu",
    "Makara",
    "Kumbha",
    "Meena",
]

VEDIC_SIGN_INDEX: dict[str, int] = {name: idx for idx, name in enumerate(VEDIC_SIGNS)}

VEDIC_SIGN_RULERS: dict[str, str] = {
    "Mesha": "Mars",
    "Vrishabha": "Venus",
    "Mithuna": "Mercury",
    "Karka": "Moon",
    "Simha": "Sun",
    "Kanya": "Mercury",
    "Tula": "Venus",
    "Vrischika": "Mars",
    "Dhanu": "Jupiter",
    "Makara": "Saturn",
    "Kumbha": "Saturn",
    "Meena": "Jupiter",
}

SIGN_ELEMENT: dict[str, str] = {
    "Mesha": "Fire",
    "Vrishabha": "Earth",
    "Mithuna": "Air",
    "Karka": "Water",
    "Simha": "Fire",
    "Kanya": "Earth",
    "Tula": "Air",
    "Vrischika": "Water",
    "Dhanu": "Fire",
    "Makara": "Earth",
    "Kumbha": "Air",
    "Meena": "Water",
}

# Used in divisional charts (Navamsa) and for layman explanations.
SIGN_MODALITY: dict[str, str] = {
    "Mesha": "Cardinal",
    "Vrishabha": "Fixed",
    "Mithuna": "Mutable",
    "Karka": "Cardinal",
    "Simha": "Fixed",
    "Kanya": "Mutable",
    "Tula": "Cardinal",
    "Vrischika": "Fixed",
    "Dhanu": "Mutable",
    "Makara": "Cardinal",
    "Kumbha": "Fixed",
    "Meena": "Mutable",
}

# Nakshatra constants (27 nakshatras of 13°20' each).
NAKSHATRA_SPAN_DEG = 13.333333333333334
NAKSHATRA_PADA_SPAN_DEG = NAKSHATRA_SPAN_DEG / 4

NAKSHATRA_NAMES: list[str] = [
    "Ashwini",
    "Bharani",
    "Krittika",
    "Rohini",
    "Mrigashira",
    "Ardra",
    "Punarvasu",
    "Pushya",
    "Ashlesha",
    "Magha",
    "Purva Phalguni",
    "Uttara Phalguni",
    "Hasta",
    "Chitra",
    "Swati",
    "Vishakha",
    "Anuradha",
    "Jyeshtha",
    "Mula",
    "Purva Ashadha",
    "Uttara Ashadha",
    "Shravana",
    "Dhanishta",
    "Shatabhisha",
    "Purva Bhadrapada",
    "Uttara Bhadrapada",
    "Revati",
]

# Lords in the same order as NAKSHATRA_NAMES.
NAKSHATRA_LORDS: list[str] = list(NAKSHATRA_RULERS)

NAKSHATRA_GANA: dict[str, str] = {
    # Traditional "temperament groups" used in matchmaking.
    # Deva = harmonious, Manushya = practical, Rakshasa = intense.
    "Ashwini": "Deva",
    "Bharani": "Manushya",
    "Krittika": "Rakshasa",
    "Rohini": "Manushya",
    "Mrigashira": "Deva",
    "Ardra": "Manushya",
    "Punarvasu": "Deva",
    "Pushya": "Deva",
    "Ashlesha": "Rakshasa",
    "Magha": "Rakshasa",
    "Purva Phalguni": "Manushya",
    "Uttara Phalguni": "Manushya",
    "Hasta": "Deva",
    "Chitra": "Rakshasa",
    "Swati": "Deva",
    "Vishakha": "Rakshasa",
    "Anuradha": "Deva",
    "Jyeshtha": "Rakshasa",
    "Mula": "Rakshasa",
    "Purva Ashadha": "Manushya",
    "Uttara Ashadha": "Manushya",
    "Shravana": "Deva",
    "Dhanishta": "Rakshasa",
    "Shatabhisha": "Rakshasa",
    "Purva Bhadrapada": "Manushya",
    "Uttara Bhadrapada": "Manushya",
    "Revati": "Deva",
}

NAKSHATRA_NADI: dict[str, str] = {
    # Traditional Nadi groups (Aadi/Vata, Madhya/Pitta, Antya/Kapha).
    "Ashwini": "Aadi",
    "Ardra": "Aadi",
    "Punarvasu": "Aadi",
    "Uttara Phalguni": "Aadi",
    "Hasta": "Aadi",
    "Jyeshtha": "Aadi",
    "Mula": "Aadi",
    "Shatabhisha": "Aadi",
    "Purva Bhadrapada": "Aadi",
    "Bharani": "Madhya",
    "Mrigashira": "Madhya",
    "Pushya": "Madhya",
    "Purva Phalguni": "Madhya",
    "Chitra": "Madhya",
    "Anuradha": "Madhya",
    "Purva Ashadha": "Madhya",
    "Dhanishta": "Madhya",
    "Uttara Bhadrapada": "Madhya",
    "Krittika": "Antya",
    "Rohini": "Antya",
    "Ashlesha": "Antya",
    "Magha": "Antya",
    "Swati": "Antya",
    "Vishakha": "Antya",
    "Uttara Ashadha": "Antya",
    "Shravana": "Antya",
    "Revati": "Antya",
}

NAKSHATRA_YONI: dict[str, str] = {
    # Traditional Yoni (animal archetype) used in matchmaking.
    "Ashwini": "Horse",
    "Bharani": "Elephant",
    "Krittika": "Sheep",
    "Rohini": "Serpent",
    "Mrigashira": "Serpent",
    "Ardra": "Dog",
    "Punarvasu": "Cat",
    "Pushya": "Sheep",
    "Ashlesha": "Cat",
    "Magha": "Rat",
    "Purva Phalguni": "Rat",
    "Uttara Phalguni": "Cow",
    "Hasta": "Buffalo",
    "Chitra": "Tiger",
    "Swati": "Buffalo",
    "Vishakha": "Tiger",
    "Anuradha": "Deer",
    "Jyeshtha": "Deer",
    "Mula": "Dog",
    "Purva Ashadha": "Monkey",
    "Uttara Ashadha": "Mongoose",
    "Shravana": "Monkey",
    "Dhanishta": "Lion",
    "Shatabhisha": "Horse",
    "Purva Bhadrapada": "Lion",
    "Uttara Bhadrapada": "Cow",
    "Revati": "Elephant",
}

# Varna (archetype) based on Moon sign in the traditional Varna Kuta table.
VARNA_BY_MOON_SIGN: dict[str, str] = {
    "Karka": "Brahmin",
    "Vrischika": "Brahmin",
    "Meena": "Brahmin",
    "Mesha": "Kshatriya",
    "Simha": "Kshatriya",
    "Dhanu": "Kshatriya",
    "Vrishabha": "Vaishya",
    "Kanya": "Vaishya",
    "Makara": "Vaishya",
    "Mithuna": "Shudra",
    "Tula": "Shudra",
    "Kumbha": "Shudra",
}

# Vashya group (traditional) based on Moon sign.
VASHYA_BY_MOON_SIGN: dict[str, str] = {
    "Mesha": "Chatushpada (Quadruped)",
    "Vrishabha": "Chatushpada (Quadruped)",
    "Mithuna": "Dwipada (Human)",
    "Karka": "Jalachara (Aquatic)",
    "Simha": "Vanachara (Wild)",
    "Kanya": "Dwipada (Human)",
    "Tula": "Dwipada (Human)",
    "Vrischika": "Keeta (Insect)",
    "Dhanu": "Dwipada (Human)",
    "Makara": "Chatushpada (Quadruped)",
    "Kumbha": "Dwipada (Human)",
    "Meena": "Jalachara (Aquatic)",
}

# Panchang names.
TITHI_NAMES: list[str] = [
    "Pratipada",
    "Dwitiya",
    "Tritiya",
    "Chaturthi",
    "Panchami",
    "Shashthi",
    "Saptami",
    "Ashtami",
    "Navami",
    "Dashami",
    "Ekadashi",
    "Dwadashi",
    "Trayodashi",
    "Chaturdashi",
    "Purnima/Amavasya",
]

YOGA_NAMES: list[str] = [
    "Vishkumbha",
    "Priti",
    "Ayushman",
    "Saubhagya",
    "Shobhana",
    "Atiganda",
    "Sukarma",
    "Dhriti",
    "Shoola",
    "Ganda",
    "Vriddhi",
    "Dhruva",
    "Vyaghata",
    "Harshana",
    "Vajra",
    "Siddhi",
    "Vyatipata",
    "Variyana",
    "Parigha",
    "Shiva",
    "Siddha",
    "Sadhya",
    "Shubha",
    "Shukla",
    "Brahma",
    "Indra",
    "Vaidhriti",
]

KARANA_MOVABLE: list[str] = [
    "Bava",
    "Balava",
    "Kaulava",
    "Taitila",
    "Garaja",
    "Vanija",
    "Vishti",
]

KARANA_FIXED: dict[int, str] = {
    0: "Kimstughna",
    57: "Shakuni",
    58: "Chatushpada",
    59: "Naga",
}

# Used to label houses in plain English.
HOUSE_MEANINGS: dict[int, str] = {
    1: "Self, body, vitality, identity, beginnings (Lagna).",
    2: "Wealth, speech, family, values, sustenance.",
    3: "Courage, effort, communication, siblings, skills.",
    4: "Home, mother, foundations, comfort, inner peace.",
    5: "Creativity, education, children, intelligence, romance.",
    6: "Health, service, debts, obstacles, daily routines.",
    7: "Partnership, marriage, contracts, public interactions.",
    8: "Transformation, longevity, secrets, shared resources.",
    9: "Dharma, luck, higher learning, mentors, long journeys.",
    10: "Career, status, actions, responsibility, reputation.",
    11: "Gains, networks, aspirations, friends, fulfillment.",
    12: "Release, spirituality, loss, foreign lands, rest.",
}

