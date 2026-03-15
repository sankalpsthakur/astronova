"""
Planet-in-House interpretation data for the Time Travel feature.

Provides rich Vedic astrology (Jyotish) interpretations for each of the
9 Vedic planets placed in each of the 12 houses (108 combinations),
plus retrograde modifiers and helper functions for the mobile UI.
"""

# ---------------------------------------------------------------------------
# 1. HOUSE_MEANINGS — 12 Bhava descriptions
# ---------------------------------------------------------------------------

HOUSE_MEANINGS = {
    1: {
        "name": "1st House (Lagna)",
        "theme": "Self & Identity",
        "keywords": ["self", "body", "vitality", "personality"],
        "description": (
            "The ascendant represents your physical constitution, personality, "
            "and how the world perceives you. It is the seed of the entire chart."
        ),
        "lifeAreas": ["health", "appearance", "temperament", "first impressions"],
    },
    2: {
        "name": "2nd House (Dhana)",
        "theme": "Wealth & Family",
        "keywords": ["wealth", "speech", "family", "values"],
        "description": (
            "Governs accumulated wealth, family lineage, speech, and food habits. "
            "It reflects your relationship with material security."
        ),
        "lifeAreas": ["finances", "family bonds", "diet", "early education"],
    },
    3: {
        "name": "3rd House (Sahaja)",
        "theme": "Courage & Communication",
        "keywords": ["courage", "siblings", "communication", "skills"],
        "description": (
            "The house of self-effort, short journeys, and artistic expression. "
            "It shows your willpower and ability to take initiative."
        ),
        "lifeAreas": ["siblings", "writing", "short travel", "hobbies"],
    },
    4: {
        "name": "4th House (Sukha)",
        "theme": "Home & Inner Peace",
        "keywords": ["home", "mother", "comfort", "emotions"],
        "description": (
            "Represents domestic happiness, mother, vehicles, and property. "
            "It indicates your emotional foundation and sense of belonging."
        ),
        "lifeAreas": ["home life", "mother", "property", "education"],
    },
    5: {
        "name": "5th House (Putra)",
        "theme": "Creativity & Intelligence",
        "keywords": ["creativity", "children", "romance", "intellect"],
        "description": (
            "The house of Poorva Punya (past-life merit), governing children, "
            "creative expression, education, and speculative ventures."
        ),
        "lifeAreas": ["children", "romance", "education", "investments"],
    },
    6: {
        "name": "6th House (Ripu)",
        "theme": "Health & Service",
        "keywords": ["health", "service", "enemies", "obstacles"],
        "description": (
            "Governs disease, debts, enemies, and daily service. "
            "A strong 6th house grants the ability to overcome adversity."
        ),
        "lifeAreas": ["health", "daily work", "legal disputes", "pets"],
    },
    7: {
        "name": "7th House (Kalatra)",
        "theme": "Partnership & Marriage",
        "keywords": ["marriage", "partnership", "contracts", "public"],
        "description": (
            "The house of spouse, business partnerships, and public dealings. "
            "It reflects how you relate one-on-one with others."
        ),
        "lifeAreas": ["marriage", "business partners", "contracts", "open enemies"],
    },
    8: {
        "name": "8th House (Randhra)",
        "theme": "Transformation & Mystery",
        "keywords": ["transformation", "longevity", "secrets", "occult"],
        "description": (
            "Governs sudden events, inheritance, hidden knowledge, and lifespan. "
            "It is the house of deep research and psychological depth."
        ),
        "lifeAreas": ["inheritance", "surgery", "research", "spouse's wealth"],
    },
    9: {
        "name": "9th House (Dharma)",
        "theme": "Fortune & Higher Wisdom",
        "keywords": ["dharma", "luck", "guru", "pilgrimage"],
        "description": (
            "The most auspicious trikona, representing father, guru, higher "
            "learning, and long-distance travel. It shows your Bhagya (fortune)."
        ),
        "lifeAreas": ["father", "higher education", "religion", "long travel"],
    },
    10: {
        "name": "10th House (Karma)",
        "theme": "Career & Public Life",
        "keywords": ["career", "status", "authority", "reputation"],
        "description": (
            "The zenith of the chart, governing profession, public status, and "
            "your visible contribution to society. It shows your Karma in action."
        ),
        "lifeAreas": ["profession", "government", "fame", "achievements"],
    },
    11: {
        "name": "11th House (Labha)",
        "theme": "Gains & Aspirations",
        "keywords": ["gains", "friends", "networks", "fulfillment"],
        "description": (
            "The house of income, social circles, elder siblings, and the "
            "fulfillment of desires. Planets here tend to give material results."
        ),
        "lifeAreas": ["income", "friendships", "elder siblings", "goals"],
    },
    12: {
        "name": "12th House (Vyaya)",
        "theme": "Liberation & Letting Go",
        "keywords": ["spirituality", "loss", "foreign lands", "moksha"],
        "description": (
            "Governs expenses, isolation, foreign residence, and final liberation. "
            "It is the house of surrender, sleep, and the subconscious."
        ),
        "lifeAreas": ["spirituality", "foreign settlement", "expenditure", "sleep"],
    },
}

# ---------------------------------------------------------------------------
# 2. PLANET_SIGNIFICATIONS — 9 Vedic Grahas
# ---------------------------------------------------------------------------

PLANET_SIGNIFICATIONS = {
    "Sun": {
        "name": "Sun (Surya)",
        "symbol": "\u2609",
        "keywords": ["authority", "vitality", "ego", "father"],
        "nature": "malefic",
        "element": "fire",
        "description": (
            "The Atmakaraka, representing the soul, willpower, government, "
            "and the father in Vedic astrology."
        ),
    },
    "Moon": {
        "name": "Moon (Chandra)",
        "symbol": "\u263D",
        "keywords": ["emotions", "mind", "mother", "nurturing"],
        "nature": "benefic",
        "element": "water",
        "description": (
            "Ruler of the mind and emotions, the Moon governs intuition, "
            "fertility, and our deepest sense of comfort."
        ),
    },
    "Mars": {
        "name": "Mars (Mangal)",
        "symbol": "\u2642",
        "keywords": ["energy", "courage", "action", "conflict"],
        "nature": "malefic",
        "element": "fire",
        "description": (
            "The planet of action and valor, Mars drives ambition, physical "
            "strength, and the warrior spirit."
        ),
    },
    "Mercury": {
        "name": "Mercury (Budha)",
        "symbol": "\u263F",
        "keywords": ["intellect", "communication", "commerce", "learning"],
        "nature": "neutral",
        "element": "earth",
        "description": (
            "The prince among planets, Mercury governs speech, analytical "
            "thinking, trade, and youthful curiosity."
        ),
    },
    "Jupiter": {
        "name": "Jupiter (Guru)",
        "symbol": "\u2643",
        "keywords": ["wisdom", "expansion", "fortune", "dharma"],
        "nature": "benefic",
        "element": "ether",
        "description": (
            "The great benefic and divine teacher, Jupiter bestows knowledge, "
            "prosperity, children, and spiritual grace."
        ),
    },
    "Venus": {
        "name": "Venus (Shukra)",
        "symbol": "\u2640",
        "keywords": ["love", "beauty", "harmony", "luxury"],
        "nature": "benefic",
        "element": "water",
        "description": (
            "Guru of the Asuras, Venus governs romance, artistic talent, "
            "material comforts, and the refined pleasures of life."
        ),
    },
    "Saturn": {
        "name": "Saturn (Shani)",
        "symbol": "\u2644",
        "keywords": ["discipline", "karma", "restriction", "endurance"],
        "nature": "malefic",
        "element": "air",
        "description": (
            "The great taskmaster, Saturn teaches through delay and hardship, "
            "rewarding patience, humility, and persistent effort."
        ),
    },
    "Rahu": {
        "name": "Rahu (North Node)",
        "symbol": "\u260A",
        "keywords": ["ambition", "illusion", "obsession", "foreignness"],
        "nature": "malefic",
        "element": "air",
        "description": (
            "The shadow planet of worldly desire, Rahu amplifies material "
            "hunger, unconventional paths, and karmic lessons through excess."
        ),
    },
    "Ketu": {
        "name": "Ketu (South Node)",
        "symbol": "\u260B",
        "keywords": ["detachment", "spirituality", "liberation", "past life"],
        "nature": "malefic",
        "element": "fire",
        "description": (
            "The moksha-karaka, Ketu strips away worldly attachment, "
            "directing the soul toward spiritual insight and liberation."
        ),
    },
}

# ---------------------------------------------------------------------------
# 3. PLANET_IN_HOUSE — 108 interpretations (9 planets x 12 houses)
# ---------------------------------------------------------------------------

PLANET_IN_HOUSE = {
    # -----------------------------------------------------------------------
    # SUN in houses 1-12
    # -----------------------------------------------------------------------
    ("Sun", 1): {
        "summary": "Sun in 1st House: Strong personality, natural leadership, and robust vitality.",
        "strengths": ["commanding presence", "self-confidence", "strong willpower"],
        "challenges": ["ego dominance", "self-centeredness"],
        "lifeArea": "identity",
    },
    ("Sun", 2): {
        "summary": "Sun in 2nd House: Wealth through authority, powerful speech, pride in family lineage.",
        "strengths": ["authoritative speech", "steady income from government or leadership roles", "strong family values"],
        "challenges": ["harsh or dominating speech", "conflicts over family wealth"],
        "lifeArea": "finances",
    },
    ("Sun", 3): {
        "summary": "Sun in 3rd House: Courageous initiative, influential communication, leadership among siblings.",
        "strengths": ["bold self-expression", "creative writing ability", "entrepreneurial drive"],
        "challenges": ["strained sibling relations", "overbearing communication style"],
        "lifeArea": "communication",
    },
    ("Sun", 4): {
        "summary": "Sun in 4th House: Pride in home and heritage, authoritative parent, government property connections.",
        "strengths": ["strong domestic foundation", "property acquisition", "educational achievement"],
        "challenges": ["dominating home atmosphere", "tension with mother"],
        "lifeArea": "home",
    },
    ("Sun", 5): {
        "summary": "Sun in 5th House: Creative brilliance, leadership in education, strong connection with children.",
        "strengths": ["sharp intellect", "artistic talent", "speculative success"],
        "challenges": ["ego in romantic affairs", "over-investment in personal glory"],
        "lifeArea": "creativity",
    },
    ("Sun", 6): {
        "summary": "Sun in 6th House: Triumph over enemies, strong disease resistance, success in service roles.",
        "strengths": ["ability to defeat competition", "good health vitality", "success in government service"],
        "challenges": ["conflicts with subordinates", "stress from overwork"],
        "lifeArea": "health",
    },
    ("Sun", 7): {
        "summary": "Sun in 7th House: Prominent spouse, strong public image, partnerships with authority figures.",
        "strengths": ["influential partnerships", "public recognition through marriage", "strong business alliances"],
        "challenges": ["ego clashes in marriage", "dominating partner dynamics"],
        "lifeArea": "partnership",
    },
    ("Sun", 8): {
        "summary": "Sun in 8th House: Interest in hidden knowledge, inheritance from father, transformative life events.",
        "strengths": ["research aptitude", "resilience through crises", "interest in occult sciences"],
        "challenges": ["health concerns related to vitality", "strained relationship with father"],
        "lifeArea": "transformation",
    },
    ("Sun", 9): {
        "summary": "Sun in 9th House: Deep dharmic conviction, respected teacher or guide, fortunate father.",
        "strengths": ["strong moral compass", "success in higher education", "leadership in religious or philosophical circles"],
        "challenges": ["dogmatic beliefs", "conflicts with mentors"],
        "lifeArea": "dharma",
    },
    ("Sun", 10): {
        "summary": "Sun in 10th House: Strong career ambitions, leadership roles, public recognition and fame.",
        "strengths": ["professional authority", "government favor", "lasting reputation"],
        "challenges": ["workaholic tendencies", "pressure of public expectations"],
        "lifeArea": "career",
    },
    ("Sun", 11): {
        "summary": "Sun in 11th House: Gains through influential networks, fulfillment of ambitions, powerful friendships.",
        "strengths": ["high income potential", "well-connected social circle", "achievement of long-term goals"],
        "challenges": ["ego in friendships", "over-reliance on status networks"],
        "lifeArea": "gains",
    },
    ("Sun", 12): {
        "summary": "Sun in 12th House: Spiritual seeking, foreign connections, expenditure on noble causes.",
        "strengths": ["spiritual depth", "success in foreign lands", "charitable disposition"],
        "challenges": ["low physical vitality", "sense of isolation or anonymity"],
        "lifeArea": "spirituality",
    },

    # -----------------------------------------------------------------------
    # MOON in houses 1-12
    # -----------------------------------------------------------------------
    ("Moon", 1): {
        "summary": "Moon in 1st House: Sensitive personality, emotional expressiveness, intuitive nature.",
        "strengths": ["strong intuition", "empathetic disposition", "adaptable personality"],
        "challenges": ["emotional vulnerability", "fluctuating self-image"],
        "lifeArea": "identity",
    },
    ("Moon", 2): {
        "summary": "Moon in 2nd House: Wealth fluctuations, sweet speech, strong attachment to family.",
        "strengths": ["nurturing family bonds", "eloquent and soothing speech", "income from public-facing work"],
        "challenges": ["financial instability", "emotional eating habits"],
        "lifeArea": "finances",
    },
    ("Moon", 3): {
        "summary": "Moon in 3rd House: Imaginative communication, emotional bond with siblings, creative hobbies.",
        "strengths": ["artistic writing", "emotional courage", "adaptable communication style"],
        "challenges": ["restless mind", "over-sensitivity to criticism"],
        "lifeArea": "communication",
    },
    ("Moon", 4): {
        "summary": "Moon in 4th House: Deep love for home, close bond with mother, emotional contentment.",
        "strengths": ["strong domestic happiness", "property gains", "inner peace and emotional stability"],
        "challenges": ["over-attachment to comfort", "mood swings tied to home environment"],
        "lifeArea": "home",
    },
    ("Moon", 5): {
        "summary": "Moon in 5th House: Fertile imagination, emotional connection with children, romantic idealism.",
        "strengths": ["creative talent", "intuitive intelligence", "devotional mindset"],
        "challenges": ["emotional over-investment in romance", "anxiety about children"],
        "lifeArea": "creativity",
    },
    ("Moon", 6): {
        "summary": "Moon in 6th House: Emotional sensitivity to health, service-oriented nurturing, worry-prone mind.",
        "strengths": ["healing ability", "dedication to service", "empathy for the suffering"],
        "challenges": ["digestive health issues", "anxiety and excessive worry"],
        "lifeArea": "health",
    },
    ("Moon", 7): {
        "summary": "Moon in 7th House: Emotionally fulfilling partnerships, attractive personality, public popularity.",
        "strengths": ["nurturing spouse", "harmonious partnerships", "public appeal"],
        "challenges": ["emotional dependency on partner", "need for constant reassurance"],
        "lifeArea": "partnership",
    },
    ("Moon", 8): {
        "summary": "Moon in 8th House: Psychic sensitivity, emotional intensity, interest in the mystical.",
        "strengths": ["intuitive research ability", "emotional resilience through transformation", "inheritance potential"],
        "challenges": ["emotional turbulence", "fear and anxiety about change"],
        "lifeArea": "transformation",
    },
    ("Moon", 9): {
        "summary": "Moon in 9th House: Devotional nature, emotional connection to faith, fortunate mother.",
        "strengths": ["spiritual inclination", "love of pilgrimage and travel", "intuitive wisdom"],
        "challenges": ["sentimentalizing beliefs", "emotional restlessness"],
        "lifeArea": "dharma",
    },
    ("Moon", 10): {
        "summary": "Moon in 10th House: Career in public service, fame through nurturing roles, emotional investment in work.",
        "strengths": ["popularity in profession", "success in caregiving or hospitality", "public trust"],
        "challenges": ["mood-driven career decisions", "work-life emotional imbalance"],
        "lifeArea": "career",
    },
    ("Moon", 11): {
        "summary": "Moon in 11th House: Gains through emotional connections, supportive friend circle, fulfilled desires.",
        "strengths": ["strong social bonds", "income from public or women", "community-oriented success"],
        "challenges": ["emotional fluctuations in friendships", "unfocused aspirations"],
        "lifeArea": "gains",
    },
    ("Moon", 12): {
        "summary": "Moon in 12th House: Rich dream life, spiritual sensitivity, comfort in solitude.",
        "strengths": ["deep meditation ability", "foreign settlement prospects", "compassionate nature"],
        "challenges": ["emotional isolation", "sleep disturbances or vivid dreams"],
        "lifeArea": "spirituality",
    },

    # -----------------------------------------------------------------------
    # MARS in houses 1-12
    # -----------------------------------------------------------------------
    ("Mars", 1): {
        "summary": "Mars in 1st House: Dynamic energy, athletic build, fearless and competitive temperament.",
        "strengths": ["physical stamina", "leadership through action", "pioneering spirit"],
        "challenges": ["impulsiveness", "aggressive first impression"],
        "lifeArea": "identity",
    },
    ("Mars", 2): {
        "summary": "Mars in 2nd House: Assertive speech, earning through effort and courage, family protector.",
        "strengths": ["determined wealth-building", "bold communication", "protective of family"],
        "challenges": ["harsh speech causing conflicts", "impulsive spending"],
        "lifeArea": "finances",
    },
    ("Mars", 3): {
        "summary": "Mars in 3rd House: Exceptional courage, athletic siblings, mastery in hands-on skills.",
        "strengths": ["fearless initiative", "skill in martial arts or sports", "powerful writing"],
        "challenges": ["sibling rivalry", "reckless short travels"],
        "lifeArea": "communication",
    },
    ("Mars", 4): {
        "summary": "Mars in 4th House: Property through effort, energetic home life, strong emotional drive.",
        "strengths": ["real estate success", "home renovation skills", "protective of family"],
        "challenges": ["domestic arguments", "restless home environment"],
        "lifeArea": "home",
    },
    ("Mars", 5): {
        "summary": "Mars in 5th House: Competitive intellect, passion in romance, athletic or adventurous children.",
        "strengths": ["sharp strategic mind", "sports and competition success", "bold creative expression"],
        "challenges": ["impulsive romantic decisions", "speculative losses"],
        "lifeArea": "creativity",
    },
    ("Mars", 6): {
        "summary": "Mars in 6th House: Powerful victory over enemies, strong immunity, excellence in competitive fields.",
        "strengths": ["defeating opponents", "surgical or medical aptitude", "disciplined fitness"],
        "challenges": ["workplace conflicts", "injury-prone constitution"],
        "lifeArea": "health",
    },
    ("Mars", 7): {
        "summary": "Mars in 7th House: Passionate partnerships, dynamic spouse, assertive public dealings (Mangal Dosha).",
        "strengths": ["energetic business partnerships", "protective spouse", "charisma in public interactions"],
        "challenges": ["marital conflicts", "impatience with partners"],
        "lifeArea": "partnership",
    },
    ("Mars", 8): {
        "summary": "Mars in 8th House: Transformative energy, research in hidden matters, sudden life changes.",
        "strengths": ["resilience in crises", "surgical skill", "inheritance from in-laws"],
        "challenges": ["accident proneness", "anger management issues"],
        "lifeArea": "transformation",
    },
    ("Mars", 9): {
        "summary": "Mars in 9th House: Warrior for beliefs, adventurous journeys, active pursuit of dharma.",
        "strengths": ["courageous convictions", "success in foreign ventures", "physical pilgrimage energy"],
        "challenges": ["fanaticism", "conflicts with father or guru"],
        "lifeArea": "dharma",
    },
    ("Mars", 10): {
        "summary": "Mars in 10th House: Ambitious career drive, success in engineering or defense, action-oriented leadership.",
        "strengths": ["professional determination", "executive ability", "technical mastery"],
        "challenges": ["ruthless ambition", "workplace power struggles"],
        "lifeArea": "career",
    },
    ("Mars", 11): {
        "summary": "Mars in 11th House: Gains through courage and competition, influential allies, achievement of goals.",
        "strengths": ["high income through effort", "strong elder sibling bond", "goal-oriented energy"],
        "challenges": ["aggressive networking", "conflicts in group settings"],
        "lifeArea": "gains",
    },
    ("Mars", 12): {
        "summary": "Mars in 12th House: Energy directed inward, foreign residence, hidden strength and secret activities.",
        "strengths": ["spiritual warrior energy", "success in foreign lands", "private determination"],
        "challenges": ["suppressed anger", "expenditure through impulsive actions"],
        "lifeArea": "spirituality",
    },

    # -----------------------------------------------------------------------
    # MERCURY in houses 1-12
    # -----------------------------------------------------------------------
    ("Mercury", 1): {
        "summary": "Mercury in 1st House: Quick-witted personality, youthful appearance, excellent communicator.",
        "strengths": ["sharp intellect", "versatile personality", "persuasive speaking ability"],
        "challenges": ["nervous energy", "tendency to overthink"],
        "lifeArea": "identity",
    },
    ("Mercury", 2): {
        "summary": "Mercury in 2nd House: Wealth through intellect, articulate speech, business-minded family.",
        "strengths": ["income from writing or commerce", "multilingual ability", "financial acumen"],
        "challenges": ["talking before thinking", "scattered financial plans"],
        "lifeArea": "finances",
    },
    ("Mercury", 3): {
        "summary": "Mercury in 3rd House: Brilliant communicator, skilled writer, mentally agile and curious.",
        "strengths": ["literary talent", "networking mastery", "quick learning"],
        "challenges": ["information overload", "superficial knowledge"],
        "lifeArea": "communication",
    },
    ("Mercury", 4): {
        "summary": "Mercury in 4th House: Intellectual home environment, academic mother, multiple residences.",
        "strengths": ["home-based business success", "educational foundations", "analytical mind"],
        "challenges": ["mental restlessness at home", "over-analyzing emotions"],
        "lifeArea": "home",
    },
    ("Mercury", 5): {
        "summary": "Mercury in 5th House: Brilliant student, success in competitive exams, witty and playful romance.",
        "strengths": ["academic excellence", "creative writing or media talent", "strategic thinking in investments"],
        "challenges": ["over-intellectualizing feelings", "nervous approach to romance"],
        "lifeArea": "creativity",
    },
    ("Mercury", 6): {
        "summary": "Mercury in 6th House: Analytical problem-solver, success in health or legal professions, detail-oriented service.",
        "strengths": ["medical or legal aptitude", "defeating enemies through intellect", "precise work ethic"],
        "challenges": ["nervous health conditions", "over-critical nature"],
        "lifeArea": "health",
    },
    ("Mercury", 7): {
        "summary": "Mercury in 7th House: Communicative partnerships, youthful spouse, success in business contracts.",
        "strengths": ["diplomatic negotiation skill", "intellectual compatibility in marriage", "trade success"],
        "challenges": ["indecision in partnerships", "excessive analysis of relationships"],
        "lifeArea": "partnership",
    },
    ("Mercury", 8): {
        "summary": "Mercury in 8th House: Research-oriented mind, interest in occult sciences, inherited intellectual gifts.",
        "strengths": ["deep research ability", "skill in astrology or psychology", "strategic financial planning"],
        "challenges": ["secretive communication", "anxiety about hidden matters"],
        "lifeArea": "transformation",
    },
    ("Mercury", 9): {
        "summary": "Mercury in 9th House: Love of higher learning, skilled teacher, philosophical writing.",
        "strengths": ["academic success", "publishing and media recognition", "multicultural understanding"],
        "challenges": ["intellectual pride", "debating religious matters excessively"],
        "lifeArea": "dharma",
    },
    ("Mercury", 10): {
        "summary": "Mercury in 10th House: Career in communication, media, or commerce, recognized intellectual.",
        "strengths": ["professional versatility", "public speaking success", "technology career aptitude"],
        "challenges": ["career indecision", "reputation for inconsistency"],
        "lifeArea": "career",
    },
    ("Mercury", 11): {
        "summary": "Mercury in 11th House: Gains through intellect and networking, diverse friend circle, digital income.",
        "strengths": ["income from communication or technology", "influential network", "goal achievement through planning"],
        "challenges": ["scattered social connections", "unrealistic goals"],
        "lifeArea": "gains",
    },
    ("Mercury", 12): {
        "summary": "Mercury in 12th House: Contemplative mind, foreign language ability, intuitive writing.",
        "strengths": ["imagination and creative visualization", "success abroad", "spiritual intellect"],
        "challenges": ["communication difficulties", "mental fatigue and insomnia"],
        "lifeArea": "spirituality",
    },

    # -----------------------------------------------------------------------
    # JUPITER in houses 1-12
    # -----------------------------------------------------------------------
    ("Jupiter", 1): {
        "summary": "Jupiter in 1st House: Wise and generous personality, natural teacher, blessed with good fortune.",
        "strengths": ["optimistic outlook", "respected by others", "strong moral character"],
        "challenges": ["overindulgence leading to weight gain", "self-righteousness"],
        "lifeArea": "identity",
    },
    ("Jupiter", 2): {
        "summary": "Jupiter in 2nd House: Abundant wealth, truthful speech, prosperous family life.",
        "strengths": ["financial prosperity", "eloquent and wise speech", "family harmony"],
        "challenges": ["over-spending on luxuries", "complacency about savings"],
        "lifeArea": "finances",
    },
    ("Jupiter", 3): {
        "summary": "Jupiter in 3rd House: Wise communication, philosophical writing, benevolent relationship with siblings.",
        "strengths": ["inspiring communication", "successful publishing", "courageous optimism"],
        "challenges": ["preachiness in conversation", "over-promising"],
        "lifeArea": "communication",
    },
    ("Jupiter", 4): {
        "summary": "Jupiter in 4th House: Spacious and beautiful home, wise mother, deep inner contentment.",
        "strengths": ["property expansion", "academic success", "emotional wisdom"],
        "challenges": ["attachment to comfort", "over-expansion of domestic life"],
        "lifeArea": "home",
    },
    ("Jupiter", 5): {
        "summary": "Jupiter in 5th House: Blessed with intelligent children, creative genius, spiritual inclination.",
        "strengths": ["educational brilliance", "wise investment sense", "devotional nature"],
        "challenges": ["over-confidence in speculation", "excessive pride in children"],
        "lifeArea": "creativity",
    },
    ("Jupiter", 6): {
        "summary": "Jupiter in 6th House: Overcoming obstacles through wisdom, healing profession, generous service.",
        "strengths": ["success in healing or law", "protection from enemies", "charitable nature"],
        "challenges": ["weight-related health issues", "taking on too many burdens"],
        "lifeArea": "health",
    },
    ("Jupiter", 7): {
        "summary": "Jupiter in 7th House: Wise and supportive spouse, successful partnerships, respected public image.",
        "strengths": ["fortunate marriage", "successful business partnerships", "diplomatic skill"],
        "challenges": ["idealistic expectations of partner", "over-trusting in contracts"],
        "lifeArea": "partnership",
    },
    ("Jupiter", 8): {
        "summary": "Jupiter in 8th House: Longevity, inheritance, deep interest in mysticism and occult knowledge.",
        "strengths": ["protection in crises", "financial gains through inheritance", "spiritual transformation"],
        "challenges": ["secrecy about beliefs", "struggles with shared resources"],
        "lifeArea": "transformation",
    },
    ("Jupiter", 9): {
        "summary": "Jupiter in 9th House: Supreme fortune, devotion to dharma, revered teacher or guru.",
        "strengths": ["exceptional luck", "spiritual wisdom", "success in higher education and travel"],
        "challenges": ["religious orthodoxy", "over-reliance on fortune"],
        "lifeArea": "dharma",
    },
    ("Jupiter", 10): {
        "summary": "Jupiter in 10th House: Prestigious career, respected leader, success in education or law.",
        "strengths": ["professional honor", "ethical leadership", "career growth and recognition"],
        "challenges": ["over-ambition masked as duty", "conflict between career and personal life"],
        "lifeArea": "career",
    },
    ("Jupiter", 11): {
        "summary": "Jupiter in 11th House: Abundant gains, influential friends, fulfillment of noble aspirations.",
        "strengths": ["substantial income", "supportive social circle", "large-scale goal achievement"],
        "challenges": ["extravagant social spending", "unrealistic expectations from friends"],
        "lifeArea": "gains",
    },
    ("Jupiter", 12): {
        "summary": "Jupiter in 12th House: Spiritual liberation, success in foreign lands, generous and selfless nature.",
        "strengths": ["moksha potential", "charitable giving", "ashram or retreat connections"],
        "challenges": ["excessive expenditure", "detachment from material security"],
        "lifeArea": "spirituality",
    },

    # -----------------------------------------------------------------------
    # VENUS in houses 1-12
    # -----------------------------------------------------------------------
    ("Venus", 1): {
        "summary": "Venus in 1st House: Attractive personality, artistic flair, charming and graceful demeanor.",
        "strengths": ["physical beauty", "magnetic personality", "artistic talent"],
        "challenges": ["vanity", "excessive focus on appearances"],
        "lifeArea": "identity",
    },
    ("Venus", 2): {
        "summary": "Venus in 2nd House: Wealth through arts or luxury, sweet melodious speech, beautiful family life.",
        "strengths": ["financial comfort", "refined taste in food and dress", "harmonious family"],
        "challenges": ["overindulgence in luxury", "attachment to material possessions"],
        "lifeArea": "finances",
    },
    ("Venus", 3): {
        "summary": "Venus in 3rd House: Artistic communication, creative hobbies, harmonious sibling bonds.",
        "strengths": ["talent in music, dance, or writing", "pleasant social manner", "enjoyable short travels"],
        "challenges": ["superficial creative pursuits", "flirtatious communication"],
        "lifeArea": "communication",
    },
    ("Venus", 4): {
        "summary": "Venus in 4th House: Luxurious home, beautiful vehicles, loving mother, domestic happiness.",
        "strengths": ["beautiful living spaces", "comfort and luxury at home", "emotional harmony"],
        "challenges": ["over-attachment to comforts", "extravagant home spending"],
        "lifeArea": "home",
    },
    ("Venus", 5): {
        "summary": "Venus in 5th House: Romantic nature, artistic creativity, beautiful children, love of entertainment.",
        "strengths": ["creative genius in arts", "fulfilling romance", "success in entertainment"],
        "challenges": ["excessive romantic idealism", "indulgence in pleasures"],
        "lifeArea": "creativity",
    },
    ("Venus", 6): {
        "summary": "Venus in 6th House: Service through beauty and healing, overcoming rivals with grace, health-conscious.",
        "strengths": ["success in beauty or health industries", "diplomatic conflict resolution", "aesthetic work environment"],
        "challenges": ["relationship difficulties", "reproductive health concerns"],
        "lifeArea": "health",
    },
    ("Venus", 7): {
        "summary": "Venus in 7th House: Beautiful and loving spouse, harmonious marriage, success in partnerships.",
        "strengths": ["fulfilling marriage", "artistic partnerships", "public charm"],
        "challenges": ["over-dependence on partner", "idealizing relationships"],
        "lifeArea": "partnership",
    },
    ("Venus", 8): {
        "summary": "Venus in 8th House: Deep sensual nature, inheritance through spouse, interest in tantric arts.",
        "strengths": ["financial gains through marriage", "transformative relationships", "occult artistic talent"],
        "challenges": ["secret relationships", "possessiveness"],
        "lifeArea": "transformation",
    },
    ("Venus", 9): {
        "summary": "Venus in 9th House: Love of philosophy and culture, fortunate travel, devotion through beauty.",
        "strengths": ["artistic pilgrimage", "cross-cultural romance", "refined spiritual practice"],
        "challenges": ["superficial spirituality", "excessive travel indulgence"],
        "lifeArea": "dharma",
    },
    ("Venus", 10): {
        "summary": "Venus in 10th House: Career in arts or luxury, public admiration, professional charm.",
        "strengths": ["success in creative professions", "popularity and fame", "diplomatic career skills"],
        "challenges": ["using charm for manipulation", "career driven by appearances"],
        "lifeArea": "career",
    },
    ("Venus", 11): {
        "summary": "Venus in 11th House: Gains through arts and partnerships, beautiful friendships, fulfilled desires.",
        "strengths": ["income from creative ventures", "socially graceful networking", "luxury through associations"],
        "challenges": ["materialistic friendships", "over-indulgent social life"],
        "lifeArea": "gains",
    },
    ("Venus", 12): {
        "summary": "Venus in 12th House: Pleasure in solitude, foreign romance, spiritual devotion through art.",
        "strengths": ["bed pleasures", "foreign luxury connections", "transcendent artistic vision"],
        "challenges": ["secret love affairs", "excessive expenditure on pleasures"],
        "lifeArea": "spirituality",
    },

    # -----------------------------------------------------------------------
    # SATURN in houses 1-12
    # -----------------------------------------------------------------------
    ("Saturn", 1): {
        "summary": "Saturn in 1st House: Serious demeanor, disciplined personality, slow but steady rise in life.",
        "strengths": ["resilience and endurance", "mature outlook", "self-discipline"],
        "challenges": ["delayed recognition", "pessimistic tendencies"],
        "lifeArea": "identity",
    },
    ("Saturn", 2): {
        "summary": "Saturn in 2nd House: Wealth through hard work, measured speech, frugal family values.",
        "strengths": ["disciplined saving", "practical financial management", "honest speech"],
        "challenges": ["financial hardship in early life", "restricted family harmony"],
        "lifeArea": "finances",
    },
    ("Saturn", 3): {
        "summary": "Saturn in 3rd House: Determined effort, structured communication, serious relationship with siblings.",
        "strengths": ["perseverance", "disciplined writing or craftsmanship", "long-lasting courage"],
        "challenges": ["communication blocks", "strained sibling relations"],
        "lifeArea": "communication",
    },
    ("Saturn", 4): {
        "summary": "Saturn in 4th House: Responsibilities at home, property through persistent effort, duty toward mother.",
        "strengths": ["durable property investments", "inner discipline", "emotional maturity"],
        "challenges": ["lack of domestic peace", "emotional coldness"],
        "lifeArea": "home",
    },
    ("Saturn", 5): {
        "summary": "Saturn in 5th House: Disciplined intellect, delayed children, serious approach to creativity.",
        "strengths": ["structured learning", "mature creative expression", "cautious investments"],
        "challenges": ["lack of joy in creative pursuits", "delayed or difficult progeny"],
        "lifeArea": "creativity",
    },
    ("Saturn", 6): {
        "summary": "Saturn in 6th House: Victory over enemies through patience, strong work ethic, chronic health awareness.",
        "strengths": ["defeating competition methodically", "disciplined health routines", "dedicated service"],
        "challenges": ["chronic health issues", "burdensome daily routines"],
        "lifeArea": "health",
    },
    ("Saturn", 7): {
        "summary": "Saturn in 7th House: Delayed marriage, mature or older spouse, lasting but tested partnerships.",
        "strengths": ["committed long-term relationships", "loyal partnerships", "business durability"],
        "challenges": ["marital delays or coldness", "partner who is demanding or restrictive"],
        "lifeArea": "partnership",
    },
    ("Saturn", 8): {
        "summary": "Saturn in 8th House: Longevity, chronic transformative processes, deep karmic lessons.",
        "strengths": ["long life", "research endurance", "handling crises with composure"],
        "challenges": ["chronic illness", "fear and anxiety about mortality"],
        "lifeArea": "transformation",
    },
    ("Saturn", 9): {
        "summary": "Saturn in 9th House: Structured spiritual practice, delayed fortune, duty-bound philosophy.",
        "strengths": ["disciplined dharmic path", "respect for tradition", "success through perseverance in higher learning"],
        "challenges": ["rigid religious views", "strained relationship with father or guru"],
        "lifeArea": "dharma",
    },
    ("Saturn", 10): {
        "summary": "Saturn in 10th House: Powerful career through discipline, authority after sustained effort, lasting legacy.",
        "strengths": ["professional mastery", "government or institutional success", "unshakable reputation"],
        "challenges": ["career pressure and heavy responsibilities", "delayed promotions"],
        "lifeArea": "career",
    },
    ("Saturn", 11): {
        "summary": "Saturn in 11th House: Steady gains over time, reliable friendships, disciplined pursuit of goals.",
        "strengths": ["consistent long-term income", "loyal older friends", "methodical goal attainment"],
        "challenges": ["limited social circle", "delayed fulfillment of desires"],
        "lifeArea": "gains",
    },
    ("Saturn", 12): {
        "summary": "Saturn in 12th House: Spiritual discipline, foreign residence, expenses through obligations.",
        "strengths": ["structured spiritual practice", "success abroad through hard work", "acceptance of solitude"],
        "challenges": ["isolation and loneliness", "hidden debts or liabilities"],
        "lifeArea": "spirituality",
    },

    # -----------------------------------------------------------------------
    # RAHU in houses 1-12
    # -----------------------------------------------------------------------
    ("Rahu", 1): {
        "summary": "Rahu in 1st House: Magnetic personality, unconventional self-image, intense worldly ambition.",
        "strengths": ["charismatic presence", "ability to reinvent identity", "success in foreign environments"],
        "challenges": ["identity confusion", "deceptive self-presentation"],
        "lifeArea": "identity",
    },
    ("Rahu", 2): {
        "summary": "Rahu in 2nd House: Unconventional wealth sources, foreign food habits, amplified material desires.",
        "strengths": ["sudden financial gains", "multilingual or foreign speech", "innovative earning methods"],
        "challenges": ["financial instability", "dishonesty in speech"],
        "lifeArea": "finances",
    },
    ("Rahu", 3): {
        "summary": "Rahu in 3rd House: Bold and unconventional communication, media success, daring initiatives.",
        "strengths": ["media and technology talent", "fearless self-promotion", "innovative skills"],
        "challenges": ["manipulative communication", "risky ventures"],
        "lifeArea": "communication",
    },
    ("Rahu", 4): {
        "summary": "Rahu in 4th House: Unusual home environment, foreign property, intense emotional undercurrents.",
        "strengths": ["property in foreign lands", "technological comforts at home", "unique cultural heritage"],
        "challenges": ["domestic instability", "disconnect from roots"],
        "lifeArea": "home",
    },
    ("Rahu", 5): {
        "summary": "Rahu in 5th House: Unconventional creativity, obsessive romance, speculative risk-taking.",
        "strengths": ["innovative creative expression", "success in technology or film", "unique intellectual gifts"],
        "challenges": ["gambling tendencies", "complications in love or with children"],
        "lifeArea": "creativity",
    },
    ("Rahu", 6): {
        "summary": "Rahu in 6th House: Powerful victory over enemies, unconventional healing, overcoming foreign obstacles.",
        "strengths": ["defeating powerful opponents", "success in competitive or legal fields", "resilience against disease"],
        "challenges": ["unusual health issues", "obsessive work habits"],
        "lifeArea": "health",
    },
    ("Rahu", 7): {
        "summary": "Rahu in 7th House: Unconventional partnerships, foreign spouse, intense public interactions.",
        "strengths": ["cross-cultural marriage success", "innovative business partnerships", "public magnetism"],
        "challenges": ["deception in relationships", "multiple partnership disruptions"],
        "lifeArea": "partnership",
    },
    ("Rahu", 8): {
        "summary": "Rahu in 8th House: Deep occult interest, sudden transformations, unconventional research.",
        "strengths": ["mastery of hidden knowledge", "sudden inheritance", "fearlessness in crisis"],
        "challenges": ["obsession with mysteries", "sudden health scares"],
        "lifeArea": "transformation",
    },
    ("Rahu", 9): {
        "summary": "Rahu in 9th House: Unconventional beliefs, foreign guru, amplified desire for higher truth.",
        "strengths": ["cross-cultural wisdom", "success in foreign higher education", "breaking philosophical boundaries"],
        "challenges": ["religious hypocrisy", "conflict with traditional authorities"],
        "lifeArea": "dharma",
    },
    ("Rahu", 10): {
        "summary": "Rahu in 10th House: Rapid career rise, fame through unconventional means, powerful public image.",
        "strengths": ["sudden professional success", "technology or media career", "political acumen"],
        "challenges": ["scandal risk", "unsustainable career shortcuts"],
        "lifeArea": "career",
    },
    ("Rahu", 11): {
        "summary": "Rahu in 11th House: Large gains through networks, influential foreign friends, amplified ambitions.",
        "strengths": ["massive income potential", "powerful social networking", "fulfillment of material desires"],
        "challenges": ["toxic friendships", "insatiable desire for more"],
        "lifeArea": "gains",
    },
    ("Rahu", 12): {
        "summary": "Rahu in 12th House: Foreign settlement, unconventional spirituality, hidden ambitions.",
        "strengths": ["success in foreign lands", "spiritual experiences through unusual paths", "vivid inner world"],
        "challenges": ["excessive expenditure", "escapism and addictions"],
        "lifeArea": "spirituality",
    },

    # -----------------------------------------------------------------------
    # KETU in houses 1-12
    # -----------------------------------------------------------------------
    ("Ketu", 1): {
        "summary": "Ketu in 1st House: Spiritually inclined personality, detachment from ego, mysterious aura.",
        "strengths": ["spiritual magnetism", "intuitive self-awareness", "non-materialistic outlook"],
        "challenges": ["identity confusion", "low self-confidence"],
        "lifeArea": "identity",
    },
    ("Ketu", 2): {
        "summary": "Ketu in 2nd House: Detachment from wealth, unconventional speech, past-life family karma.",
        "strengths": ["non-attachment to money", "spiritual speech", "intuitive knowledge of value"],
        "challenges": ["financial instability", "disconnection from family"],
        "lifeArea": "finances",
    },
    ("Ketu", 3): {
        "summary": "Ketu in 3rd House: Intuitive communication, spiritual courage, detachment from daily efforts.",
        "strengths": ["psychic communication", "mastery gained from past lives", "spiritual writing"],
        "challenges": ["lack of motivation for routine tasks", "distant sibling relationships"],
        "lifeArea": "communication",
    },
    ("Ketu", 4): {
        "summary": "Ketu in 4th House: Spiritual seeking over domestic comfort, detachment from homeland, inner restlessness.",
        "strengths": ["spiritual detachment from materialism", "yogic inner peace", "past-life wisdom about emotions"],
        "challenges": ["lack of domestic stability", "disconnection from mother"],
        "lifeArea": "home",
    },
    ("Ketu", 5): {
        "summary": "Ketu in 5th House: Past-life intelligence, spiritual creativity, detachment from progeny.",
        "strengths": ["innate wisdom", "meditative creativity", "moksha-oriented intellect"],
        "challenges": ["difficulty with children", "disinterest in worldly education"],
        "lifeArea": "creativity",
    },
    ("Ketu", 6): {
        "summary": "Ketu in 6th House: Spiritual victory over enemies, past-life healing abilities, detached service.",
        "strengths": ["natural immunity", "effortless victory over obstacles", "spiritual healing gifts"],
        "challenges": ["mysterious health conditions", "difficulty with structured routines"],
        "lifeArea": "health",
    },
    ("Ketu", 7): {
        "summary": "Ketu in 7th House: Spiritual partnerships, detachment from marriage, past-life relationship karma.",
        "strengths": ["spiritual partner connection", "non-attachment in business", "past-life relationship wisdom"],
        "challenges": ["marital dissatisfaction", "difficulty sustaining partnerships"],
        "lifeArea": "partnership",
    },
    ("Ketu", 8): {
        "summary": "Ketu in 8th House: Natural occult ability, spiritual transformation, past-life mystical knowledge.",
        "strengths": ["intuitive research mastery", "moksha through transformation", "psychic abilities"],
        "challenges": ["sudden unexpected events", "mysterious health issues"],
        "lifeArea": "transformation",
    },
    ("Ketu", 9): {
        "summary": "Ketu in 9th House: Past-life spiritual merit, unconventional dharma, detachment from dogma.",
        "strengths": ["innate spiritual wisdom", "non-dogmatic philosophical outlook", "liberation-oriented path"],
        "challenges": ["lack of faith in traditions", "disconnection from father or guru"],
        "lifeArea": "dharma",
    },
    ("Ketu", 10): {
        "summary": "Ketu in 10th House: Detachment from career ambition, past-life authority, spiritual vocation.",
        "strengths": ["effortless professional skill from past lives", "non-attachment to status", "spiritual career calling"],
        "challenges": ["career dissatisfaction", "lack of worldly ambition"],
        "lifeArea": "career",
    },
    ("Ketu", 11): {
        "summary": "Ketu in 11th House: Spiritual friendships, detachment from material gains, past-life network karma.",
        "strengths": ["non-materialistic approach to goals", "spiritual community connections", "wisdom about true fulfillment"],
        "challenges": ["income instability", "loss of friendships"],
        "lifeArea": "gains",
    },
    ("Ketu", 12): {
        "summary": "Ketu in 12th House: Strong moksha potential, natural meditation ability, past-life spiritual mastery.",
        "strengths": ["deep liberation potential", "effortless spiritual practice", "transcendence of worldly bonds"],
        "challenges": ["excessive withdrawal from world", "difficulty with practical matters"],
        "lifeArea": "spirituality",
    },
}

# ---------------------------------------------------------------------------
# 4. RETROGRADE_MEANINGS — Vakri Graha effects for each planet
# ---------------------------------------------------------------------------

RETROGRADE_MEANINGS = {
    "Sun": {
        "theme": "The Sun does not retrograde in astronomy, but in Jyotish its combust or weakened state turns attention inward toward self-doubt and re-evaluation of ego and authority.",
        "advice": "Reflect on whether your sense of identity comes from within or from external validation.",
    },
    "Moon": {
        "theme": "The Moon does not retrograde, but its waning phase (Krishna Paksha) mirrors retrograde energy, turning emotions inward and amplifying introspection.",
        "advice": "Honor your need for solitude and inner emotional processing during this phase.",
    },
    "Mars": {
        "theme": "Retrograde Mars internalizes anger and drive, redirecting aggressive energy into strategic review and re-evaluation of goals.",
        "advice": "Pause before acting on impulse; revisit unfinished projects rather than starting new ones.",
    },
    "Mercury": {
        "theme": "Retrograde Mercury disrupts communication and technology, prompting review of contracts, plans, and misunderstandings.",
        "advice": "Double-check all communications, back up data, and avoid signing important agreements.",
    },
    "Jupiter": {
        "theme": "Retrograde Jupiter turns wisdom inward, questioning beliefs, re-examining faith, and deepening philosophical understanding.",
        "advice": "Revisit your spiritual practices and core values; growth now comes from inner contemplation.",
    },
    "Venus": {
        "theme": "Retrograde Venus re-evaluates relationships, aesthetic choices, and personal values, often reviving past connections.",
        "advice": "Reflect on what you truly value in love and beauty; avoid major relationship decisions.",
    },
    "Saturn": {
        "theme": "Retrograde Saturn intensifies karmic review, revisiting past responsibilities and demanding inner accountability.",
        "advice": "Address lingering duties and unresolved karmic patterns with patience and honesty.",
    },
    "Rahu": {
        "theme": "Rahu is always retrograde in mean-node calculation, amplifying its obsessive and unconventional energy perpetually.",
        "advice": "Stay grounded in ethics; question whether your ambitions serve your higher purpose.",
    },
    "Ketu": {
        "theme": "Ketu is always retrograde in mean-node calculation, perpetually dissolving worldly attachments and pushing toward liberation.",
        "advice": "Embrace letting go; the detachment you feel is guiding you toward spiritual freedom.",
    },
}

# ---------------------------------------------------------------------------
# 5. Helper function
# ---------------------------------------------------------------------------


def get_house_planet_insight(
    planet_id: str, house: int, is_retrograde: bool = False
) -> dict:
    """
    Returns a combined interpretation for a planet in a specific house.

    Args:
        planet_id: Planet name (e.g. "Sun", "Moon", "Mars", etc.)
        house: House number (1-12)
        is_retrograde: Whether the planet is currently retrograde

    Returns:
        dict with keys: planet, house, interpretation, retrograde (optional),
        or an error dict if the combination is not found.
    """
    # Normalise planet_id to title case for consistent lookup
    planet_key = planet_id.strip().title()

    # Validate inputs
    if planet_key not in PLANET_SIGNIFICATIONS:
        return {"error": f"Unknown planet: {planet_id}"}
    if house < 1 or house > 12:
        return {"error": f"Invalid house number: {house}. Must be 1-12."}

    planet_info = PLANET_SIGNIFICATIONS[planet_key]
    house_info = HOUSE_MEANINGS[house]
    placement = PLANET_IN_HOUSE.get((planet_key, house))

    if placement is None:
        return {"error": f"No interpretation found for {planet_key} in house {house}."}

    result = {
        "planet": {
            "name": planet_info["name"],
            "symbol": planet_info["symbol"],
            "nature": planet_info["nature"],
            "keywords": planet_info["keywords"],
        },
        "house": {
            "number": house,
            "name": house_info["name"],
            "theme": house_info["theme"],
            "lifeAreas": house_info["lifeAreas"],
        },
        "interpretation": {
            "summary": placement["summary"],
            "strengths": placement["strengths"],
            "challenges": placement["challenges"],
            "lifeArea": placement["lifeArea"],
        },
    }

    if is_retrograde:
        retro = RETROGRADE_MEANINGS.get(planet_key)
        if retro:
            result["retrograde"] = {
                "theme": retro["theme"],
                "advice": retro["advice"],
            }

    return result
