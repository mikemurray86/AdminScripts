param(
    [string]$user,
    [string]$pass
)

(new-object directoryservices.directoryentry "",$user,$pass).psbase.name -ne $null