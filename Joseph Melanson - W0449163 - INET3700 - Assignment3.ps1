<#
Title: Assignment 3
Student: Joseph Melanson - W0449163
Course: INET3700
Faculty: George Campanis
Date: November 28, 2021
Description: This script allows a user to perform a variety of functions: add a local user, change a password, add a user to an existing local group, and remove a local user. All changes are written to the Windows event log.
#>

# the following if statement checks to see if Powershell is running as admin, and if not, reruns it as admin and closes the original window
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) { # check to see if Powershell is running as admin
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments # pull command to run original script and arguments
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine # run Powershell again as admin
    Exit # close original non-admin window
}

New-EventLog -Source PowershellAssignment3 -LogName Application # create a source in the application log for the event log to reference when writing events

function AddToLocalGroup($Username, $LocalGroup) { # adds a supplied user to a supplied local group
    try { # try to add the supplied user to the supplied group
        Add-LocalGroupMember -Group $LocalGroup -Member $Username -ErrorAction Stop # add user to group
        Write-EventLog -ComputerName $env:ComputerName -EntryType SuccessAudit -LogName "Application" -Source "PowershellAssignment3" -EventID 4201 -Message "Windows User Added to Group" # write success to the event log
        "User {0} added to the group {1}." -f $Username, $LocalGroup # feedback to user
    } catch { # catch error
        $message = $_ # store the latest/current error in $message
        Write-Warning "Error: $message" # display error to the user
        Write-EventLog -ComputerName $env:ComputerName -EntryType FailureAudit -LogName "Application" -Source "PowershellAssignment3" -EventID 4202 -Message $message # write error to the event log
    }
}

function AddWindowsUser($Username, [SecureString] $Password, $LocalGroup) { # adds a new user account with supplied username, password and local group
    try { # try to add supplied user, then call AddToLocalGroup to add them to supplied group
        New-LocalUser -Name $Username -Password $Password -ErrorAction Stop | Out-Null # add supplied user with supplied password, use "| Out-Null" to discard default output as it was causing issues with the menu
        Write-EventLog -ComputerName $env:ComputerName -EntryType SuccessAudit -LogName "Application" -Source "PowershellAssignment3" -EventID 4203 -Message "Windows User Created" # write success to the event log
        "User {0} created." -f $Username # feedback to user
        AddToLocalGroup $Username $LocalGroup # add supplied user to supplied local group
    } catch { # catch error
        $message = $_ # store the latest/current error in $message
        Write-Warning "Error: $message" # display error to the user
        Write-EventLog -ComputerName $env:ComputerName -EntryType FailureAudit -LogName "Application" -Source "PowershellAssignment3" -EventID 4204 -Message $message # write error to the event log
    }
}

function ChangeUserPassword($Username, [SecureString] $Password) {
    try { # try to change the password
        Set-LocalUser -Name $Username -Password $Password -ErrorAction Stop # sets supplied password on supplied username
        Write-EventLog -ComputerName $env:ComputerName -EntryType SuccessAudit -LogName "Application" -Source "PowershellAssignment3" -EventID 4205 -Message "User Password Changed" # write success to the event log
        "Password for user {0} changed." -f $Username # confirmation message
    } catch { # catch error
        $message = $_ # store the latest/current error in $message
        Write-Warning "Error: $message" # display a non-technical error to the user
        Write-EventLog -ComputerName $env:ComputerName -EntryType FailureAudit -LogName "Application" -Source "PowershellAssignment3" -EventID 4206 -Message $message # write error to the event log
    }
}

function RemoveFromLocalGroup($Username, $LocalGroup) {
    $title = Remove-LocalGroupMember -Group $LocalGroup -Member $Username -WhatIf # store whatif notification for removing the supplied user from the supplied group
    $question = "Are you sure you want to proceed?" # store confirmation prompt
    $choices = "&Yes", "&No" # store confirmation choices
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 0) # prompt for user input/decision
    if ($decision -eq 0) { # if yes attempt task
        try { # try to remove the user from the group
            Remove-LocalGroupMember -Group $LocalGroup -Member $Username -ErrorAction Stop # remove the supplied user from the supplied group
            Write-EventLog -ComputerName $env:ComputerName -EntryType SuccessAudit -LogName "Application" -Source "PowershellAssignment3" -EventID 4207 -Message "User Removed From Group" # write success to the event log
            "User {0} removed from group {1}." -f $Username, $LocalGroup # confirmation message
        } catch { # catch error
            $message = $_ # store the latest/current error in $message
            Write-Warning "Error: $message" # display a non-technical error to the user
            Write-EventLog -ComputerName $env:ComputerName -EntryType FailureAudit -LogName "Application" -Source "PowershellAssignment3" -EventID 4208 -Message $message # write error to the event log
        }
    } else { # if no cancel task
        "Operation aborted." # feedback to user
    }
}

function RemoveWindowsUser($Username) { # removes user with supplied username
    $title = Remove-LocalUser -Name $Username -WhatIf # store whatif notification for removing the supplied user
    $question = "Are you sure you want to proceed?" # store confirmation prompt
    $choices = "&Yes", "&No" # store confirmation choices
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 0) # prompt for user input/decision
    if ($decision -eq 0) { # if yes attempt task
        try { # try to remove the user
            Remove-LocalUser -Name $Username -ErrorAction Stop # remove the supplied user
            Write-EventLog -ComputerName $env:ComputerName -EntryType SuccessAudit -LogName "Application" -Source "PowershellAssignment3" -EventID 4209 -Message "Windows User Removed" # write success to the event log
            "User {0} removed." -f $Username # confirmation message
        } catch { # catch error
            $message = $_ # store the latest/current error in $message
            Write-Warning "Error: $message" # display a non-technical error to the user
            Write-EventLog -ComputerName $env:ComputerName -EntryType FailureAudit -LogName "Application" -Source "PowershellAssignment3" -EventID 4210 -Message $message # write error to the event log
        }
    } else { # if no cancel task
        "Operation aborted." # feedback to user
    }
}

Clear-Host # clear the screen
"-----Joseph Melanson - Assignment 3 - Powershell Script-----" # title
Do { # start main menu/script loop
    "`n" # spacing
    "Please type of number for the task you would like to perform:"
    "`n" # spacing
    "1. Add a local user" # AddWindowsUser
    "2. Change a password" # ChangeUserPassword
    "3. Add a user to an existing local group" # AddToLocalGroup
    "4. Remove a local user" # RemoveWindowUser
    "5. Remove a user from a local group" # RemoveFromLocalGroup
    "6. Exit" # quit script
    "`n" # spacing
    $choice = Read-Host "Please enter a number between 1 and 6" # prompt for user input
    Switch ($choice) { # input feedback and action section
        0 { # not used
            "`n" # spacing
            "Bad input. Please enter a number between 1 and 6" # non-system error message
        }
        1 { # prompt for input and call AddWindowsUser function
            "`n" # spacing
            $Username = Read-Host "Enter the username for the new user" # get username
            $Password = Read-Host "Enter the password for the new user" -AsSecureString # get password
            $LocalGroup = Read-Host "Enter the local group for the new user" # get local group
            "`n" # spacing
            AddWindowsUser $Username $Password $LocalGroup # call function and pass parameters
        }
        2 { # prompt for input and call ChangeUserPassword function
            "`n" # spacing
            $Username = Read-Host "Enter the username for the user whose password will be changed" # get username
            $Password = Read-Host "Enter the NEW password for the user" -AsSecureString # get password
            "`n" # spacing
            ChangeUserPassword $Username $Password # call function and pass parameters
        }
        3 { # prompt for input and call AddToLocalGroup function
            "`n" # spacing
            $Username = Read-Host "Enter username to add to the local group" # get username
            $LocalGroup = Read-Host "Enter the local group to add the user to" # get local group
            "`n" # spacing
            AddToLocalGroup $Username $LocalGroup # call function and pass parameters
        }
        4 { # prompt for input and call RemoveWindowUser function
            "`n" # spacing
            $Username = Read-Host "Enter username" # get username
            "`n" # spacing
            RemoveWindowsUser $Username # call function and pass parameters
        }
        5 { # prompt for input and call RemoveFromLocalGroup function
            "`n" # spacing
            $Username = Read-Host "Enter the user to remove from a local group" # get username
            $LocalGroup = Read-Host "Enter the local group to remove the user from" # get local group
            "`n" # spacing
            RemoveFromLocalGroup $Username $LocalGroup # call function and pass parameters
        }
        6 {
            break # perform a clean end of the program when user enters 6
        }
        default { # not used
            "`n" # spacing
            "Bad input. Please enter a number between 1 and 6" # non-system error message
        }
    }
} While ($choice -ne "6") # exit the script when the user enters 6