    <#
    .SYNOPSIS
        This collects information directly from the windows host
    .PARAMETER Computername
        The computer to collect info from
    .EXAMPLE
        example
    .NOTES
        Notes
    .LINK
        https://msdn.microsoft.com/en-us/powershell/scripting/core-powershell/running-remote-commands
    #>

    [cmdletbinding()]

       param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        [switch]$Firewall,
        [switch]$roles,
        [System.Management.Automation.CredentialAttribute()]$credential
    )

function Test-PSRemoting{
    <#
    .SYNOPSIS
        this tests if psremoting is enabled and prompts to add to trusted hosts if it is not.
    .PARAMETER ComputerName
        the computer to test the connection on
    .EXAMPLE
        Test-PSRemoting -ComputerName 'SomeMachine'
        Attemps to connect to SomeMachine. Returns true if successful and prompts to add to trusted hosts and retest if not. 
    #>

    [CmdletBinding()]

    param(
        [string[]]$ComputerName
    )

    foreach($computer in $ComputerName){
        try{ 
            Test-WSMan $computer -ErrorAction stop | Out-Null
        }
        catch{
            $message = "Powershell Remoting on $computer failed..."
            $question = "Would you like to add $Computer to your trusted hosts and try again?"
            $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
            $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
            $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))
            $answer = $Host.UI.PromptForChoice($message, $question, $choices, 1)

            if($answer -eq 0){
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value $Computer -Concatenate
                Test-PSRemoting @PSBoundParameters
            }
        }
    }
}

Test-PSRemoting -ComputerName $ComputerName

switch($PSBoundParameters.Keys){
    'Firewall' {
        Write-Verbose 'Checking Firewall rules'
        if(Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock { Get-Command Get-NetFirewallRule -ErrorAction SilentlyContinue }){
            Write-Verbose 'detected Get-NetFirewallRule on system'
            $Rules = Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock {
                Get-NetFirewallRule -Enabled true | Where-Object {$_.name -notlike '{*' } | Select-Object name
            }
        }
        else{ 
            Write-Verbose 'using netsh for lookup'
            $RawRules = netsh advfirewall firewall show rule name=all
            $RuleCol = $RawRules | Out-String -Stream
            $Rules = @()
            $rule = [PSCustomObject]@{Name='';Enabled=''}
            foreach($line in $RuleCol){
                switch -Regex ($line){
                    'Rule Name:' {
                        Write-Verbose 'Found new rule name'
                        if(($rule.Enabled -ne 'No') -and ($rule.Enabled -ne '') -and ($rule.Name -notlike '{*')){ 
                            # If you are in a rule name then you should have a complete rule waiting from the last time the foreach loop executed.
                            $Rules += $rule # Save all enabled rules
                        }
                        $rule.Name = (Select-String -Pattern '(?<=Rule Name:\s).+' -InputObject $line).Matches.Value.Trim(' ')
                    }
                    'Enabled:' {
                        Write-Verbose 'Collecting rule status'
                        $rule.Enabled = (Select-String -Pattern '(?<=Enabled:\s).+' -InputObject $line).Matches.Value.Trim(' ')
                    }
                }
            }
        }
        $Rules
    }
    'roles' {
        Get-WindowsFeature -ComputerName $ComputerName -Credential $credential | Where-Object 'installed' | Select-Object 'name'
    }
}
