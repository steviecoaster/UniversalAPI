[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String]
    $First,

    [Parameter(Mandatory)]
    [String]
    $Last,

    [Parameter(Mandatory)]
    [String]
    $Username,

    [Parameter(Mandatory)]
    [String]
    $Email,

    [Parameter(Mandatory)]
    [String]
    $Password
)

process {
    Import-Module NexuShell

    $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force

    #$SecureNexusPassword = $NexusPassword | ConvertTo-SecureString -AsPlainText -Force
    #$Credential = [System.Management.Automation.PSCredential]::new($NexusAdmin,$SecureNexusPassword)
    Connect-NexusServer -Hostname nexus.steviecoaster.dev -UseSSL -Credential $NexusAdmin

    if($Username -in (Get-NexusUser | Select -Expand Username)){
        throw "Username already taken. Please try another name"
    }

    else {
        $params = @{
            Username = $Username
            Password = $SecurePassword
            FirstName = $First
            LastName = $Last
            EmailAddress = $Email
            Status = 'Active'
            Roles = 'choco'
        }

        New-NexusUser @params
    }
    
}
