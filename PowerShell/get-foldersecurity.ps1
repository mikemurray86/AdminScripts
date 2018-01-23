[cmdletbinding()]

param(
    [string]$file
)

$perms = Import-Csv $file

foreach($perm in $perms){
    try{
        $account = Get-ADUser $perm.Account.split('\')[1] -ErrorAction Stop
    }
    catch{
        $account = @{'GivenName' = ''
                     'Surname'   = ''
                    }
    }
    Add-Member -InputObject $perm -NotePropertyName 'AccountFirstName' -NotePropertyValue $account.GivenName
    Add-Member -InputObject $perm -NotePropertyName 'AccountLastName' -NotePropertyValue $account.Surname

}

$perms