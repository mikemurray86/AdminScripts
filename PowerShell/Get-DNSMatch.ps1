<#
.SYNOPSIS
    Reads all .dns files for MS DNS servers and searches for a string
.DESCRIPTION
    This will check all the files that end in .dns that are located in $env:systemroot\system32\dns 
    for the specified string and print it to the screen if located.
.EXAMPLE
    PS C:\> Get-DNSMatch.ps1 -SearchPattern "opi.mt.gov"
    This will return every DNS record that contains the string "opi.mt.gov"
.PARAMETER SearchPattern
    This is any regular expression you would like to search for in the DNS records
.NOTES
    This does not support AD integrated zones. 
#>

Param (
    [String]$searchPattern
)

$resultsFormat = @{Expression={$_.Filename};Label="File"},
                 @{Expression={$_.LineNumber};Label="Line"},
                 @{Expression={$_.Line};Label="Text"}

$searchResults = Get-ChildItem -Path C:\Windows\System32\DNS -Filter "*.dns" | 
                    Select-String -Pattern $searchPattern | 
                    Format-Table $resultsFormat -AutoSize

If ($searchResults) {
    $searchResults
} 
Else {
    Write-Host "`nNo search results`n"
}