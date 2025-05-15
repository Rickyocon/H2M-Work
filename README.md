About This Project
This project was created to solve a common challenge in enterprise IT: automating WinGet upgrades silently and at scale using Microsoft Intune, without requiring user permissions, UAC prompts, or manual input.

🎯 The Problem
Although WinGet is a powerful package manager, deploying it and running updates under SYSTEM context introduces several blockers:

It's not available in the system’s PATH by default.

Many packages are user-scoped and need per-user context to update.

Microsoft’s documentation provides very limited guidance on enterprise deployment.

UAC prompts and permissions interfere with automation.

🔧 The Solution
This project builds a complete, working solution that:

Installs PowerShell 7 to ensure compatibility and module access.

Installs (or ensures presence of) the App Installer package from the Microsoft Store.

Adds WinGet to the system-level PATH so it’s recognized in SYSTEM context.

Uses scheduled or Intune-triggered scripts to run winget upgrade commands under SYSTEM context—completely silently.

🛠️ Order of Operations
To successfully deploy this solution, use the following deployment sequence in Intune:

PowerShell7.ps1

Installs the latest version of PowerShell 7 (required for some module and compatibility support).

Install App Installer from the Microsoft Store (User Context)

WinGet is bundled with this. If it's not preinstalled, it must be deployed via Microsoft Store for Business or Company Portal in the user context.

If unavailable, consider alternative offline installers or manual appx deployment (TBD).

WingetSystemPath.ps1

Adds the WinGet executable folder to the System PATH, allowing it to be recognized under SYSTEM context in scheduled tasks or Intune.

WingetUpdates-SYSTEM.ps1

Runs winget upgrade --all silently, system-wide. Only affects packages that are system-scoped.

⚠️ Additional Notes
WingetUpdates-USER.ps1 is an optional script that allows WinGet upgrades in user context. It still requires user interaction/UAC, so it's mostly useful for on-demand upgrades or troubleshooting.

WinGet Registration Script is included to re-register the App Installer package. This is helpful if winget is not recognized in elevated PowerShell, even though it exists.

Testing with PsExec.exe: During development, PsExec -s was used to launch PowerShell in SYSTEM context to simulate Intune behavior and verify winget recognition and functionality.

✅ Key Benefits
No UAC or user interaction required

Intune-managed, automated software updates

Improved compliance, reduced attack surface

Saves IT time and reduces risk from outdated apps

Deployable to thousands of devices with confidence
