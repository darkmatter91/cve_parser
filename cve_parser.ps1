# Parse parameters
param (
    [switch]$Cleanup,
    [string]$Filename
)

# Colors
$green = "`e[0;32m"
$gray = "`e[0;37m"
$blue = "`e[0;34m"
$red = "`e[0;31m"
$no_color = "`e[0m"

# Banner
Write-Host "  ______   ______  ___                      " -ForegroundColor Blue
Write-Host " / ___/ | / / __/ / _ \___ ________ ___ ____" -ForegroundColor Blue
Write-Host "/ /__ | |/ / _/  / ___/ _ \`/ __(_-</ -_) __/" -ForegroundColor Blue
Write-Host "\___/ |___/___/ /_/   \_,_/_/ /___/\__/_/   " -ForegroundColor Blue
Write-Host "                                            "
Write-Host "              By E-nzym3" -ForegroundColor Red
Write-Host "          PS By Darkmatter91" -ForegroundColor Red
Write-Host "    (https://github.com/e-nzym3)`n" -ForegroundColor Red

# Function to display usage
function Show-Usage {
    Write-Host "Usage: .\script.ps1 [-Cleanup] -Filename <filename>"
    Write-Host "  -Cleanup  Cleanup chunk files after processing"
    exit 1
}


# Check if the filename is provided as an argument
if (-not $Filename) {
    Show-Usage
}

# Check if the file exists
if (-not (Test-Path $Filename)) {
    Write-Host "File not found!" -ForegroundColor Red
    exit 1
}

# Get the total number of lines in the file
$total_lines = (Get-Content $Filename).Count

# Calculate the number of chunks
$chunk_size = 100
$num_chunks = [math]::Ceiling($total_lines / $chunk_size)

# Split the file into chunks and process each chunk
for ($i = 0; $i -lt $num_chunks; $i++) {
    $start_line = $i * $chunk_size + 1
    $end_line = [math]::Min($start_line + $chunk_size - 1, $total_lines)
    
    # Extract the chunk and save it to a new file
    $chunk_filename = "${Filename}_chunk_$($i + 1)"
    Get-Content $Filename | Select-Object -Skip ($start_line - 1) -First ($end_line - $start_line + 1) | Set-Content $chunk_filename
    
    Write-Host "[*] Created chunk $($i + 1): lines $start_line to $end_line" -ForegroundColor Green
    
    # Pass the chunk file as an argument to the cvemap script
    & cvemap -silent -id $chunk_filename -f kev,poc -fe epss,age,template -o "${chunk_filename}_cvemap.out" > $null
        
    # Check the exit status of cvemap
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] Error processing $chunk_filename with cvemap" -ForegroundColor Red
        exit 1
    }
    
    # Remove chunk file if cleanup is enabled
    if ($Cleanup) {
        Remove-Item $chunk_filename
        Write-Host "[*] Removed chunk file: $chunk_filename" -ForegroundColor Green
    }

    python3 cve_json_parse.py "${chunk_filename}_cvemap.out"
}

Write-Host "[-] File split into $num_chunks chunks and processed with cvemap!`n[-] Check file ending in _parsed.csv for output!" -ForegroundColor Blue