[CmdletBinding()]
param(
    [Parameter()]
    $Thumbprint
)

process {
    if ((Test-Path C:\ProgramData\nexus\etc\ssl\keystore.jks)) {
        Remove-Item C:\ProgramData\nexus\etc\ssl\keystore.jks -Force
    }

    $KeyTool = "C:\ProgramData\nexus\jre\bin\keytool.exe"
    $password = "chocolatey" | ConvertTo-SecureString -AsPlainText -Force
    $certificate = Get-ChildItem  Cert:\LocalMachine\TrustedPeople\ | Where-Object { $_.Thumbprint -eq $Thumbprint } | Sort-Object | Select-Object -First 1

    Write-Host "Exporting .pfx file to C:\, will remove when finished" -ForegroundColor Green
    $certificate | Export-PfxCertificate -FilePath C:\cert.pfx -Password $password
    Get-ChildItem -Path c:\cert.pfx | Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -Exportable -Password $password
    Write-Warning -Message "You'll now see prompts and other outputs, things are working as expected, don't do anything"
    $string = ("chocolatey" | & $KeyTool -list -v -keystore C:\cert.pfx) -match '^Alias.*'
    $currentAlias = ($string -split ':')[1].Trim()

    $passkey = '9hPRGDmfYE3bGyBZCer6AUsh4RTZXbkw'
    & $KeyTool -importkeystore -srckeystore C:\cert.pfx -srcstoretype PKCS12 -srcstorepass chocolatey -destkeystore C:\ProgramData\nexus\etc\ssl\keystore.jks -deststoretype JKS -alias $currentAlias -destalias jetty -deststorepass $passkey
    & $KeyTool -keypasswd -keystore C:\ProgramData\nexus\etc\ssl\keystore.jks -alias jetty -storepass $passkey -keypass chocolatey -new $passkey

    $xmlPath = 'C:\ProgramData\nexus\etc\jetty\jetty-https.xml'
    [xml]$xml = Get-Content -Path 'C:\ProgramData\nexus\etc\jetty\jetty-https.xml'
    foreach ($entry in $xml.Configure.New.Where{ $_.id -match 'ssl' }.Set.Where{ $_.name -match 'password' }) {
        $entry.InnerText = $passkey
    }

    $xml.OuterXml | Set-Content -Path $xmlPath

    Remove-Item C:\cert.pfx

    $nexusPath = 'C:\ProgramData\sonatype-work\nexus3'
    $configPath = "$nexusPath\etc\nexus.properties"

    $configStrings = @('jetty.https.stsMaxAge=-1', 'application-port-ssl=8443', 'nexus-args=${jetty.etc}/jetty.xml,${jetty.etc}/jetty-https.xml,${jetty.etc}/jetty-requestlog.xml')
    $configStrings | ForEach-Object {
        if ((Get-Content -Raw $configPath) -notmatch [regex]::Escape($_)) {
            $_ | Add-Content -Path $configPath
        }
    }

    Restart-Service nexus
    
}