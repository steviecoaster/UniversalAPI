[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String[]]
    $Domain,

    [Parameter(Mandatory)]
    [String]
    $ContactEmail
)

process {
    if(-not 'Posh-Acme' -in (Get-Module -ListAvailable).Name){
        Install-Module Posh-Acme -Force
    }

    Import-Module Posh-Acme
    Set-PAServer LE_PROD
    New-PAAccount -Contact $ContactEmail

    $pArgs = @{
        CFToken = ($env:Cloudflare | ConvertTo-SecureString -AsPlainText -Force)
    }

    $Domain | Foreach-Object {
        New-PACertificate $_ -Plugin Cloudflare -PluginArgs $pArgs
    }
}