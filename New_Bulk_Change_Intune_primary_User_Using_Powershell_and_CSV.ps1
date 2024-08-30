 # <Update or Change Inutne Primary User Using PowerShell>
#.DESCRIPTION
 # <Update or Change Inutne Primary User Using PowerShell>
#.Demo
#<YouTube video link-->https://www.youtube.com/@ChanderManiPandey
#.INPUTS
 # <Provide all required inforamtion in User Input Section-line No 29-30>
#.OUTPUTS
 # <This will chage the Change Primary in Intune portal>
#.NOTES
 <# Version:       1.0
  Author:          Chander Mani Pandey
  Creation Date:   8 Oct 2023
  
  Find Author on 
  Youtube:-         https://www.youtube.com/@chandermanipandey8763
  Twitter:-           https://twitter.com/Mani_CMPandey
  LinkedIn:-         https://www.linkedin.com/in/chandermanipandey
  
 #>

cls
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' 
$error.clear() ## this is the clear error history 

# ==============================User Input Section Start=============================================================================================================
$Path = "C:\Temp\IntuneReporting\ChangePrimaryUser"
$FilePath = "C:\TEMP\IntuneReporting\ChangePrimaryUser\InputFile.csv"
$tenant = “abc.onmicrosoft.com”                                  # https://www.youtube.com/watch?v=h7BwDBtBo8Q
$clientId = “b2b2d492-6ec6-4276-a027-8ea534”                     # https://www.youtube.com/watch?v=h7BwDBtBo8Q
$clientSecret = “0G18Q~e2uJFXDfb_TrXS9NDRnKwQo_dxH”              # https://www.youtube.com/watch?v=h7BwDBtBo8Q

# ==============================User Input Section End===============================================================================================================



$Inputfile = Import-Csv -Path $FilePath
$LogPath = Join-Path -Path $Path -ChildPath "ChangePrimaryUser.txt"

# Check if the log directory exists; if not, create it
if (-not (Test-Path -Path $Path)) {
    New-Item -Path $Path -ItemType Directory -Force
}

# Check if the log file exists; if not, create it
if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType File
}

# Function to write log messages to the log file
function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    
    $FormattedLog = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Host $FormattedLog -ForegroundColor $Color
    $FormattedLog | Out-File -FilePath $LogPath -Append
}

# Log the script start
Write-Log -Message "Script started" -Color "White"

# Install and import the Microsoft.Graph.Intune module if not already installed
$MGIModule = Get-Module -Name "Microsoft.Graph.Intune" -ListAvailable
if ($MGIModule -eq $null) {
    Install-Module -Name Microsoft.Graph.Intune -Force
}
Import-Module Microsoft.Graph.Intune -Force

# Connect to Microsoft Graph
$authority = “https://login.windows.net/$tenant”
Update-MSGraphEnvironment -AppId $clientId -Quiet
Update-MSGraphEnvironment -AuthUrl $authority -Quiet
Connect-MSGraph -ClientSecret $ClientSecret 
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet

# Get the total number of devices in the CSV file
$totalDevices = $Inputfile.Count
Write-Log -Message "Total devices in CSV: $totalDevices" -Color "White"
Write-Host ""

# Initialize a counter for device progress
$deviceCounter = 0

foreach ($In in $Inputfile) {
    $deviceCounter++
    
    # Check if the new user name is equal to the old user name, and skip the update if they are the same
    if ($In.NewUserName -eq $In.userPrincipalName) {
        $message = "Skipping update for $deviceCounter/$totalDevices devices - New and old user names are the same: $($In.NewUserName)"
        Write-Host $message -ForegroundColor Yellow
        Write-Log -Message $message -Color "Green"
        Write-Host "==============================================================================================================================================================="
        continue
    }

    $message = "Updating $deviceCounter/$totalDevices devices - New Primary User Name: $($In.NewUserName) / $($In.DeviceName) and Old Primary User Name $($In.userPrincipalName)..."
    Write-Host $message -ForegroundColor Yellow
    Write-Log -Message $message -Color "Green"

     $graphApiVersion = "beta"
     $Resource = "deviceManagement/managedDevices('$($In.id)')/users/`$ref"
     $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
     $userUri = "https://graph.microsoft.com/$graphApiVersion/users/" + $($In.NewUserID)
     $JSON = @{
         "@odata.id" = $userUri
     }
    
     try {
         Invoke-MSGraphRequest -HttpMethod Post -Url $uri -Content $JSON
         $successMessage = "Successfully updated the primary user."
         Write-Host $successMessage -ForegroundColor Green
         Write-Log -Message $successMessage -Color "Green"
         Write-Host "============================================================================================================================================================="
     } catch {
         $errorMessage = "An error occurred: $_"
         Write-Host $errorMessage
         Write-Log -Message $errorMessage -Color "Red"
         if ($_.ErrorDetails) {
             $errorDetails = "Error Details:`n$($_.ErrorDetails)"
             Write-Host $errorDetails
             Write-Log -Message $errorDetails -Color "Red"
         }
     }
}

# Log the script completion
Write-Log -Message "Script completed" -Color "White"