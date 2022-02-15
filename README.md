# Intro

You've found the supporting repository to a [Twitch Stream](https://twitch.tv/steviecoaster) I did on 15t February 2022. On that stream I walked you through installing [PowerShell Univeral](https://ironmansoftware.com/powershell-universal/), and [Sonatype Nexus](https://sonatype.com), and configuring a system to convert PowerShell Gallery modules into Chocolatey packages you can host internally on your network.

This is great when:

1. The PSGallery goes offline
2. A build pipeline requires modules it can't access
3. A secure environment has no access to the PSGallery

This talk used the free/open source version of each of the tools described above, making this really accessible to you!

## Getting things setup

### 1. Installing Chocolatey

[Chocolatey](https://chocolatey.org) can be installed _really_ quickly. Just execute the following in an _elevated_ PowerShell session:

```powershell
Invoke-Expression ([System.Net.WebClient]::new().DownloadString('https://chocolatey.org/install.ps1'))
```

(Or, if you prefer a more "PowerShell-y" syntax: `Invoke-Expression (New-Object (System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`

### Installing Sonatype Nexus

>:note: **I've seen instances of issues with installing this package on servers, so please do the following _first_**
>
>Open up Internet Explorer on the system (Actual Internet Explorer _not_ Edge!), and go through the first-run wizard if this is a fresh box. I know, I know _What year is it?!?!_

In that elevated PowerShell session run this:

```powershell
Set-Location $PathToClonedRepo
.\Install-Nexus.ps1
```

There's some extra "goodies" in that script to further harden Nexus, but the script will get you configured the same way that I had things in Nexus for the stream. Review the script if you would like to do more during the install process.

### Install PowerShell Universal

Same deal, let's hit the "easy button", and use Chocolatey:

In that elevated session, run `choco install powershelluniversal -y -s https://community.chocolatey.org/api/v2/`

### Secure things with SSL

Notably, this is optional, however, we're technologists. So, let's do this the "right way"

#### Install Posh-ACME and provision certificate(s)

Posh-ACME is a _great_ PowerShell module that makes getting and maintaining Let's Encrypt certificates _super simple_. Now, to preface, I've written this code with [Cloudflare](https://cloudflare.com) in mind as my DNS provider, as that's what I use since their free plan is _fantastic_, and does everything I need in a DNS provider. You're mileage may vary here, and some adjustments made. If you use a different DNS method, you can head over to the [Posh-ACME docs](https://poshac.me) to find the guide for your scenario and modify the script to suit.

In the elevated PowerShell session you can execute the following:

>:note: **Be patient, this takes a moment per certificate to complete**
>

```powershell
Set-Location $PathToClonedRepo
$env:Cloudflare = 'YourCloudFlareApiKey' #the script will pick up this env variable, and use it
.\New-StreamCertificate.ps1 -Domain 'universal.yourdns.name','nexus.yourdns.name' -ContactEmail 'your@email.address'
```

This script will:

1. Install Posh-Acme if not already installed
2. Configure an account for your ContactEmail against the `LE_PROD` servers
3. Submit a certificate request and download the new certificate

Please review the script in full for details on what all is happening.

#### Import Let's Encrypt certificates into Certificate Stores

Now, arguably, these certificates are certificates backed by a Trusted Root, but the different softwares need them to be put in the Windows Certificate store so they can use them.
The following PowerShell will plop them into `Cert:\LocalMachine\TrustedPeople`, perfect for our purposes here:

Again, elevated PowerShell session (seriously, are you noticing a theme here?)

```powershell
Set-Location $PathToClonedRepo
.\Import-LECertificate.ps1 -CertificateDomain 'universal.yourdns.name','nexus.yourdns.name'
```

#### Configuring Nexus SSL Certificate

This part is a _little finnicky_, because Java tooling is known to humans to suck a portion of their soul away upon first use.

First thing we need to do is get the thumbprint of the certificate we want to use. `Get-ChildItem Cert:\LocalMachine\TrustedPeople` does the trick nicely, and you can just copy the thumbprint from there. Or get more creative if you know what you're doing ;).

This will get Nexus setup:

```powershell
Set-Location $PathToClonedRepo
.\New-NexusCert.ps1 -Thumbprint 'PasteYourThumbprintHere'
```

#### Configuring PowerShell Universal SSL

Configuring PowerShell Universal for SSL takes a bit of playing with the appsettings.json file for the kestrel process. Thankfully PowerShell does JSON well, and you can use the following to make it super simple:

```powershell
Set-Location $PathToClonedRepo
.\New-PSUCertificate.ps1 -Domain 'your.domain.name'
```
