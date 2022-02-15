[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String[]]
    $CertificateDomain
)

process {

    $CertificateDomain | Foreach-Object {

        $importArgs = @{
            FilePath = (Get-PACertificate -MainDomain $_).PfxFile
            Password = ('poshacme' | ConvertTo-SecureString -AsPlainText -Force) 
            CertStoreLocation = 'Cert:\LocalMachine\TrustedPeople'
            Exportable = $true
        }

        Import-PfxCertificate @importArgs

    }
}