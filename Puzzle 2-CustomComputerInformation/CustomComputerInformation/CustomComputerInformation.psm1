Function Get-ComputerDiskInformation {
    <#
    .SYNOPSIS
    Gets Logical Disk infromation from a Windows computer.
    
    .DESCRIPTION
    Get-ComputerDiskInformation utilizes the Common Information Model (CIM) to query the win32_logicaldisk instance for
    information on the logical disks mounted in Windows. The cmdlet can be run locally or against one or more remote 
    endpoints. 
    
    .EXAMPLE
    Get-ComputerDiskInformation -ComputerName 'SERVER1'

    .EXAMPLE
    'Server1' | Get-ComputerDiskInformation

    .EXAMPLE
    (Get-Content .\computers.txt) | Get-ComputerDiskInformation
    
    .NOTES
    Compatable with PowerShell 6.0
    Part of my solution to the Iron Scripter 2018 prequel puzzle 2 released January 21, 2018
    #>

    [CmdletBinding()]
    Param (
        [Parameter( ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true)]
        [String[]]$ComputerName = 'localhost'
    )

    Begin {}

    Process {

        Foreach ($computer in $ComputerName) {

            Try {

                $WMI = @{

                    'ComputerName' = $computer;
                    'Class' = 'Win32_LogicalDisk';
                    'ErrorAction' = 'Stop'

                }

                $Disks = Get-CimInstance @WMI

                Foreach ($disk in $disks ) {

                    $DiskProps = @{

                        'Drive' = $Disk.DeviceID;
                        'DriveType' = $disk.Description;
                        'Size' = $disk.size;
                        'FreeSpace' = $Disk.FreeSpace;
                        'Compressed' = $disk.Compressed;
                        'PercentUsed' = ((($disk.Size - $disk.FreeSpace) / $disk.size) * 100)

                    }

                    Write-Debug "Test DiskProps"

                    $DiskObject = New-Object -TypeName PSObject -Property $DiskProps
                    $DiskObject.PSObject.TypeNames.Insert(0,'Custom.DiskInformation')
                    Write-Output $DiskObject
                }

            } Catch {

                Write-Output "$($Error[0])"
                
            }
        }
    }

    End {}

}
########################################################################################################################
Function Get-ComputerInformation {
    <#
    .SYNOPSIS
    Retrieves general information about a computer
    
    .DESCRIPTION
    Get-ComputerInformation utilizes the Common Information Model (CIM) to query the win32_operatingsystem instance to
    the OS Name, OS Version, OS Manufacturer, Windows directory path, the language locale, Available Physical Memory, 
    Available Virtual Memory, Total Virtual Memory, and Logical Disk information from the Win32_logicaldisk instance via
    a helper function Get-ComputerDiskInformation.
    
    .EXAMPLE
    Get-ComputerInformation -ComputerName 'SERVER1'

    .EXAMPLE
    'Server1' | Get-ComputerInformation

    .EXAMPLE
    (Get-Content .\computers.txt) | Get-ComputerInformation
    
    .NOTES
    Compatable with PowerShell 6.0
    Requires helper function Get-ComputerDiskInformation
    Part of my solution to the Iron Scripter 2018 prequel puzzle 2 released January 21, 2018
    #>

    [CmdletBinding()]
    Param(
        [Parameter( ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true)]
        [String[]]$ComputerName = 'localhost'
    )

    Begin {}

    Process {

        Foreach ($Computer in $ComputerName) {

            Try {

                $WMI = @{

                    'ComputerName' = $Computer;
                    'Class' = 'Win32_OperatingSystem';
                    'ErrorAction' = 'Stop'

                }

                $OS = Get-CimInstance @WMI
                
                #object returned by Get-ComputerDiskInformation has properties
                #that correspond to properties returned by Get-WmiObject win32_logicaldisk
                $disks = Get-ComputerDiskInformation -ComputerName $Computer

                $Properties = @{

                    'ComputerName' = $computer;
                    'OSName' = $OS.Caption;
                    #'OSVersion' = "$($OS.ServicePackMajorVersion)" + "." + "$($OS.ServicePackMinorVersion)";
                    'OSVersion' = $OS.Version;
                    'OSManufacturer' = $OS.Manufacturer;
                    'WindowsDir' = $OS.WindowsDirectory;
                    'Locale' = $OS.MUILanguages;
                    'AvailPhysicalMemory' = $OS.FreePhysicalMemory;
                    'TotalVirtualMemory' = $OS.TotalVirtualMemorySize;
                    'AvailVirtualMemory' = $OS.FreeVirtualMemory;
                    'LogicalDisks' = $Disks

                }

                Write-debug "Test Properties"

                $Object = New-Object -TypeName PSObject -Property $Properties
                $Object.PSObject.TypeNames.Insert(0,'Custom.ComputerInformation')
                Write-Debug 'Test output'
                Write-Output $Object

            } Catch {

                Write-Output "$($Error[0])"

            }
        }
    }

    End {}
}