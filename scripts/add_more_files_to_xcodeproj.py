#!/usr/bin/env python3
"""Incremental addition: 6 more Swift files that appeared from parallel agents.

To be run AFTER add_swift_files_to_xcodeproj.py has already been applied.
"""
import re

PROJECT = "/Users/sankalp/Projects/iosapps/astronova/client/astronova.xcodeproj/project.pbxproj"

# Additional files to register (fileref, buildfile, name, group, relative_path)
MORE_FILES = [
    # Self group
    ("SELFNEW02000000000012", "SELFNEW01000000000012", "AstrocartographyMapView.swift",
     "Self", "AstronovaApp/Features/Self/AstrocartographyMapView.swift"),
    ("SELFNEW02000000000013", "SELFNEW01000000000013", "BayesianSliderView.swift",
     "Self", "AstronovaApp/Features/Self/BayesianSliderView.swift"),
    # Onboarding group
    ("ONBRD0200000000000001", "ONBRD0100000000000001", "PhoneVectorStepView.swift",
     "Onboarding", "AstronovaApp/Features/Onboarding/PhoneVectorStepView.swift"),
    ("ONBRD0200000000000002", "ONBRD0100000000000002", "ContextPriorsStepView.swift",
     "Onboarding", "AstronovaApp/Features/Onboarding/ContextPriorsStepView.swift"),
    # Services group
    ("SRVCS0200000000000001", "SRVCS0100000000000001", "APIModelMappings.swift",
     "Services", "AstronovaApp/Services/APIModelMappings.swift"),
    ("SRVCS0200000000000002", "SRVCS0100000000000002", "SynthesisService.swift",
     "Services", "AstronovaApp/Services/SynthesisService.swift"),
]

with open(PROJECT) as f:
    c = f.read()

# --- 1. PBXBuildFile entries ---
bf_lines = []
for fr, bf, name, grp, rp in MORE_FILES:
    bf_lines.append(
        f"\t\t{bf} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};"
    )
c = c.replace("/* End PBXBuildFile section */",
              "\n".join(bf_lines) + "\n/* End PBXBuildFile section */")

# --- 2. PBXFileReference entries ---
fr_lines = []
for fr, bf, name, grp, rp in MORE_FILES:
    fr_lines.append(
        f'\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; '
        f'name = {name}; path = {rp}; sourceTree = "<group>"; }};'
    )
c = c.replace("/* End PBXFileReference section */",
              "\n".join(fr_lines) + "\n/* End PBXFileReference section */")

# --- 3. Add to Self group children (after PremiumGateView.swift) ---
self_marker = '\t\t\t\tSELFNEW02000000000011 /* PremiumGateView.swift */,'
self_add = '\t\t\t\tSELFNEW02000000000012 /* AstrocartographyMapView.swift */,\n\t\t\t\tSELFNEW02000000000013 /* BayesianSliderView.swift */,'
c = c.replace(self_marker, self_marker + "\n" + self_add)

# --- 4. Add to Onboarding group children ---
onboarding_marker = '\t\tAA0003000000000000000005 /* Onboarding */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = ('
onboarding_add = '\t\t\t\tONBRD0200000000000001 /* PhoneVectorStepView.swift */,\n\t\t\t\tONBRD0200000000000002 /* ContextPriorsStepView.swift */,'
c = c.replace(onboarding_marker, onboarding_marker + "\n" + onboarding_add)

# --- 5. Add to Services group children (after SessionTracker.swift) ---
svc_marker = '\t\t\t\tWAVE13ST00000000000001 /* SessionTracker.swift */,'
svc_add = '\t\t\t\tSRVCS0200000000000001 /* APIModelMappings.swift */,\n\t\t\t\tSRVCS0200000000000002 /* SynthesisService.swift */,'
c = c.replace(svc_marker, svc_marker + "\n" + svc_add)

# --- 6. Sources build phase (after PredictionTimelineView) ---
src_marker = '\t\t\t\tTT001000000000000000007 /* PredictionTimelineView.swift in Sources */,'
src_add_lines = []
for fr, bf, name, grp, rp in MORE_FILES:
    src_add_lines.append(f"\t\t\t\t{bf} /* {name} in Sources */,")
c = c.replace(src_marker, src_marker + "\n" + "\n".join(src_add_lines))

with open(PROJECT, "w") as f:
    f.write(c)

print("Added 6 more files to pbxproj:")
for _, _, name, grp, _ in MORE_FILES:
    print(f"  {grp}/{name}")
