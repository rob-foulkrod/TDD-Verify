# Update-VerificationStats.ps1
# Script to automatically update the summary statistics in the site verification checklist
# Author: GitHub Copilot
# Date: October 16, 2025

param(
    [string]$ChecklistPath = ".\site-verification-checklist.txt",
    [string]$SummaryPath = ".\verification-summary.txt"
)

function Update-VerificationStats {
    param(
        [string]$ChecklistFilePath,
        [string]$SummaryFilePath
    )
    
    # Check if checklist file exists
    if (-not (Test-Path $ChecklistFilePath)) {
        Write-Error "Checklist file not found: $ChecklistFilePath"
        return
    }
    
    Write-Host "Reading checklist file: $ChecklistFilePath" -ForegroundColor Green
    
    # Read the checklist content
    $content = Get-Content $ChecklistFilePath -Raw
    
    # Initialize counters
    $totalSites = 0
    $testedPass = 0
    $testedFail = 0
    $untested = 0
    $tagsYes = 0
    $tagsNo = 0
    $tagsUnknown = 0
    $patchCreated = 0
    $patchAccepted = 0
    $patchPending = 0
    
    # Arrays to track site details
    $passedSites = @()
    $failedSites = @()
    $sitesNeedingTags = @()
    $sitesWithPatches = @()
    $sitesWithAcceptedPatches = @()
    $sitesWithPendingPatches = @()
    
    # Split content into lines for processing
    $lines = $content -split "`r?`n"
    
    # Process each line to count statistics
    $inSiteSection = $false
    $currentSite = $null
    $currentUrl = $null
    $currentPatchCreated = $false
    $currentPatchAccepted = $false
    
    foreach ($line in $lines) {
        # Determine if we're in the site verification section
        if ($line -match 'SITE VERIFICATION CHECKLIST') {
            $inSiteSection = $true
            continue
        }
        if ($line -match 'TESTING INSTRUCTIONS') {
            $inSiteSection = $false
            continue
        }
        
        if ($inSiteSection) {
            # Count total sites and capture site names
            if ($line -match '^\d+\.\s+(.+)') {
                $totalSites++
                $currentSite = $matches[1]
                # Reset patch tracking for new site
                $currentPatchCreated = $false
                $currentPatchAccepted = $false
            }
            
            # Capture URL
            if ($line -match 'URL:\s*(.+)') {
                $currentUrl = $matches[1]
            }
            
            # Track patch information
            if ($line -match 'PatchCreated:\s*true') {
                $patchCreated++
                $currentPatchCreated = $true
                if ($currentSite) {
                    $sitesWithPatches += "$currentSite"
                }
            }
            
            if ($line -match 'PatchAccepted:\s*true') {
                $patchAccepted++
                $currentPatchAccepted = $true
                if ($currentSite) {
                    $sitesWithAcceptedPatches += "$currentSite"
                }
            }
            
            # Track pending patches (created but not accepted)
            if ($currentPatchCreated -and -not $currentPatchAccepted -and $line -match 'PatchAccepted:\s*false') {
                $patchPending++
                if ($currentSite) {
                    $sitesWithPendingPatches += "$currentSite"
                }
            }
            
            # Count testing status and track site details
            if ($line -match 'Tested:\s*PASS') {
                $testedPass++
                if ($currentSite) {
                    $passedSites += "$currentSite"
                }
            }
            elseif ($line -match 'Tested:\s*FAIL') {
                $testedFail++
                if ($currentSite) {
                    $failedSites += "$currentSite"
                }
            }
            elseif ($line -match 'Tested:\s*UNTESTED') {
                $untested++
            }
            
            # Count tag requirements and track sites needing tags
            if ($line -match 'TagNeeded:\s*(YES|true)') {
                $tagsYes++
                if ($currentSite) {
                    $sitesNeedingTags += "$currentSite"
                }
            }
            elseif ($line -match 'TagNeeded:\s*(NO|false)') {
                $tagsNo++
            }
            elseif ($line -match 'TagNeeded:\s*UNKNOWN') {
                $tagsUnknown++
            }
        }
    }
    
    # Display current statistics
    Write-Host "`nCurrent Statistics:" -ForegroundColor Cyan
    Write-Host "Total Sites: $totalSites" -ForegroundColor White
    Write-Host "Tested (PASS): $testedPass" -ForegroundColor Green
    Write-Host "Tested (FAIL): $testedFail" -ForegroundColor Red
    Write-Host "Untested: $untested" -ForegroundColor Yellow
    Write-Host "SecurityControl Tags Needed (YES): $tagsYes" -ForegroundColor Magenta
    Write-Host "SecurityControl Tags Needed (NO): $tagsNo" -ForegroundColor Green
    Write-Host "SecurityControl Tags Status Unknown: $tagsUnknown" -ForegroundColor Yellow
    Write-Host "Patches Created: $patchCreated" -ForegroundColor Cyan
    Write-Host "Patches Accepted: $patchAccepted" -ForegroundColor Green
    Write-Host "Patches Pending: $patchPending" -ForegroundColor Yellow
    
    # Calculate progress metrics
    $testedTotal = $testedPass + $testedFail
    $progressPercent = if ($totalSites -gt 0) { [math]::Round(($testedTotal / $totalSites) * 100, 1) } else { 0 }
    $passRate = if ($testedTotal -gt 0) { [math]::Round(($testedPass / $testedTotal) * 100, 1) } else { 0 }
    
    # Progress bar
    $barLength = 50
    $filledLength = [math]::Floor(($progressPercent / 100) * $barLength)
    $bar = "█" * $filledLength + "░" * ($barLength - $filledLength)
    $progressBar = "[$bar] $progressPercent%"
    
    # Create the summary file content
    $today = Get-Date -Format "MMMM d, yyyy"
    $summaryContent = @"
# Azure Demo Sites Verification Summary
# Last Updated: $today

================================================================================
SUMMARY STATISTICS
================================================================================
Total Sites: $totalSites
Tested (PASS): $testedPass
Tested (FAIL): $testedFail
Untested: $untested
SecurityControl Tags Needed (YES): $tagsYes
SecurityControl Tags Needed (NO): $tagsNo
SecurityControl Tags Status Unknown: $tagsUnknown
Patches Created: $patchCreated
Patches Accepted: $patchAccepted
Patches Pending: $patchPending

================================================================================
PROGRESS REPORT
================================================================================
Overall Testing Progress: $testedTotal/$totalSites sites ($progressPercent%)
Pass Rate: $testedPass/$testedTotal tested sites ($passRate%)
Progress Bar: $progressBar

================================================================================
BREAKDOWN BY STATUS
================================================================================
SITES THAT PASSED ($testedPass):
"@

    # Add passed sites to the summary
    if ($passedSites.Count -gt 0) {
        foreach ($site in $passedSites) {
            $summaryContent += "`n- $site (PASS)"
        }
    } else {
        $summaryContent += "`n- [None currently]"
    }

    $summaryContent += "`n`nSITES THAT FAILED ($testedFail):"
    
    # Add failed sites to the summary
    if ($failedSites.Count -gt 0) {
        foreach ($site in $failedSites) {
            $summaryContent += "`n- $site (FAIL)"
        }
    } else {
        $summaryContent += "`n- [None currently]"
    }

    $summaryContent += "`n`nSITES REQUIRING SECURITY TAGS ($tagsYes):"
    
    # Add sites needing tags to the summary
    if ($sitesNeedingTags.Count -gt 0) {
        foreach ($site in $sitesNeedingTags) {
            $summaryContent += "`n- $site"
        }
    } else {
        $summaryContent += "`n- [None currently]"
    }

    $summaryContent += "`n`nPATCH TRACKING:"
    $summaryContent += "`nSITES WITH PATCHES CREATED ($patchCreated):"
    
    # Add sites with patches created
    if ($sitesWithPatches.Count -gt 0) {
        foreach ($site in $sitesWithPatches) {
            $summaryContent += "`n- $site"
        }
    } else {
        $summaryContent += "`n- [None currently]"
    }

    $summaryContent += "`n`nSITES WITH PATCHES ACCEPTED ($patchAccepted):"
    
    # Add sites with patches accepted
    if ($sitesWithAcceptedPatches.Count -gt 0) {
        foreach ($site in $sitesWithAcceptedPatches) {
            $summaryContent += "`n- $site"
        }
    } else {
        $summaryContent += "`n- [None currently]"
    }

    $summaryContent += "`n`nSITES WITH PATCHES PENDING ($patchPending):"
    
    # Add sites with patches pending
    if ($sitesWithPendingPatches.Count -gt 0) {
        foreach ($site in $sitesWithPendingPatches) {
            $summaryContent += "`n- $site"
        }
    } else {
        $summaryContent += "`n- [None currently]"
    }

    $summaryContent += "`n`n================================================================================"
    
    # Write the summary to the separate file
    Write-Host "`nUpdating summary file: $SummaryFilePath" -ForegroundColor Green
    $summaryContent | Set-Content $SummaryFilePath -Encoding UTF8
    
    # Update the "Last Updated" date in the main checklist
    $checklistContent = Get-Content $ChecklistFilePath -Raw
    $updatedChecklistContent = $checklistContent -replace '# Last Updated: .*', "# Last Updated: $today"
    $updatedChecklistContent | Set-Content $ChecklistFilePath -Encoding UTF8
    
    Write-Host "Summary statistics updated successfully!" -ForegroundColor Green
    Write-Host "Last Updated date set to: $today" -ForegroundColor Green
    
    # Return metrics for progress display
    return @{
        TotalSites = $totalSites
        TestedPass = $testedPass
        TestedFail = $testedFail
        ProgressPercent = $progressPercent
        PassRate = $passRate
        ProgressBar = $progressBar
    }
}

function Show-Progress {
    param(
        [int]$TestedPass,
        [int]$TestedFail,
        [int]$TotalSites
    )
    
    $testedTotal = $TestedPass + $TestedFail
    $progressPercent = if ($TotalSites -gt 0) { [math]::Round(($testedTotal / $TotalSites) * 100, 1) } else { 0 }
    $passRate = if ($testedTotal -gt 0) { [math]::Round(($TestedPass / $testedTotal) * 100, 1) } else { 0 }
    
    Write-Host "`nProgress Report:" -ForegroundColor Cyan
    Write-Host "Overall Testing Progress: $testedTotal/$TotalSites sites ($progressPercent%)" -ForegroundColor White
    Write-Host "Pass Rate: $TestedPass/$testedTotal tested sites ($passRate%)" -ForegroundColor White
    
    # Progress bar
    $barLength = 50
    $filledLength = [math]::Floor(($progressPercent / 100) * $barLength)
    $bar = "█" * $filledLength + "░" * ($barLength - $filledLength)
    Write-Host "[$bar] $progressPercent%" -ForegroundColor Green
}

# Main execution
try {
    Write-Host "Azure Demo Sites Verification Statistics Updater" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    # Update the statistics
    $results = Update-VerificationStats -ChecklistFilePath $ChecklistPath -SummaryFilePath $SummaryPath
    
    if ($results) {
        Show-Progress -TestedPass $results.TestedPass -TestedFail $results.TestedFail -TotalSites $results.TotalSites
    }
    
    Write-Host "`nFiles updated:" -ForegroundColor Green
    Write-Host "- Checklist: $ChecklistPath" -ForegroundColor Gray
    Write-Host "- Summary: $SummaryPath" -ForegroundColor Gray
    Write-Host "`nScript completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}

# Usage examples
Write-Host "`nUsage Examples:" -ForegroundColor Yellow
Write-Host "  .\Update-VerificationStats.ps1" -ForegroundColor Gray
Write-Host "  .\Update-VerificationStats.ps1 -ChecklistPath 'custom-checklist.txt' -SummaryPath 'custom-summary.txt'" -ForegroundColor Gray