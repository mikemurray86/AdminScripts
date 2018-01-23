<#
.SYNOPSIS
    A script to modify shortcut paths
.PARAMETER OldPath
    the path to look for
.PARAMETER NewPath
    the path to change it to
.PARAMETER SearchPath
    Where to start searching from
.PARAMETER Recurse
    Flag to only recursively check sub-folders
.EXAMPLE
    Set-ShortcutPath -OldPath S:\test -NewPath S:\new -SearchPath C:\

    This will find all shortcuts that start with 'S:\test' and change them to 'S:\new'
.NOTES
    Notes
.LINK
    Helpful Links
#>

#Requires -version 3

Function Get-Shortcut {
    <#
    .SYNOPSIS
        Collects shortcuts at the specified Paths
    .PARAMETER Path
        the source path to start checking from
    .PARAMETER Recurse
        Set's to check recursively or not. 
    .EXAMPLE
        Get-Shortcut -Path C:\temp -Recurse

        checks C:\temp and all subfolders for any .lnk files
    .LINK
        https://stackoverflow.com/questions/484560/editing-shortcut-lnk-properties-with-powershell
    #>

    [cmdletbinding()]

    param(
        [Parameter(Mandatory=$True)]
        [string]$Path,
        [switch]$Recurse
    )

    begin{
        $shell =  New-Object -ComObject WScript.Shell
    }
    process{
        if($Recurse){
            $links = Get-ChildItem -Path $Path -Recurse -Filter *.lnk
        }
        else {
            $links = Get-ChildItem -Path $Path -Filter *.lnk
        }
        foreach ($item in $links){
            $shell.createShortcut($item.FullName)
        }

    }
}

Function Set-Shortcut {
    <#
    .SYNOPSIS
        Takes a shortcut and modifies it's settings in some way
    .PARAMETER Link
        The link to modify
    .PARAMETER Arguments
        What to populate in the arguments field of a shortcut
    .PARAMETER Description
        Information in the Description field
    .PARAMETER Hotkey
        The information for the hotkey field
    .PARAMETER IconLocation
        What Icon to use
    .PARAMETER RelativePath
        Set the RelativePath value
    .PARAMETER TargetPath
        Set where the link points to.
    .PARAMETER WindowStyle
        An integer value for how to display the window
    .PARAMETER WorkingDirectory
        Set the working directory for the link
    .EXAMPLE
        Set-Shortcut -Link C:\temp\test.lnk -TargetPath 'C:\temp\test\'

        points the shortcut to the C:\temp\test folder
    .NOTES
        Notes
    .LINK
        Helpful Links
    #>

    [cmdletbinding()]

    param(
        [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        [validatePattern('.lnk$')]
        [alias('FullName')]
        [string]$Link,
        [string]$Arguments,
        [string]$Description,
        [string]$Hotkey,
        [string]$IconLocation,
        [string]$RelativePath,
        [string]$TargetPath,
        [string]$WindowStyle,
        [string]$WorkingDirectory
    )

    begin{
        $shell =  New-Object -ComObject WScript.Shell
    }
    process{

        $item = $shell.createShortcut($Link)

        switch($PSBoundParameters.Keys){
            'Arguments'        { $item.Arguments = $Arguments               }
            'Description'      { $item.Description = $Description           }
            'Hotkey'           { $item.Hotkey = $Hotkey                     }
            'IconLocation'     { $item.IconLocation = $IconLocation         }
            'RelativePath'     { $item.RelativePath = $RelativePath         }
            'TargetPath'       { $item.TargetPath = $TargetPath             }    
            'WindowStyle'      { $item.WindowStyle = $WindowStyle           }
            'WorkingDirectory' { $item.WorkingDirectory = $WorkingDirectory }
        }

        $item.save()
    }
}