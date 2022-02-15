[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]
    $Module,

    [Parameter()]
    [String]
    $Version,

    [Parameter()]
    [String]
    $PushPackage
)

begin {

    $date = Get-Date -Format 'yyyyMMdd-HHmmss'
    $null = Start-Transcript "C:\Universal_Transcripts\$Module-$($date).txt"

    Function Get-ChocolateyNewArgs {
        [cmdletBinding()]
        param(
            [Parameter()]
            [psobject]
            $manifest
        )
        process {
            #Construct choco arguments
            $chocoArgs = @()

            $chocoArgs += 'new'
            $chocoArgs += "$PackageName"
            $chocoArgs += "--template='powershell.template'"
            Write-Debug -Message ($chocoArgs -join ' ')

            $Version = $metadata.Version.ToString()
            $chocoArgs += "PackageVersion=$Version"
            Write-Debug -Message ($chocoArgs -join ' ')

            $Author = $metadata.Author
            $chocoArgs += "Author=$Author"
            Write-Debug -Message ($chocoArgs -join ' ')

            $ProjectUri = $metadata.ProjectUri
            $chocoArgs += "ProjectUri=$ProjectUri"
            Write-Debug -Message ($chocoArgs -join ' ')


            $LicenseUri = $metadata.LicenseUri
            $chocoArgs += "LicenseUri=$LicenseUri"

            $HelpInfoUri = $metadata.HelpInfoUri

            Write-Debug -Message ($chocoArgs -join ' ')

            $Description = $metadata.Description
            $Tags = $metadata.Tags | Select -Unique
            $ReleaseNotes = $metadata.ReleaseNotes

            if(-not $ReleaseNotes) {
                $ReleaseNotes = $ProjectUri
                $chocoArgs += "ReleaseNotes=$ReleaseNotes"
                Write-Debug -Message ($chocoArgs -join ' ')

            } else {
                $chocoArgs += "ReleaseNotes=$ReleaseNotes"
                Write-Debug -Message ($chocoArgs -join ' ')

            }

            if(-not $HelpInfoUri){
                $HelpInfoUri = $ProjectUri
                $chocoArgs += "HelpInfoUri=$HelpInfoUri"
                Write-Debug -Message ($chocoArgs -join ' ')

            } else {
                $chocoArgs += "HelpInfoUri=$HelpInfoUri"
                Write-Debug -Message ($chocoArgs -join ' ')
            }

            if($Tags){
                $chocoArgs += "Tags='$Tags'"
                Write-Debug -Message ($chocoArgs -join ' ')
            }

            if($Description){
                $chocoArgs += "Description=$Description"
            } else {
                $chocoArgs += "Description='Chocolatey Package of the $Module PowerShell Module'"
            }

            
            $chocoArgs += "Module=$Module"

            return $chocoArgs
        }
    }

    Function ConvertTo-ChocoPackage {
        [CmdletBinding()]
        Param()

        process {
            #Create zip archive
            $Source = Join-Path $SavePath -ChildPath $Module
            $Destination = Join-Path $SavePath -ChildPath "$Module.zip"
            Compress-Archive -Path $Source -DestinationPath $Destination

            try {
                #create the package
                $newArgs = Get-ChocolateyNewArgs
                $null = & choco @newArgs --output-directory $PackagePath
            }
            
            catch {
                #New-PSUApiResponse -Body 'Package creation failed. Cannot continue.' -StatusCode 500
            }

            do {
                Start-Sleep -Milliseconds 100
            } until ((Test-Path $toolsDir))

            #Copy Module zip to package tools folder
            Copy-Item $Destination -Destination $toolsDir

            try {
            #Pack Chocolatey Package
            $nuspecFile = Get-ChildItem $PackagePath -Recurse -Filter *.nuspec
            $packArgs = @('pack',"$($nuspecFile.FullName)","--output-directory='$PackagePath'")
            $null = & choco @packArgs
            }
            catch {
                #New-PSUApiResponse -Body "Pack operation failed. Cannot continue" -StatusCode 500
            }

            try {
            
            #New-PSUApiResponse -Body "https://universal.steviecoaster.dev/package/$($nupkgFile.Name)" -StatusCode 200
            } catch {
                #New-PSUApiResponse -Body 'Push operation failed. Cannot continue' -StatusCode 500
            }
        }
    }

    Function Remove-ModuleFiles {
        process {
            Get-ChildItem $SavePath | Remove-Item -Recurse -Force
            Get-ChildItem $PackagePath | Remove-Item -Recurse -Force
        }
    }

    Function Move-Package {
        process {
            $file = Get-ChildItem $PackagePath -Filter *.nupkg 
            $file | Copy-Item -Destination $OutputFolder

            @{
                DownloadLink = "https://universal.steviecoaster.dev/package/$($file.Name)"
                Message = "This link expires after 10 days"
            }
        }
    }
}
process {

    $SavePath = 'C:\drop'
    $PackagePath = 'C:\package'
    $OutputFolder = 'C:\completed_packages'
    $PackageName = "$Module.powershell"
    $toolsDir = Join-Path $PackagePath -ChildPath "$PackageName\tools"

    Remove-ModuleFiles

    if($Version){
        Save-Module -Name $Module -RequiredVersion $Version -Path $SavePath
    } else {
        Save-Module -Name $Module -Path $SavePath
    }

    $pattern = [regex]::Escape($module) + '.psd1'
    $manifest = Get-ChildItem $SavePath -Recurse -Filter *.psd1 | Where-Object Name -match $pattern
    try {
        $metadata = Test-ModuleManifest $manifest.FullName -ErrorAction Stop
    }
    catch {
        New-PSUApiResponse -Body $_.Exception.Message -StatusCode 500
    }

    if(-not $metadata.ProjectUri){
        
        Remove-ModuleFiles

    } 

    else {
        ConvertTo-ChocoPackage
        Move-Package
    }    

}

end {
    Remove-ModuleFiles
    $null = Stop-Transcript
}
