About This Project
This project was created to solve a common yet frustrating challenge in enterprise IT environments: automating WinGet upgrades at scale using Microsoft Intune, without requiring user interaction or admin approval.

🎯 The Problem
WinGet, Microsoft’s official package manager, is powerful — but out of the box, it is designed to run in a user context and struggles with:

Lack of visibility when run under SYSTEM context

UAC prompts for some updates

Inability to update user-scoped apps

Poor documentation for enterprise deployment

🔧 The Solution
This project delivers a fully automated, Intune-deployable WinGet upgrade system, which:

Installs and configures PowerShell 7

Ensures WinGet is accessible in the SYSTEM environment

Adds necessary system-level PATH entries

Registers the App Installer package if required

Runs regular, silent, SYSTEM-context WinGet upgrade jobs

Avoids user prompts or the need for elevated permissions

✅ Key Benefits
No user interaction or UAC required

Improves device hygiene and reduces vulnerabilities from outdated software

Saves IT teams time by eliminating manual update tasks

Improves endpoint compliance and security posture across the org

This project was built and tested in a real-world deployment at H2M Architects + Engineers, and is adaptable for use in any modern enterprise leveraging Intune.
