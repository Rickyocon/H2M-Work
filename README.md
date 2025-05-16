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

Adds WinGet to the system-level PATH so it’s recognized under SYSTEM context.

Uses scheduled or Intune-triggered scripts to run winget upgrade commands silently.

Optionally installs PowerShell 7 and ensures the App Installer package is present.

🛠️ Order of Operations

To successfully deploy this solution via Intune, use the following steps:

WingetSystemPath.ps1

Adds the WinGet executable folder to the System PATH.

Ensures winget.exe is recognized under SYSTEM context (used by Intune).

WingetUpdates-SYSTEM.ps1

Executes winget upgrade --all silently, scoped to system-level packages only.

Does not require any user interaction.

Optional:

PowerShell7.ps1

Installs PowerShell 7 if required for your environment or scripts.

Install App Installer (User Context)

WinGet is bundled with this. Must be deployed via Microsoft Store for Business or Company Portal.

If unavailable, consider offline appx deployment (manual or via Intune script).

WingetUpdates-USER.ps1

Runs winget upgrade in user context, useful for on-demand user-initiated updates.

Still prompts for UAC; not silent.

WinGet Registration Script

Re-registers the App Installer package.

Useful if winget is not recognized in elevated PowerShell sessions.

Testing with PsExec.exe

PsExec -s was used to test PowerShell sessions under SYSTEM context, replicating how Intune executes scripts.

✅ Key Benefits

No UAC or user interaction required

Intune-managed, automated software updates

Improved compliance and reduced attack surface

Saves IT time and reduces risk from outdated software

Scalable to thousands of devices with confidence


Saves IT time and reduces risk from outdated apps

Deployable to thousands of devices with confidence
