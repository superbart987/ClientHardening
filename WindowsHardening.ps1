#######################################
#    Bart Rats          6-11-2023     #
#    Versie 0.1                       #
#    WindowsHardening.ps1             #
#######################################

#---------------------------------------------------------------------------------#
#  Door middel van dit script kan de windows client in 1 keer worden gehardend.   #
#---------------------------------------------------------------------------------#

#Variabelen
$secureusers = 0
$rdp = 0
$updates = 0
$av = 0
$lock = 0
$encryption = 0
$selectie = 0

#Functions
Function WriteList{
    Clear-Host
    Write-Host ("0 = niet geselecteerd, 1 = geselecteerd")
    Write-Host ("1) secureusers= " + $secureusers)
    Write-Host ("2) rdp= " + $rdp)
    Write-Host ("3) updates= " + $updates)
    Write-Host ("4) av= " + $av)
    Write-Host ("5) lock= " + $lock)
    Write-Host ("6) encryption= " + $encryption)
}

while ($selectie -eq 0)
{
    Clear-Host
    WriteList
    Write-Host ("7) Done")
    $keuze = Read-Host "Kies de opties die aangepast moeten worden, als alles geselecteerd is, kies Done"
    switch ($keuze){

        1 {"Secureusers"; $secureusers = 1}
        2 {"rdp"; $rdp = 1}
        3 {"Updates"; $updates = 1}
        4 {"Av"; $av = 1}
        5 {"Lock"; $lock = 1}
        6 {"Encryption"; $encryption = 1}
        7 {"Done"; $selectie = 1}
    }
}

#WriteList

#Securing gebruikers
if ($secureusers -eq 1) {
    #create new user
    $inputtxt = Read-Host "een nieuwe user aanmaken? [ja/nee]"
    if ($inputtxt -eq "ja"){
        $username = Read-Host "Geef de nieuwe gebruiker een naam"
        $passwd = Read-Host "Geef de user een sterk wachtwoord"
        New-LocalUser -Name $username -Password (ConvertTo-SecureString $passwd -AsPlainText -Force)
    }

    #Get all local users, display users and enabled status
    $localUsers = Get-LocalUser
    $enabledusers = @()
    foreach ($user in $localUsers) {
        if ($user.Enabled -eq $true){
            [string[]]$enabledusers += $user.Name
            Write-Host "Gebruikersnaam: $($user.Name)" "Enabled: $($user.Enabled)"
        }
    }
    Clear-Host
    foreach ($user in $enabledusers) {
        Write-Host $enabledusers
    }
    write-host "Done"
    #select user to disable
    while ($disableusers -notcontains "Done"){
        $disableusers = Read-Host "`n Kies een gebruiker en vervolgens Done"
    }
    foreach ($user in $disableusers){
        net user $user /active:no
    }
}

#RDP
if ($rdp -eq 1){
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    while ($rdpusers -notcontains "Done"){
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $rdpusers
        $rdpusers += Read-Host "Welke user mag verbinden met RDP, alle user ingevuld type Done?"
    }
}

#Updates
if ($updates -eq 1){
    #enable automatic updates
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name AUOptions -Value 5
}

#AV
if ($av -eq 1){
    #check antivirus status
    $avstatus = Get-MpComputerStatus
    if ($avstatus.AntivirusEnabled -eq $false){
        MpCmdRun.exe -wdenable
    }
    #update en scan elke dag
    Set-MpPreference -SignatureScheduleDay Everyday
    Set-MpPreference -ScanScheduleDay Everyday 
}

#Lock
if ($lock -eq 1){
    [int]$timeout = Read-Host "Hoe lang moet de inactiviteit zijn voordat de client locked? in minuten"
    $timeout = $timeout * 60
    powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOCONLOCK $timeout
    powercfg.exe /setactive SCHEME_CURRENT
}

#Encryption
if ($encryption -eq 1){
    $windows = Get-ComputerInfo | Select-Object WindowsProductName
    if ($windows -notcontains "Home"){
        $bitlockercheck = Get-BitLockerVolume -MountPoint "C:"
        if ($bitlockercheck.ProtectionStatus -eq "off"){
            $recoveryPassword = Enable-BitLocker -MountPoint "C:" -RecoveryPasswordProtector -UsedSpaceOnly
            Write-Host $recoveryPassword
            $bureaubladPad = [System.IO.Path]::Combine($env:USERPROFILE, 'Desktop')
            $recoveryPassword | Out-File -FilePath $bureaubladPad -Force
        }
    }

    elseif ($windows -notcontains "Home") {
        Write-Host "Huidige windows editie ondersteund geen Bitlocker"
    }
            
}