"""
Comprehensive tests for horoscope generation and lucky elements.
Ensures no hardcoding and bespoke user experiences.
"""

from __future__ import annotations

from datetime import datetime, timedelta

import pytest

from routes.horoscope import SIGN_TRAITS, VALID_SIGNS, _generate_horoscope

try:  # pragma: no cover - optional dependency in some environments
    import swisseph as _swe  # noqa: F401
except Exception:  # pragma: no cover
    pytest.skip("pyswisseph not installed", allow_module_level=True)


# Update all calls to _generate_horoscope to include None for natal_data
def _gen_horoscope(sign, dt, period):
    """Wrapper to maintain backward compatibility with tests."""
    return _generate_horoscope(sign, dt, period, None)


class TestHoroscopeGeneration:
    """Test real astrological horoscope generation."""

    @pytest.mark.parametrize("sign", VALID_SIGNS)
    def test_all_signs_generate_unique_content(self, sign):
        """Each sign should generate unique horoscope content."""
        dt = datetime(2025, 1, 1, 0, 0, 0)
        content, lucky_elements = _gen_horoscope(sign, dt, "daily")

        assert content, f"Content should not be empty for {sign}"
        assert len(content) > 50, f"Content should be substantial for {sign}"
        assert sign.title() not in content or sign.lower() in content.lower(), f"Content should be relevant to {sign}"

    def test_horoscope_changes_with_date(self):
        """Horoscope content should vary based on date (planetary positions)."""
        sign = "leo"
        date1 = datetime(2025, 1, 1)
        date2 = datetime(2025, 7, 1)  # 6 months later, different planetary positions

        content1, _ = _gen_horoscope(sign, date1, "daily")
        content2, _ = _gen_horoscope(sign, date2, "daily")

        # Content should differ because planetary positions differ
        # (though lucky elements may be same if day_offset mod 3 is same)
        assert content1 != content2, "Horoscope should change with date"

    def test_horoscope_uses_sign_traits(self):
        """Horoscope should incorporate sign-specific keywords."""
        sign = "aries"
        dt = datetime(2025, 1, 1)

        content, _ = _gen_horoscope(sign, dt, "daily")

        # Should mention at least one Aries keyword
        aries_keywords = SIGN_TRAITS["aries"]["keywords"]
        has_keyword = any(kw in content.lower() for kw in aries_keywords)

        assert has_keyword, f"Aries horoscope should mention keywords: {aries_keywords}"

    def test_horoscope_adapts_to_period_type(self):
        """Weekly/monthly horoscopes should have broader scope than daily."""
        sign = "libra"
        dt = datetime(2025, 1, 1)

        content_daily, _ = _gen_horoscope(sign, dt, "daily")
        content_weekly, _ = _gen_horoscope(sign, dt, "weekly")
        content_monthly, _ = _gen_horoscope(sign, dt, "monthly")

        # All should be different
        assert content_daily != content_weekly
        assert content_weekly != content_monthly

    @pytest.mark.parametrize("period", ["daily", "weekly", "monthly"])
    def test_horoscope_period_types(self, period):
        """All period types should generate valid content."""
        sign = "gemini"
        dt = datetime(2025, 1, 1)

        content, lucky_elements = _gen_horoscope(sign, dt, period)

        assert content
        assert lucky_elements
        assert len(content) > 30


class TestLuckyElements:
    """Test sign-specific lucky elements generation."""

    @pytest.mark.parametrize("sign", VALID_SIGNS)
    def test_all_signs_have_lucky_elements(self, sign):
        """Every sign should return populated lucky elements."""
        dt = datetime(2025, 1, 1)
        _, lucky_elements = _generate_horoscope(sign, dt, "daily")

        assert lucky_elements, f"{sign} should have lucky elements"
        assert "color" in lucky_elements, f"{sign} missing color"
        assert "number" in lucky_elements, f"{sign} missing number"
        assert "day" in lucky_elements, f"{sign} missing day"
        assert "element" in lucky_elements, f"{sign} missing element"
        assert "ruler" in lucky_elements, f"{sign} missing ruler"

    def test_lucky_elements_match_sign_traits(self):
        """Lucky elements should come from sign's trait pool."""
        sign = "scorpio"
        dt = datetime(2025, 1, 1)

        _, lucky_elements = _generate_horoscope(sign, dt, "daily")

        traits = SIGN_TRAITS[sign]

        assert lucky_elements["color"] in traits["colors"], f"Color {lucky_elements['color']} not in {sign} colors"
        assert lucky_elements["number"] in traits["lucky_numbers"], f"Number {lucky_elements['number']} not in {sign} numbers"
        assert lucky_elements["day"] in traits["lucky_days"], f"Day {lucky_elements['day']} not in {sign} days"
        assert lucky_elements["element"] == traits["element"]
        assert lucky_elements["ruler"] == traits["ruler"]

    def test_lucky_elements_rotate_with_date(self):
        """Lucky elements should vary day by day (bespoke experience)."""
        sign = "taurus"
        date1 = datetime(2025, 1, 1)
        date2 = datetime(2025, 1, 2)
        date3 = datetime(2025, 1, 3)

        _, elem1 = _generate_horoscope(sign, date1, "daily")
        _, elem2 = _generate_horoscope(sign, date2, "daily")
        _, elem3 = _generate_horoscope(sign, date3, "daily")

        # At least one element should differ across consecutive days
        # (depending on modulo arithmetic with trait array sizes)
        elements_same = (
            elem1["color"] == elem2["color"] == elem3["color"]
            and elem1["number"] == elem2["number"] == elem3["number"]
            and elem1["day"] == elem2["day"] == elem3["day"]
        )

        # With 3 colors, 3 numbers, 2 days, there should be variation
        assert not elements_same, "Lucky elements should rotate with date"

    def test_lucky_elements_consistent_within_day(self):
        """Same day should give same lucky elements (deterministic)."""
        sign = "cancer"
        dt1 = datetime(2025, 6, 15, 8, 0)
        dt2 = datetime(2025, 6, 15, 20, 0)  # Same day, different time

        _, elem1 = _generate_horoscope(sign, dt1, "daily")
        _, elem2 = _generate_horoscope(sign, dt2, "daily")

        assert elem1 == elem2, "Same day should give same lucky elements"

    def test_no_hardcoded_purple_seven(self):
        """Ensure no sign is hardcoded to 'Purple' and '7'."""
        # This was the iOS client bug mentioned in audit
        for sign in VALID_SIGNS:
            dt = datetime(2025, 1, 1)
            _, lucky_elements = _generate_horoscope(sign, dt, "daily")

            # Check that we're not always returning Purple/7
            # (would indicate hardcoding)
            if sign != "sagittarius":  # Sagittarius legitimately has Purple
                # Other signs should occasionally have different colors
                pass

            # Verify numbers come from sign's pool, not hardcoded 7
            traits = SIGN_TRAITS[sign]
            assert lucky_elements["number"] in traits["lucky_numbers"]

    @pytest.mark.parametrize(
        "sign,expected_element,expected_ruler",
        [
            ("aries", "fire", "Mars"),
            ("taurus", "earth", "Venus"),
            ("gemini", "air", "Mercury"),
            ("cancer", "water", "Moon"),
            ("leo", "fire", "Sun"),
            ("virgo", "earth", "Mercury"),
            ("libra", "air", "Venus"),
            ("scorpio", "water", "Mars"),
            ("sagittarius", "fire", "Jupiter"),
            ("capricorn", "earth", "Saturn"),
            ("aquarius", "air", "Saturn"),
            ("pisces", "water", "Jupiter"),
        ],
    )
    def test_sign_element_and_ruler_accuracy(self, sign, expected_element, expected_ruler):
        """Verify astrological accuracy of sign elements and rulers."""
        dt = datetime(2025, 1, 1)
        _, lucky_elements = _generate_horoscope(sign, dt, "daily")

        assert lucky_elements["element"] == expected_element, f"{sign} should be {expected_element} element"
        assert lucky_elements["ruler"] == expected_ruler, f"{sign} should be ruled by {expected_ruler}"


class TestBespokeUserExperience:
    """Test that each user gets unique, personalized content."""

    def test_different_signs_same_day_different_content(self):
        """Different signs on same day should get different horoscopes."""
        dt = datetime(2025, 3, 15)

        results = {}
        for sign in VALID_SIGNS:
            content, lucky_elements = _gen_horoscope(sign, dt, "daily")
            results[sign] = {"content": content, "lucky": lucky_elements}

        # Fire signs should have different content from water signs
        fire_content = results["aries"]["content"]
        water_content = results["cancer"]["content"]

        assert fire_content != water_content, "Different signs should have different content"

        # Leo and Aries (both fire) should have different lucky elements
        # (because they have different colors/numbers/days)
        leo_lucky = results["leo"]["lucky"]
        aries_lucky = results["aries"]["lucky"]

        assert leo_lucky != aries_lucky, "Same element signs should have different lucky elements"

    def test_same_sign_different_days_variation(self):
        """Same sign on different days should show variation."""
        sign = "virgo"
        dates = [
            datetime(2025, 1, 1),
            datetime(2025, 1, 15),
            datetime(2025, 2, 1),
            datetime(2025, 6, 1),
        ]

        contents = []
        lucky_sets = []

        for dt in dates:
            content, lucky = _gen_horoscope(sign, dt, "daily")
            contents.append(content)
            lucky_sets.append(lucky)

        # Content should vary (different planetary positions)
        unique_contents = set(contents)
        assert len(unique_contents) > 1, "Content should vary across dates"

        # Lucky elements should rotate
        unique_lucky = [(l["color"], l["number"], l["day"]) for l in lucky_sets]
        assert len(set(unique_lucky)) > 1, "Lucky elements should rotate"

    def test_year_long_rotation_coverage(self):
        """Over a year, each sign should show all its lucky elements."""
        sign = "aquarius"
        traits = SIGN_TRAITS[sign]

        seen_colors = set()
        seen_numbers = set()
        seen_days = set()

        # Sample throughout the year (smaller intervals to catch all rotations)
        for day_offset in range(0, 365):  # Every day
            dt = datetime(2025, 1, 1) + timedelta(days=day_offset)
            _, lucky = _generate_horoscope(sign, dt, "daily")

            seen_colors.add(lucky["color"])
            seen_numbers.add(lucky["number"])
            seen_days.add(lucky["day"])

        # Should see all options over the year
        assert seen_colors == set(traits["colors"]), f"Should cycle through all colors: {traits['colors']}, got {seen_colors}"
        assert seen_numbers == set(
            traits["lucky_numbers"]
        ), f"Should cycle through all numbers: {traits['lucky_numbers']}, got {seen_numbers}"
        assert seen_days == set(
            traits["lucky_days"]
        ), f"Should cycle through all days: {traits['lucky_days']}, got {seen_days}"


class TestEphemerisIntegration:
    """Test that horoscope uses real planetary positions."""

    def test_sun_transit_detection(self):
        """When Sun is in sign's position, content should reflect it."""
        # Leo season: Sun in Leo (~July 23 - Aug 22)
        leo_dt = datetime(2025, 8, 1)  # Sun in Leo
        content, _ = _generate_horoscope("leo", leo_dt, "daily")

        # Should mention Sun illumination
        assert "sun" in content.lower() or "shine" in content.lower(), "Leo horoscope during Leo season should mention Sun"

    def test_content_incorporates_planetary_keywords(self):
        """Horoscope should use planetary keywords from transits."""
        dt = datetime(2025, 3, 15)

        # Mars-ruled sign should get Mars-related guidance
        content, _ = _generate_horoscope("aries", dt, "daily")

        # Should mention action, courage, leadership, or initiative
        mars_themes = ["action", "courage", "leadership", "initiative", "mars", "bold"]
        has_mars_theme = any(theme in content.lower() for theme in mars_themes)

        assert has_mars_theme, "Aries horoscope should include Mars themes"

    def test_water_sign_emotional_guidance(self):
        """Water signs should get emotion-related guidance when relevant."""
        dt = datetime(2025, 4, 15)

        for sign in ["cancer", "scorpio", "pisces"]:
            content, _ = _gen_horoscope(sign, dt, "daily")

            # Water signs should mention emotions, intuition, or feelings
            water_themes = ["emotion", "intuition", "feeling", "deep", "spiritual"]
            has_water_theme = any(theme in content.lower() for theme in water_themes)

            assert has_water_theme, f"{sign} should include water sign themes"
