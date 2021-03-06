# Find users with a spesific computer listed in Active Directory Logon Workstations | https://github.com/flemmingss/

##############################################################################################

### configuration ###

$users_file = "users.txt" # file with usernames (new line for each username)
$computers_file = "computers.txt" # file with data. Don't edit this file, script wil automaticly create content with the UPDATE-command 

##############################################################################################

### Set Poweshell location to be equal to script location ###

$script_location = $MyInvocation.MyCommand.Path
$script_location = Split-Path $script_location
Set-Location $script_location

### text files verification ###

$users_file_exist = Test-Path $users_file # check if file exist, returns True/False
$computers_file_exist = Test-Path $computers_file # check if file exist, returns True/False

Write-Host "Checking if files exist"

### $users_file verification ###

If ($users_file_exist -eq "True")
	{
	Write-Host "$users_file found"
	$users_file_count = Get-Content $users_file
	
	If ($users_file_count.count -eq "0" -or $users_file_count.count -eq "1")
		{
		Write-Host "$users_file is empty or contains too few usernames"
		Write-Host "At least two usernames is needed to run script. Press any key to exit ..."
		$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") # pause command, $X is to avoid output
		exit
		}
	
	}
Else
	{
	Write-Host "$users_file not found"
	Write-Host "File is needed to run script. Press any key to exit ..."
 	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") # pause command, $X is to avoid output
	exit
	}

### $computers_file verification ###

If ($computers_file_exist -eq "True")
	{
	Write-Host "$computers_file found"
	}

Else
	{
	Write-Host "$computers_file not found"
	Write-Host "Creating file $computers_file"
	New-Item $computers_file -type file | Out-Null # creating new textfile
	}

$computers_file_empty = Get-Content $computers_file

If ($computers_file_empty -eq $null)
	{
	Write-Host "$computers_file is empty"
	Write-Host "You need to run UPDATE before searching for computer!"
	}

### script ###

Do
	{
	$input = read-host "Computer name (or update/exit)" #user input

	if ($input -eq "update")	
		{
		Add-PSSnapin Quest.ActiveRoles.ADManagement -erroraction 'silentlycontinue' #Adding Quest ActiveRoles Management snapin, hide error message (if Quest.ActiveRoles.ADManagement is already added)
		
		Write-Host "Deleting content from $computers_file"
		Clear-Content "$computers_file"
		Write-Host "Import list of users from $users_file"
		$lines = Get-Content $users_file | Measure-Object -line
		$lines = [int]$lines.Lines
		[int]$line_counter = "0"
		Write-Host "$lines user accounts found"
        Write-Host "Initiates retrieval of restriction lists from Active Directory"
        
			Do
			{			
			$computers_file_empty = Get-Content $computers_file
			$user_account = (Get-Content $users_file)[$line_counter] 	
			$logonto_check_data = (Get-QADUser $user_account -IncludedProperties userWorkstations -SizeLimit 0 | Select-Object userWorkstations) | Out-String
			$logonto_check_cleaned = $logonto_check_data.replace(' ' , '')
			$logonto_check_quantity = ($logonto_check_cleaned.ToCharArray() | Where-Object {$_} | Measure-Object).Count 
	
				if ($logonto_check_quantity -ne 44)
				{
				Write-Host "Initiates retrieval of approved workstations from $user_account" -foregroundcolor Yellow 
				$computers = (Get-QADUser $user_account -IncludedProperties userWorkstations -SizeLimit 0 | Select-Object -ExpandProperty userWorkstations | Format-Table -Property userWorkstations) | Out-String
				$computers = $computers -replace "\s", ""
				$computers = "," + $computers + ","
				
				If ($computers -eq ",,")
					{
					Write-Host "> Username $user_account not found in Active Directory" -foregroundcolor Red
					}
				
				$computers >> "$computers_file"
				}
	
				Else 
					{
					Write-Host "Initiates retrieval of approved workstations from $user_account" -foregroundcolor Yellow
					Write-Host "> There is no workstation logon restrictions assigned to $user_account" -foregroundcolor Magenta 
					"" >> "$computers_file" # writing a empty line because line numbers in the two text files must match to get corrent output
					}
	
	   		$line_counter = $line_counter+1
			} until ($line_counter -eq $lines)

		}
		
		ElseIf ($input -ne "update" -and $input -ne "exit" -and $input -ne "$null" -and $computers_file_empty.count -ne "0")
			{
			$lines = Get-Content $users_file | Measure-Object -lin
			$lines = [int]$lines.Lines
			$match_computer = "no"
			[int]$line_counter = "0"

			Write-Host "The Following user(s) can log on to $input"

			Do {
				$import_users = (Get-Content $users_file)[$line_counter]
				$import_computers = (Get-Content $computers_file)[$line_counter]
				$import_computers = $import_computers + ","
				$result = $import_computers -match ",$input,"

				If ($result -eq "True")
					{
					Write-Host "$import_users" -foregroundcolor Cyan
					$match_computer = "yes"
					}	

	    		$line_counter = $line_counter+1
				} until ($line_counter -eq $lines)
				
		If ($match_computer -eq "no")
			{
			Write-Host "No matches found in any workstation logon restrictions lists"
			}
			
		}
		
	} until ($input -eq "exit")
	
# End