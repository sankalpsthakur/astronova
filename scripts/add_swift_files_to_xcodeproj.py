#!/usr/bin/env python3
"""Add Swift files to the Astronova Xcode project (project.pbxproj).

Registers 6 new Swift files and properly organizes Self/*.swift files
into a dedicated PBXGroup. LoshuGridView.swift is already registered
but was orphaned in "Recovered References" — moving it into the Self
group alongside the new files.

Safety: operations are additive only (insertions + one targeted group
replacement).  No line is removed globally.  The script writes back
the file and prints what changed.
"""

PROJECT = "/Users/sankalp/Projects/iosapps/astronova/client/astronova.xcodeproj/project.pbxproj"

# ---- Data ----
NEW_SELF = [
    ("SELFNEW0200000000000D", "SELFNEW0100000000000D", "MatrixView.swift"),
    ("SELFNEW0200000000000E", "SELFNEW0100000000000E", "ArchetypeHeaderView.swift"),
    ("SELFNEW0200000000000F", "SELFNEW0100000000000F", "ConstraintCardView.swift"),
    ("SELFNEW02000000000010", "SELFNEW01000000000010", "CosmicMirrorView.swift"),
    ("SELFNEW02000000000011", "SELFNEW01000000000011", "PremiumGateView.swift"),
]

TT_FILEREF   = "TT000000000000000000007"
TT_BUILDFILE = "TT001000000000000000007"
TT_FILENAME  = "PredictionTimelineView.swift"

# Existing Self file refs (01-0C) — already have PBXFileReference + PBXBuildFile
EXISTING_SELF = [f"SELFNEW020000000000{i:02X}" for i in range(1, 0xC + 1)]  # 10 zeros between 02 and hex (total 21 chars)

# ---- Helpers ----
def add_before_marker(content, marker, insertion):
    """Insert text right before *marker* (the marker must be unique)."""
    if marker not in content:
        raise SystemExit(f"MARKER NOT FOUND: {marker!r}")
    return content.replace(marker, insertion + "\n" + marker, 1)


def add_after_marker(content, marker, insertion):
    """Insert text right after *marker* (marker must be unique)."""
    if marker not in content:
        raise SystemExit(f"MARKER NOT FOUND: {marker!r}")
    return content.replace(marker, marker + "\n" + insertion, 1)


def build_file_entry(fileref, buildfile, name):
    return f"\t\t{buildfile} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fileref} /* {name} */; }};"


def file_ref_entry_self(fileref, name):
    return (
        f'\t\t{fileref} /* {name} */ = '
        f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; '
        f'name = {name}; path = AstronovaApp/Features/Self/{name}; sourceTree = "<group>"; }};'
    )


def file_ref_entry_tt(fileref, name):
    return (
        f'\t\t{fileref} /* {name} */ = '
        f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; '
        f'path = Features/TimeTravel/Views/{name}; sourceTree = "<group>"; }};'
    )


# ---- Main ----
def main():
    with open(PROJECT) as f:
        original = f.read()
    c = original

    # --- 1. PBXBuildFile: add 6 entries ---
    bf_entries = "\n".join(
        build_file_entry(fr, bf, name) for fr, bf, name in NEW_SELF
    )
    bf_entries += "\n" + build_file_entry(TT_FILEREF, TT_BUILDFILE, TT_FILENAME)
    c = add_before_marker(c, "/* End PBXBuildFile section */", bf_entries)

    # --- 2. PBXFileReference: add 6 entries ---
    fr_entries = "\n".join(
        file_ref_entry_self(fr, name) for fr, _, name in NEW_SELF
    )
    fr_entries += "\n" + file_ref_entry_tt(TT_FILEREF, TT_FILENAME)
    c = add_before_marker(c, "/* End PBXFileReference section */", fr_entries)

    # --- 3. PBXGroup: create "Self" group ---
    # Build children list: existing 0x01..0x0C + new 0x0D..0x11
    # We need to look up the name for each existing ref from the original file
    import re
    children = []
    for ref in EXISTING_SELF:
        m = re.search(rf'{ref} /\* (.+?) \*/', original)
        label = m.group(1) if m else ref
        children.append(f"\t\t\t\t{ref} /* {label} */,")
    for fr, _, name in NEW_SELF:
        children.append(f"\t\t\t\t{fr} /* {name} */,")

    self_group = (
        f"\t\tSELFGRP0000000000000001 /* Self */ = {{\n"
        f"\t\t\tisa = PBXGroup;\n"
        f"\t\t\tchildren = (\n"
        + "\n".join(children) + "\n"
        f"\t\t\t);\n"
        f"\t\t\tname = Self;\n"
        f"\t\t\tpath = AstronovaApp/Features/Self;\n"
        f'\t\t\tsourceTree = "<group>";\n'
        f"\t\t}};"
    )

    # Insert BEFORE the Onboarding group definition
    marker = '\t\tAA0003000000000000000005 /* Onboarding */ = {'
    c = add_before_marker(c, marker, self_group)

    # --- 4. Add "Self" group to Features group children ---
    features_child_marker = '\t\t\t\tAA0003000000000000000005 /* Onboarding */,'
    c = add_before_marker(
        c, features_child_marker,
        '\t\t\t\tSELFGRP0000000000000001 /* Self */,'
    )

    # --- 5. Add PredictionTimelineView to AstronovaApp group children ---
    # Existing TT files (001-006) are listed in the AstronovaApp group.
    # Add the new one right after the 006 entry (TimeTravelSwarmOverlay).
    astro_tt_marker = '\t\t\t\tTT000000000000000000006 /* TimeTravelSwarmOverlay.swift */,'
    c = add_after_marker(
        c, astro_tt_marker,
        f'\t\t\t\t{TT_FILEREF} /* {TT_FILENAME} */,'
    )

    # --- 6. Sources build phase: add 6 entries ---
    src_marker = '\t\t\t\tSELFNEW0100000000000C /* LoshuGridView.swift in Sources */,'
    src_entries = "\n".join(
        f"\t\t\t\t{bf} /* {name} in Sources */," for _, bf, name in NEW_SELF
    )
    src_entries += "\n" + f"\t\t\t\t{TT_BUILDFILE} /* {TT_FILENAME} in Sources */,"
    c = add_after_marker(c, src_marker, src_entries)

    # --- 7. Clean up "Recovered References": remove Self entries ---
    recovered_old = (
        '\t\tF697EF622F1054730054E084 /* Recovered References */ = {\n'
        '\t\t\tisa = PBXGroup;\n'
        '\t\t\tchildren = (\n'
        '\t\t\t\tSELFNEW02000000000001 /* SelfTabView.swift */,\n'
        '\t\t\t\tSELFNEW02000000000002 /* CosmicPulseView.swift */,\n'
        '\t\t\t\tSELFNEW02000000000003 /* EssenceBar.swift */,\n'
        '\t\t\t\tSELFNEW02000000000004 /* FoundationSection.swift */,\n'
        '\t\t\t\tSELFNEW02000000000005 /* MiniChartWheelView.swift */,\n'
        '\t\t\t\tSELFNEW02000000000006 /* MoreOptionsSheet.swift */,\n'
        '\t\t\t\tSELFNEW02000000000007 /* SelfDataService.swift */,\n'
        '\t\t\t\tSELFNEW02000000000008 /* TodaysEnergyView.swift */,\n'
        '\t\t\t\tSELFNEW02000000000009 /* ProfileCompleteness.swift */,\n'
        '\t\t\t\tSELFNEW0200000000000A /* QuickBirthEditSheet.swift */,\n'
        '\t\t\t\tSELFNEW0200000000000B /* ReportDetailView.swift */,\n'
        '\t\t\t\tSELFNEW0200000000000C /* LoshuGridView.swift */,\n'
        '\t\t\t\tORACLE02000000000001 /* OracleQuotaManager.swift */,\n'
        '\t\t\t\tORACLE02000000000002 /* OracleViewModel.swift */,\n'
        '\t\t\t\tORACLE02000000000003 /* OracleView.swift */,\n'
        '\t\t\t);\n'
        '\t\t\tname = "Recovered References";\n'
        '\t\t\tsourceTree = "<group>";\n'
        '\t\t};'
    )

    recovered_new = (
        '\t\tF697EF622F1054730054E084 /* Recovered References */ = {\n'
        '\t\t\tisa = PBXGroup;\n'
        '\t\t\tchildren = (\n'
        '\t\t\t\tORACLE02000000000001 /* OracleQuotaManager.swift */,\n'
        '\t\t\t\tORACLE02000000000002 /* OracleViewModel.swift */,\n'
        '\t\t\t\tORACLE02000000000003 /* OracleView.swift */,\n'
        '\t\t\t);\n'
        '\t\t\tname = "Recovered References";\n'
        '\t\t\tsourceTree = "<group>";\n'
        '\t\t};'
    )

    if recovered_old in c:
        c = c.replace(recovered_old, recovered_new, 1)
    else:
        print("WARNING: Recovered References block not found — Self files may "
              "remain there. This is harmless but leaves them duplicated in two groups.")

    # Write
    with open(PROJECT, "w") as f:
        f.write(c)

    # Report
    print("=" * 60)
    print("pbxproj updated: /client/astronova.xcodeproj/project.pbxproj")
    print()
    print("New files registered (PBXFileReference + PBXBuildFile + Sources):")
    for _, _, name in NEW_SELF:
        print(f"  Features/Self/{name}")
    print(f"  Features/TimeTravel/Views/{TT_FILENAME}")
    print()
    print("Also moved: 12 Self/*.swift files from 'Recovered References'")
    print("into a new 'Self' group under Features.")
    print()
    print("Missing files (not on disk, skipped):")
    print("  - Features/Onboarding/PhoneVectorStepView.swift")
    print("  - Features/Onboarding/ContextPriorsStepView.swift")
    print("  - Features/Self/AstrocartographyMapView.swift")
    print("  - Features/Self/BayesianSliderView.swift")
    print()
    print("Next: open client/astronova.xcodeproj in Xcode and build.")

if __name__ == "__main__":
    main()
