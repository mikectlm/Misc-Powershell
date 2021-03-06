[string]$stamp = (get-date -Format yyyyMMddhhmm)
$global:return_code = 0

trap 
{
	echo "Unexpected Error"
	echo $Error[0]
	$global:return_code = 100
}

if ($args.count -eq 0) {
  write-host "!!!> Wrong number of arguments"
  write-host ""
  write-host "USAGE: Rename_Files.ps1 '<FilePath;NewFilename[;Stamp][;Extension]>' '[FilePath;NewFilename[;Stamp]]'"
  exit 2
}

$args | foreach-object {
	$file = $_.split(";")
	
	if (test-path $($file[0])) {
	
		if ($file.count -lt 2) {
			$global:return_code = 2
		}
		else {
			$filename = $($file[1])
			if ($file.count -eq 4) {
				$filename += (get-date -Format $($file[2])) + $($file[3])                
			}
            elseif ($file.count -eq 3) {
                if ($filename.contains(".")) {
                	$extension = "." + $filename.split('.')[-1]
					$filename = $filename.replace($extension, (get-date -Format $($file[2]))) + $extension
                }
                else {
					$filename += get-date -Format $($file[2])
				}
            }
		}
		
		rename-item -path $($file[0]) -newname $filename
		if (!$?) {
			$global:return_code = 99
			write-host "!!!> Error renaming $($file[0])"
		}
	}
	else {
		#File not found
		if ($global:return_code -eq 0) {
			$global:return_code = 101
		}
		write-host "!!!> File $($file[0]) not found"
	}
}

#rename-item -path \\Ctor-pasir\Interface_Repository\_PendingProcess\PBC\PEBT\EnrolFile.txt -newname PEBPAPBC.txt

#rename-item -path \\Ctor-pasir\Interface_Repository\_PendingProcess\PBC\PEBT\CancelFile.txt -newname PEBPCPBC.txt
#if (!$?) { $global:return_code = 99 }
#
#rename-item -path \\Ctor-pasir\Interface_Repository\_PendingProcess\PBC\PEBT\TrailerFile.txt -newname PEBPTPBC.txt
#if (!$?) { $global:return_code = 99 }

exit $global:return_code