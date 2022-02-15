[CmdletBinding()]
Param(
    [Parameter()]
    [String]
    $Domain = 'universal.steviecoaster.dev'
)

begin { Stop-Service PowerShellUniversal }

process {
    $settings = "C:\Program Files (x86)\Universal\appsettings.json"
    $currentSettings = Get-Content $settings | ConvertFrom-Json

   
    $endpoints = @{
            https = @{
                url = 'https://*:443' ; 
                Certificate = @{ 
                    Subject = $Domain ; 
                    Store = 'TrustedPeople' ; Location = 'LocalMachine' ; 
                    AllowInvalid = $false 
                }
            }
        }

     
    $currentSettings.Kestrel.Endpoints = $endpoints
    $currentSettings | ConvertTo-Json -Depth 4 | Set-Content $settings -Force

}

end { Start-Service PowerShellUniversal }