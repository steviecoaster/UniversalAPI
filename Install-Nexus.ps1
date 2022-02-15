[CmdletBinding(DefaultParameterSetName='default')]
Param(
    [Parameter()]
    [String]
    $RepositoryName = 'gallery2choco',

    [Parameter()]
    [switch]
    $DisableAnonymous,

    [Parameter()]
    [String]
    $Role = 'NuGet'
)

process {
    if('NexuShell' -notin (Get-Module -ListAvailable).Name){
        Install-Module NexuShell -Force
        Import-Module NexuShell
    }

    else {
        Import-Module NexuShell
    }

    $packageArgs = @('install','nexus-repository','-y',"--source='https://chocolatey.org/api/v2/'")
    & choco @packageArgs

    $password = Get-Content 'C:\ProgramData\sonatype-work\nexus3\admin.password'
    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $credential = [System.Management.Automation.PSCredential]::new('admin',$SecurePassword)

    Connect-NexusServer -Hostname localhost -Credential $credential

    Get-NexusRepository | Remove-NexusRepository -Force
    New-NexusBlobStore -Name Stream -Type File -Path E:\PackageBlob -Verbose

    $repoParams = @{
        DeploymentPolicy = 'Allow'
        BlobStoreName = 'Stream'
    }

    New-NexusNugetHostedRepository -Name $RepositoryName @repoParams

    Enable-NexusRealm -Realm 'NuGet Api-Key Realm' -Verbose

    if($DisableAnonymous){
        Set-NexusAnonymousAuth -Disabled

        $roleParams = @{
            Id = $Role
            Name = $Role
            Description = 'Read-only access to NuGet repositories'
            Privileges = @('nx-repository-view-nuget-*-browse','nx-repository-view-nuget-*-read')
        }

        New-NexusRole @roleParams
    }
}