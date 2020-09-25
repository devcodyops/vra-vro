########### Windows 10 BluePrint Automated Software Installation ######################
#-----------------------------------------
#--Variables
$cifsDrive = $domain_cifs_driveletter
$cifsServer = $domain_cifs_server
$cifsPath = $domain_cifs_path
$cifsUser = $domain_cifs_username
$cifsPw = $domain_cifs_pw
$cifsUNC = "\\$cifsServer\$cifsPath"
$cifsOfficePath = "Office2016x86"
$cifsChromePath = "Chrome"
$cifsFirefoxPath = "Firefox"
$cifsAdobePath = "Adobe_Reader_DC"
$localdir = "C:\Temp\vRASoftware"

#Install Software True-False User Requested Variables
$installoffice = $officeinstall
$installchrome = $chromeinstall
$installfirefox = $firefoxinstall
$installadobedc = $adobedcinstall

#--Functions
#timeplapse formatter
Function FormatElapsedTime($ts) {
    $elapsedTime = ""
    if ( $ts.Minutes -gt 0 ){$elapsedTime = [string]::Format( "{0:00} min. {1:00}.{2:00} sec.", $ts.Minutes, $ts.Seconds, $ts.Milliseconds / 10 );}
    else{$elapsedTime = [string]::Format( "{0:00}.{1:00} sec.", $ts.Seconds, $ts.Milliseconds / 10 );}
    if ($ts.Hours -eq 0 -and $ts.Minutes -eq 0 -and $ts.Seconds -eq 0){$elapsedTime = [string]::Format("{0:00} ms.", $ts.Milliseconds);}
    if ($ts.Milliseconds -eq 0){$elapsedTime = [string]::Format("{0} ms", $ts.TotalMilliseconds);}
    return $elapsedTime
}

#--Begin Script Actions
#---------------------------------------------------
#convert software component $domain_cifs_pw to secure string to store as creds
$securePW = ConvertTo-SecureString "$cifsPw" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ($cifsUser, $securePW)

#Mount domain CIFS server
Write-Output "Mapping CIFS share ($cifsUNC) to Drive letter: $cifsDrive with domain user $cifsUser"
Try{
    New-PSDrive -Name $cifsDrive -PSProvider FileSystem -Root $cifsUNC -Persist -Credential $creds
}
Catch{
    Write-Output "Unable to map drive"
    Exit $_.Exitcode
}

#Create Local Destination folder for software to be transferred to
If ( -Not (Test-Path $localdir) ){
    New-Item -ItemType Directory -Path $localdir | Out-Null
}
# If Software was Checked at vRA Request time, copy software and install
#---------------------
#
#--Microsoft Office--#

If ($installoffice -eq "Yes"){
    # Copy Installer files from CIFS Share
    Write-Output "Copying Microsoft Office software from domain CIFS Share"
        Try {
            $mc = Measure-Command {Copy-Item ${cifsDrive}:$cifsOfficePath $localdir -Recurse -ErrorAction Stop}
            $swc = FormatElapsedTime ($mc)
            Write-Output "Copy took $swc to transfer"
        }
        Catch{
            Write-Output "Failed to copy installer binaries"
            Write-Error $_.Exception
            Exit $_.ExitCode
        }
    # Unblock the Office installer binaries
    Write-Output "Unblocking $localdir\$cifsOfficePath files"
        Try {
            Get-ChildItem -Path "$localdir\$cifsOfficePath" -Recurse | Unblock-File -Confirm:$false  -ErrorAction Stop
        }
        Catch{
           Write-Output "Failed to unblock $logTitle installer binaries"
           Write-Error $_.Exception
           Exit $_.ExitCode
        }
    #-Begin Install of Office Software
    #
    Write-Output "Checking Windows Installer Status"
    #--Check if Windows Installer Service is already Running--#
    $svc = "msiserver"
    $svcquery = Get-Service -Name $svc
    $svcstatus = $svcquery.Status
    #write-output "$svcstatus"
    #--If Windows Insaller Service found running check if busy installing other software--#
    If ($svcstatus -eq "Running"){
        Write-Output "Windows Installer Service already running, Checking if busy"
        Do {
            #$installerbusy = Get-Process -name msiexec | Where-Object -Property SI -ne 0
            #$installerbusy = Get-Process -name msiexec | Where-Object -Property CPU -ne $null
            $installerbusy = gwmi win32_process -Filter "name='msiexec.exe'" | where {$_.CommandLine -ne "C:\Windows\System32\msiexec.exe /V" -and $_.CommandLine -ne $null}
            If ($installerbusy -ne $null) {
                Write-Output "Windows Installer Currently busy with a vRA external installation, waiting..."
                Start-Sleep 10
            }
        } Until ($installerbusy -eq $null)
    }
    Write-Output "Windows Installer Service is not busy, Proceeding with Software Install"
    #
    # Change directory to the installer folder
	$InstallerPath = "$localdir\$cifsOfficePath"
	$AdminFilePath = "$localdir\$cifsOfficePath"
	
	$Arguments = "/AdminFile $AdminFilePath"
	
	
	# Perform Office installation with timer
	Write-Output "RUNNING COMMAND: $InstallerPath\setup.exe $Arguments"
	$time = [System.Diagnostics.Stopwatch]::StartNew()
	$output = Start-Process "$InstallerPath\setup.exe" -ArgumentList $Arguments -Passthru -Wait
	$time.Stop()
	$sw = FormatElapsedTime($time.Elapsed)
	If ($Output.ExitCode -ne 0){
		Write-Output "Failed to install Office from $cifsOfficePath, exitcode: $($Output.ExitCode)"
		Write-Output $Output.Exception
		Exit $Output.ExitCode
	}
	Else{
		Write-Output "$cifsOfficePath Installed successfully. Install took $sw"
        #Cleanup Installer files off disk
        Write-Output "Cleaning up $localdir\$cifsOfficePath install files"
        Remove-Item -Path $localdir\$cifsOfficePath -Recurse -ErrorAction Stop
	}

}
#--Google Chrome--#

If ($installchrome -eq "Yes"){
    # Copy Installer files from CIFS Share
    Write-Output "Copying Google Chrome software from domain CIFS Share"
        Try {
            $mc = Measure-Command {Copy-Item ${cifsDrive}:$cifsChromePath $localdir -Recurse -ErrorAction Stop}
            $swc = FormatElapsedTime ($mc)
            Write-Output "Copy took $swc to transfer"
        }
        Catch{
            Write-Output "Failed to copy installer binaries"
            Write-Error $_.Exception
            Exit $_.ExitCode
        }
    # Unblock the Chrome installer binaries
    Write-Output "Unblocking $localdir\$cifsChromePath files"
        Try {
            Get-ChildItem -Path "$localdir\$cifsChromePath" -Recurse | Unblock-File -Confirm:$false  -ErrorAction Stop
        }
        Catch{
           Write-Output "Failed to unblock $logTitle installer binaries"
           Write-Error $_.Exception
           Exit $_.ExitCode
        }
    #-Begin Install of Chrome Software
    #
    Write-Output "Checking Windows Installer Status"
    #--Check if Windows Installer Service is already Running--#
    $svc = "msiserver"
    $svcquery = Get-Service -Name $svc
    $svcstatus = $svcquery.Status
    #write-output "$svcstatus"
    #--If Windows Insaller Service found running check if busy installing other software--#
    If ($svcstatus -eq "Running"){
        Write-Output "Windows Installer Service already running, Checking if busy"
        Do {
            #$installerbusy = Get-Process -name msiexec | Where-Object -Property SI -ne 0
            #$installerbusy = Get-Process -name msiexec | Where-Object -Property CPU -ne $null
            $installerbusy = gwmi win32_process -Filter "name='msiexec.exe'" | where {$_.CommandLine -ne "C:\Windows\System32\msiexec.exe /V" -and $_.CommandLine -ne $null}
            If ($installerbusy -ne $null) {
                Write-Output "Windows Installer Currently busy with a vRA external installation, waiting..."
                Start-Sleep 10
            }
        } Until ($installerbusy -eq $null)
    }
    Write-Output "Windows Installer Service is not busy, Proceeding with Software Install"
    # Change directory to the installer folder
	$InstallerPath = "$localdir\$cifsChromePath"
	#$AdminFilePath = "$localdir\$cifsChromePath"
	
	#$Arguments = "/AdminFile $AdminFilePath"
	$Arguments = "/i $InstallerPath\GoogleChromeStandaloneEnterprise64.msi /q"
	
	# Perform Chrome installation with timer
	Write-Output "RUNNING COMMAND: MSIexec to install Chrome"
	$time = [System.Diagnostics.Stopwatch]::StartNew()
	$output = Invoke-Command -ScriptBlock {Start-Process "C:\Windows\system32\msiexec.exe" -Wait -ArgumentList $Arguments}
	$time.Stop()
	$sw = FormatElapsedTime($time.Elapsed)
    
    #Validate Chrome Install
    $software = "Chrome"
    $installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where {$_.DisplayName -match "$software"}) -ne $null
	If (-Not $installed){
		Write-Output "Failed to install Chrome from $cifsChromePath"
		Exit 1
	}
	Else{
		Write-Output "$cifsChromePath Installed successfully. Install took $sw"
        #Cleanup Installer files off disk
        Write-Output "Cleaning up $localdir\$cifsChromePath install files"
        Remove-Item -Path $localdir\$cifsChromePath -Recurse -ErrorAction Stop
	}
}
#--Mozilla Firefox--#

If ($installfirefox -eq "Yes"){
    # Copy Installer files from CIFS Share
    Write-Output "Copying Mozilla Firefox software from domain CIFS Share"
        Try {
            $mc = Measure-Command {Copy-Item ${cifsDrive}:$cifsFirefoxPath $localdir -Recurse -ErrorAction Stop}
            $swc = FormatElapsedTime ($mc)
            Write-Output "Copy took $swc to transfer"
        }
        Catch{
            Write-Output "Failed to copy installer binaries"
            Write-Error $_.Exception
            Exit $_.ExitCode
        }
    # Unblock the Firefox installer binaries
    Write-Output "Unblocking $localdir\$cifsFirefoxPath files"
        Try {
            Get-ChildItem -Path "$localdir\$cifsFirefoxPath" -Recurse | Unblock-File -Confirm:$false  -ErrorAction Stop
        }
        Catch{
           Write-Output "Failed to unblock $logTitle installer binaries"
           Write-Error $_.Exception
           Exit $_.ExitCode
        }
    #-Begin Install of Firefox Software
    #
    Write-Output "Checking Windows Installer Status"
    #--Check if Windows Installer Service is already Running--#
    $svc = "msiserver"
    $svcquery = Get-Service -Name $svc
    $svcstatus = $svcquery.Status
    #write-output "$svcstatus"
    #--If Windows Insaller Service found running check if busy installing other software--#
    If ($svcstatus -eq "Running"){
        Write-Output "Windows Installer Service already running, Checking if busy"
        Do {
            #$installerbusy = Get-Process -name msiexec | Where-Object -Property SI -ne 0
            #$installerbusy = Get-Process -name msiexec | Where-Object -Property CPU -ne $null
            $installerbusy = gwmi win32_process -Filter "name='msiexec.exe'" | where {$_.CommandLine -ne "C:\Windows\System32\msiexec.exe /V" -and $_.CommandLine -ne $null}
            If ($installerbusy -ne $null) {
                Write-Output "Windows Installer Currently busy with a vRA external installation, waiting..."
                Start-Sleep 10
            }
        } Until ($installerbusy -eq $null)
    }
    Write-Output "Windows Installer Service is not busy, Proceeding with Software Install"
    #
    # Change directory to the installer folder
	$InstallerPath = "$localdir\$cifsFirefoxPath"
	#$AdminFilePath = "$localdir\$cifsFirefoxPath"
	
	#$Arguments = "/AdminFile $AdminFilePath"
	$Arguments = "/i $InstallerPath\Firefox_Setup_69.0.msi /q"
	
	# Perform Firefox installation with timer
	Write-Output "RUNNING COMMAND: MSIexec to install Firefox"
	$time = [System.Diagnostics.Stopwatch]::StartNew()
	$output = Invoke-Command -ScriptBlock {Start-Process "C:\Windows\system32\msiexec.exe" -Wait -ArgumentList $Arguments}
	$time.Stop()
	$sw = FormatElapsedTime($time.Elapsed)
    
    #Validate Firefox Install
    $software = "Firefox"
    $installed = (Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where {$_.DisplayName -match "$software"}) -ne $null
	If (-Not $installed){
		Write-Output "Failed to install Firefox from $cifsFirefoxPath"
		Exit 1
	}
	Else{
		Write-Output "$cifsFirefoxPath Installed successfully. Install took $sw"
        #Cleanup Installer files off disk
        Write-Output "Cleaning up $localdir\$cifsFirefoxPath install files"
        Remove-Item -Path $localdir\$cifsFirefoxPath -Recurse -ErrorAction Stop
	}
}
#--Adobe Reader DC--#

If ($installadobedc -eq "Yes"){
    # Copy Installer Files from CIFS Share
    Write-Output "Copying Adobe Reader DC software from domain CIFS Share"
        Try {
            $mc = Measure-Command {Copy-Item ${cifsDrive}:$cifsAdobePath $localdir -Recurse -ErrorAction Stop}
            $swc = FormatElapsedTime ($mc)
            Write-Output "Copy took $swc to transfer"
        }
        Catch{
            Write-Output "Failed to copy installer binaries"
            Write-Error $_.Exception
            Exit $_.ExitCode
        }
    # Unblock the Adobe Reader installer binaries
    Write-Output "Unblocking $localdir\$cifsAdobePath files"
        Try {
            Get-ChildItem -Path "$localdir\$cifsAdobePath" -Recurse | Unblock-File -Confirm:$false  -ErrorAction Stop
        }
        Catch{
           Write-Output "Failed to unblock $logTitle installer binaries"
           Write-Error $_.Exception
           Exit $_.ExitCode
        }
    #-Begin Install of Adobe Reader DC Software
    #
    Write-Output "Checking Windows Installer Status"
    #--Check if Windows Installer Service is already Running--#
    $svc = "msiserver"
    $svcquery = Get-Service -Name $svc
    $svcstatus = $svcquery.Status
    #write-output "$svcstatus"
    #--If Windows Insaller Service found running check if busy installing other software--#
    If ($svcstatus -eq "Running"){
        Write-Output "Windows Installer Service already running, Checking if busy"
        Do {
            #$installerbusy = Get-Process -name msiexec | Where-Object -Property SI -ne 0
            #$installerbusy = Get-Process -name msiexec | Where-Object -Property CPU -ne $null
            $installerbusy = gwmi win32_process -Filter "name='msiexec.exe'" | where {$_.CommandLine -ne "C:\Windows\System32\msiexec.exe /V" -and $_.CommandLine -ne $null}
            If ($installerbusy -ne $null) {
                Write-Output "Windows Installer Currently busy with a vRA external installation, waiting..."
                Start-Sleep 10
            }
        } Until ($installerbusy -eq $null)
    }
    Write-Output "Windows Installer Service is not busy, Proceeding with Software Install"
    #
    # Change directory to the installer folder
	$InstallerPath = "$localdir\$cifsAdobePath"
	#$AdminFilePath = "$localdir\$cifsAdobePath"
	
	#$Arguments = "/AdminFile $AdminFilePath"
	#$Arguments = "/i $InstallerPath\AcroRdrDC1902120047_en_US.exe /sAll"
    $Arguments = "/i /sAll"
	
	# Perform Adobe Reader DC installation with timer
	Write-Output "RUNNING COMMAND: $InstallerPath\AcroRdrDC1902120047_en_US.exe to install Adobe Reader"
	$time = [System.Diagnostics.Stopwatch]::StartNew()
	#$output = Invoke-Command -ScriptBlock {Start-Process "C:\Windows\system32\msiexec.exe" -Wait -ArgumentList $Arguments}
    $output = Start-Process "$InstallerPath\AcroRdrDC1902120047_en_US.exe" -ArgumentList $Arguments -Passthru -Wait
	$time.Stop()
	$sw = FormatElapsedTime($time.Elapsed)
    
    #Validate Adobe Reader Install
    $software = "Adobe Acrobat Reader DC"
    #$installed = (Get-WmiObject -Query "SELECT * FROM Win32_Product Where Vendor Like $software" | Select-Object Name,Version,Vendor,InstallLocation ) -ne $null
    $installed = (Get-WmiObject -Query "SELECT * FROM Win32_Product Where Name Like '%$software%'" | Select-Object Name,Version,Vendor,InstallLocation ) -ne $null
	If (-Not $installed){
		Write-Output "Failed to install Adobe Reader DC from $cifsAdobePath"
		Exit 1
	}
	Else{
		Write-Output "$cifsAdobePath Installed successfully. Install took $sw"
        #Cleanup Installer files off disk
        Write-Output "Cleaning up $localdir\$cifsAdobePath install files"
        Remove-Item -Path $localdir\$cifsAdobePath -Recurse -ErrorAction Stop
	}
}