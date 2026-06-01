Make sure to always check scripts file paths to make sure they will copy and run correctly

intune -> winget is the GitHub package -> winget powershell installed powershell ver 7 -> winget registration makes winget work in adin powershell if its not working -> winget system path config maps system paths to winget.exe

save PsExec.exe from PSTools to local C drive then create a folder called WingetTesting in your local C , move PsExec.exe to that folder then run Start-Process -FilePath cmd.exe -Verb Runas -ArgumentList '/k C:\WingetTesting\PsExec.exe -i -s powershell.exe' -> this will open a command promt that is running under SYSTEM, do a whoami command to confirm. From here you can test to see if winget is recognized as a command in the system context

information:

https://nialljen.wordpress.com/2023/05/14/running-windows-package-manager-winget-in-the-system-context/#:~:text=Now%20we%20have%20a%20location,and%20run%20the%20following%20commands

https://scloud.work/how-to-winget-intune/


https://learn.microsoft.com/en-us/windows/package-manager/winget/


https://learn.microsoft.com/en-us/answers/questions/1688882/how-do-we-fix-0x8a15000f-data-required-by-the-sour


https://chatgpt.com/canvas/shared/68238466f234819191237ac3de0ad158



