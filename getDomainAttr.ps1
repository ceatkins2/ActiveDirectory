
<#
    This sciript gets the FSMO roles of the domain controllers in an AD environment, along with the installed Roles, but not features. It
    then formats it as HTML and prompts you to save a file. The result should be readable and pretty, if you like different shades of grey :)
#>



# Load required modules
Import-Module ActiveDirectory
Import-Module ServerManager

# role call (heh)
#tried adding the current "domainRoles" object to the "forestRoles" object with a "+=" operator, but that didnt work. It seems that since one is "get-adforest" and the other is "get-addomain" they cannot be concatenated
$forestRoles = Get-ADForest | Select-Object -Property SchemaMaster, DomainNamingMaster
$domainRoles = Get-ADDomain | Select-Object -Property PDCEmulator, RIDMaster, InfrastructureMaster

# iterate thru DCs, get features
$domainControllers = Get-ADDomainController -Filter *
$dcRoles = $domainControllers | ForEach-Object {
    $dc = $_
    $roles = Get-WindowsFeature -ComputerName $dc.HostName | Where-Object { $_.InstallState -eq 'Installed' -and $_.FeatureType -eq 'Role' }
    [PSCustomObject]@{
        Name  = $dc.HostName
        Roles = ($roles.DisplayName -join ', ')
    }
}

# generate html
# this template was generated via an HTML WYSIWYG generator, dont touch this, i dont know how to fix it if it breaks
$htmlReport = @"
<html>
<head>
    <title>Domain Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #dddddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f5f5f5; }
        h2 { color: #444; }
    </style>
</head>
<body>
    <h2>FSMO Roles</h2>
    <table>
        <tr>
            <th>Role</th>
            <th>Server</th>
        </tr>
        <tr>
            <td>Schema Master</td>
            <td>$($forestRoles.SchemaMaster)</td>
        </tr>
        <tr>
            <td>Domain Naming Master</td>
            <td>$($forestRoles.DomainNamingMaster)</td>
        </tr>
        <tr>
            <td>PDC Emulator</td>
            <td>$($domainRoles.PDCEmulator)</td>
        </tr>
        <tr>
            <td>RID Master</td>
            <td>$($domainRoles.RIDMaster)</td>
        </tr>
        <tr>
            <td>Infrastructure Master</td>
            <td>$($domainRoles.InfrastructureMaster)</td>
        </tr>
    </table>

    <h2>Domain Controllers and Their Roles</h2>
    <table>
        <tr>
            <th>Name</th>
            <th>Roles</th>
        </tr>
$(
    $dcRoles | ForEach-Object {
        @"
        <tr>
            <td>$($_.Name)</td>
            <td>$($_.Roles)</td>
        </tr>
"@
    }
)
    </table>
</body>
</html>
"@

# ask for filename
$fileName = Read-Host -Prompt "Enter the filename for the report (without .html extension)"

# add .html to filename
$fullPath = "./$fileName.html"
$htmlReport | Out-File -Encoding utf8 $fullPath

Write-Host "Report saved to $fullPath"
