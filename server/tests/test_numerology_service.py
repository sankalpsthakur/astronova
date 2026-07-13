"""
Unit tests for NumerologyService — Loshu Grid construction, eigenvalue analysis,
plane detection, driver/conductor numbers, and phone-digit integration.
"""

from __future__ import annotations

import pytest

from services.numerology_service import NumerologyService


class TestNumerologyService:
    """Test NumerologyService core calculations."""

    @pytest.fixture
    def service(self):
        return NumerologyService()

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _dob_24_12_1999() -> list:
        """Return sorted digit list for DOB 24/12/1999."""
        return [2, 4, 1, 2, 1, 9, 9, 9]

    # ------------------------------------------------------------------
    # Grid tests
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_build_loshu_grid_known_dob(self, service):
        """DOB 24/12/1999 -> verify grid has correct counts, missing, triple, double."""
        digits = self._dob_24_12_1999()
        result = service.build_loshu_grid(digits)

        # Verify grid structure
        assert "grid" in result
        assert "counts" in result
        assert "missing" in result
        assert "present" in result
        assert "triple_numbers" in result
        assert "double_numbers" in result
        assert "single_numbers" in result

        grid = result["grid"]
        assert len(grid) == 3
        assert all(len(row) == 3 for row in grid)

        # Verify digit counts for 24/12/1999: 1->2, 2->2, 4->1, 9->3
        counts = result["counts"]
        assert counts["1"] == 2
        assert counts["2"] == 2
        assert counts["3"] == 0
        assert counts["4"] == 1
        assert counts["5"] == 0
        assert counts["6"] == 0
        assert counts["7"] == 0
        assert counts["8"] == 0
        assert counts["9"] == 3

        # Verify grid cell values at known Lo Shu positions
        # Position (0,0)=4 -> count 1, (0,1)=9 -> count 3, (0,2)=2 -> count 2
        # Position (1,0)=3 -> count 0, (1,1)=5 -> count 0, (1,2)=7 -> count 0
        # Position (2,0)=8 -> count 0, (2,1)=1 -> count 2, (2,2)=6 -> count 0
        assert grid[0][0] == 1  # digit 4
        assert grid[0][1] == 3  # digit 9
        assert grid[0][2] == 2  # digit 2
        assert grid[1][0] == 0  # digit 3
        assert grid[1][1] == 0  # digit 5
        assert grid[1][2] == 0  # digit 7
        assert grid[2][0] == 0  # digit 8
        assert grid[2][1] == 2  # digit 1
        assert grid[2][2] == 0  # digit 6

        # Verify derived lists
        assert result["missing"] == [3, 5, 6, 7, 8]
        assert sorted(result["present"]) == [1, 2, 4, 9]
        assert result["triple_numbers"] == [9]
        assert result["double_numbers"] == [1, 2]
        assert result["single_numbers"] == [4]

    @pytest.mark.unit
    def test_eigenvalues_known_grid(self, service):
        """Verify eigenvalues for the 24/12/1999 grid: λ ≈ 1.0, 0.0, 0.0."""
        digits = self._dob_24_12_1999()
        grid_data = service.build_loshu_grid(digits)
        result = service.compute_eigenvalues(grid_data["grid"])

        assert "eigenvalues" in result
        assert "dominant_eigenvalue" in result
        assert "zero_eigenvalues" in result
        assert "interpretation" in result

        evals = result["eigenvalues"]
        assert len(evals) == 3

        # First eigenvalue should be ~1.0 (non-zero)
        assert evals[0] == pytest.approx(1.0, abs=0.01)
        # Remaining two should be ~0.0
        assert evals[1] == pytest.approx(0.0, abs=0.01)
        assert evals[2] == pytest.approx(0.0, abs=0.01)

        assert result["dominant_eigenvalue"] == pytest.approx(1.0, abs=0.01)
        assert result["zero_eigenvalues"] == 2

        # Interpretation should reference zero count
        assert "collapsed" in result["interpretation"]["zero_count"].lower() or "zero" in result["interpretation"]["zero_count"].lower()

    @pytest.mark.unit
    def test_eigenvalues_all_present_grid(self, service):
        """Grid with all 9 digits -> at least one positive eigenvalue, fewer than 3 zeros."""
        # Construct digits such that every digit 1-9 appears at least once,
        # producing a full-rank-like matrix with non-trivial structure.
        # Grid: [[2,1,1],[1,2,1],[1,1,2]] -> full rank, determinant non-zero.
        # Requires: digit 4=2, 9=1, 2=1, 3=1, 5=2, 7=1, 8=1, 1=1, 6=2
        digits = [4, 4, 9, 2, 3, 5, 5, 7, 8, 1, 6, 6]
        grid_data = service.build_loshu_grid(digits)
        result = service.compute_eigenvalues(grid_data["grid"])

        evals = result["eigenvalues"]
        assert len(evals) == 3

        # All digits present should mean the grid has no empty cells
        assert len(grid_data["missing"]) == 0

        # Dominant eigenvalue should be positive
        assert result["dominant_eigenvalue"] > 0.0

        # Not all eigenvalues should be zero (grid has energy)
        assert result["zero_eigenvalues"] < 3

    @pytest.mark.unit
    def test_eigenvalues_seeded_ui_profile_stay_real(self, service):
        """The seeded UI-test DOB should not produce complex Cardano roots."""
        # UI harness full profile: 1990-06-15.
        digits = [1, 9, 9, 0, 0, 6, 1, 5]
        report = service.full_numerology_report(digits)

        eigenvalues = report["eigenvalues"]["eigenvalues"]
        assert len(eigenvalues) == 3
        assert all(isinstance(value, float) for value in eigenvalues)

    # ------------------------------------------------------------------
    # Driver / Conductor
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_driver_conductor(self, service):
        """DOB 24/12/1999 -> driver=6, conductor=1."""
        digits = self._dob_24_12_1999()
        result = service.get_driver_conductor(digits)

        assert result["driver"] == 6
        assert result["conductor"] == 1
        assert result["driver_raw"] == 6    # day digits 2+4 = 6
        # sum of all DOB digits = 2+4+1+2+1+9+9+9 = 37
        assert result["conductor_raw"] == 37
        assert result["driver_ruler"] == "Venus"    # 6 -> Venus
        assert result["conductor_ruler"] == "Sun"    # 1 -> Sun
        assert result["driver_is_master"] is False
        assert result["conductor_is_master"] is False

    @pytest.mark.unit
    def test_master_numbers_preserved(self, service):
        """DOB with day=11 -> driver=11 (not 2)."""
        # DOB 11/03/1985 -> digits: [1,1,0,3,1,9,8,5]
        digits = [1, 1, 0, 3, 1, 9, 8, 5]
        result = service.get_driver_conductor(digits)

        # Driver is reduced sum of day digits = 1+1 = 2; but _reduce(11) preserves master
        # Wait, _reduce checks n > 9 AND n not in {11,22,33}. 11 is a master number.
        # So driver_raw = 1+1 = 2. That's already <= 9, so driver = 2.
        # Hmm, to get master 11, the raw day sum needs to be 11.
        # DOB where day digits sum to 11, e.g., 29 -> 2+9=11
        # Actually the code does sum(day_digits) then _reduce. For day=29, digits would be [2,9,...]
        # day_digits = [2,9], sum=11, _reduce(11)=11 (master preserved)
        # But wait - day_digits isn't the literal day, it's the first 2 entries in dob_digits
        # The caller parses DOB into digits. So for DD/MM/YYYY, first 2 entries are DD digits.
        # For day=29 in DD/MM/YYYY: dob_digits starts with [2,9,...]
        # day_digits = [2,9], raw_sum = 11, _reduce(11) = 11 ✓

        digits_master = [2, 9, 0, 3, 1, 9, 8, 5]  # day=29, month=03, year=1985
        result_master = service.get_driver_conductor(digits_master)
        assert result_master["driver"] == 11
        assert result_master["driver_is_master"] is True
        assert result_master["driver_ruler"] == "Unknown"  # 11 not in RULERS (only 1-9)
        assert result_master["driver_raw"] == 11

    # ------------------------------------------------------------------
    # Plane detection
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_planes_detection(self, service):
        """Thought Plane (4-9-2) is complete for 24/12/1999 grid."""
        digits = self._dob_24_12_1999()
        grid_data = service.build_loshu_grid(digits)
        result = service.analyze_planes(grid_data["grid"])

        assert "planes" in result
        assert "completed_planes" in result
        assert "incomplete_planes" in result
        assert result["total_planes"] == 8

        # Thought plane: cells (0,0)=4(1), (0,1)=9(3), (0,2)=2(2) -> all > 0 -> complete
        thought = result["planes"]["thought"]
        assert thought["completed"] is True
        assert thought["filled_count"] == 3

        # Will plane: cells (1,0)=3(0), (1,1)=5(0), (1,2)=7(0) -> all 0 -> incomplete
        will = result["planes"]["will"]
        assert will["completed"] is False
        assert will["filled_count"] == 0

        # Action plane: cells (2,0)=8(0), (2,1)=1(2), (2,2)=6(0) -> partial
        action = result["planes"]["action"]
        assert action["completed"] is False
        assert action["filled_count"] == 1

        assert "thought" in result["completed_planes"]
        assert "will" in result["incomplete_planes"]

    # ------------------------------------------------------------------
    # Phone digit integration
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_phone_digit_integration(self, service):
        """Missing 5, phone sum=5 -> fills_missing=True."""
        digits = self._dob_24_12_1999()
        # Grid missing [3, 5, 6, 7, 8]; phone digit sum = 5 fills the center
        result = service.integrate_phone_digit(digits, phone_digit_sum=5)

        assert result["phone_digit"] == 5
        assert result["fills_missing"] is True
        assert result["fills_cell"] == 5
        assert result["phone_digit_ruler"] == "Mercury"
        assert 3 in result["missing_cells"]
        assert 5 in result["missing_cells"]
        assert "impact" in result

    @pytest.mark.unit
    def test_phone_digit_no_fill(self, service):
        """Phone digit that does not fill any missing cell."""
        digits = self._dob_24_12_1999()
        # 9 is already present (triple), phone digit 9 does NOT fill a gap
        result = service.integrate_phone_digit(digits, phone_digit_sum=9)

        assert result["fills_missing"] is False
        assert result["fills_cell"] is None
        assert result["phone_digit"] == 9

    # ------------------------------------------------------------------
    # Full report
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_full_report_structure(self, service):
        """Verify all expected keys in full numerology report."""
        digits = self._dob_24_12_1999()
        report = service.full_numerology_report(digits)

        # Top-level keys
        assert "grid" in report
        assert "eigenvalues" in report
        assert "planes" in report
        assert "driver_conductor" in report
        assert "summary" in report

        # Summary sub-keys
        summary = report["summary"]
        for key in [
            "structural_health",
            "missing_digits",
            "missing_count",
            "planes_completed",
            "driver",
            "conductor",
            "dominant_eigenvalue",
            "triple_number_warning",
            "gap_guidance",
            "takeaway",
        ]:
            assert key in summary, f"Missing summary key: {key}"

        # Grid sub-keys
        grid = report["grid"]
        for key in ["grid", "counts", "missing", "present", "triple_numbers", "double_numbers", "single_numbers"]:
            assert key in grid, f"Missing grid key: {key}"

        # Eigenvalue sub-keys
        ev = report["eigenvalues"]
        for key in ["eigenvalues", "dominant_eigenvalue", "zero_eigenvalues", "interpretation"]:
            assert key in ev, f"Missing eigenvalue key: {key}"

        # Plane sub-keys
        planes = report["planes"]
        for key in ["planes", "completed_planes", "incomplete_planes", "total_planes", "completed_count"]:
            assert key in planes, f"Missing planes key: {key}"

        # Driver/conductor sub-keys
        dc = report["driver_conductor"]
        for key in [
            "driver", "conductor", "driver_raw", "conductor_raw",
            "driver_ruler", "conductor_ruler",
            "driver_is_master", "conductor_is_master",
        ]:
            assert key in dc, f"Missing DC key: {key}"

    @pytest.mark.unit
    def test_full_report_with_phone(self, service):
        """Report with phone digit includes phone_integration section."""
        digits = self._dob_24_12_1999()
        report = service.full_numerology_report(digits, phone_digit_sum=5)

        assert "phone_integration" in report
        phone = report["phone_integration"]
        assert phone["fills_missing"] is True
        assert phone["phone_digit"] == 5

    @pytest.mark.unit
    def test_master_number_grid_behavior(self, service):
        """Grid constructed from DOB containing master number day (11)."""
        # Day 29 -> driver=11, digits: 2,9,0,1,1,9,9,0 (29/01/1990)
        digits = [2, 9, 0, 1, 1, 9, 9, 0]
        result = service.get_driver_conductor(digits)

        assert result["driver"] == 11
        assert result["driver_is_master"] is True
        # Conductor: sum = 2+9+0+1+1+9+9+0 = 31 → 3+1 = 4
        assert result["conductor"] == 4
        assert result["conductor_is_master"] is False

    @pytest.mark.unit
    def test_empty_grid_dob(self, service):
        """DOB with all zeros -> grid has all zeros, all digits missing."""
        digits = [0, 0, 0, 0, 0, 0, 0, 0]
        result = service.build_loshu_grid(digits)

        assert result["missing"] == list(range(1, 10))
        assert result["present"] == []
        assert result["triple_numbers"] == []
        assert result["double_numbers"] == []

        for row in result["grid"]:
            assert all(cell == 0 for cell in row)
