<#
.SYNOPSIS
    This script sets up standard "best-practice" files for a software repository.
    It should be run once from the root directory of the local repository.

.DESCRIPTION
    This script will create:
    - .gitignore: To exclude common system and editor files.
    - LICENSE: An MIT License file.
    - CHANGELOG.md: A file to track project versions and changes.
    - .github/workflows/shellcheck.yml: A GitHub Action to lint the script.

.NOTES
    Author: RLMX Tech/Gemini
    Version: 1.0
#>

# --- Main Functions ---

function Create-Gitignore {
    Write-Host "--- Creating .gitignore file... ---" -ForegroundColor Cyan
    if (Test-Path ".gitignore") {
        Write-Host ".gitignore already exists. Skipping." -ForegroundColor Yellow
        return
    }

    $gitignoreContent = @"
# OS-generated files
.DS_Store
Thumbs.db

# Editor-specific files
.vscode/
*.swp
*.swo

# Local environment files
.env
"@
    Set-Content -Path ".gitignore" -Value $gitignoreContent
    Write-Host "✅ .gitignore created successfully." -ForegroundColor Green
}

function Create-License {
    Write-Host "`n--- Creating LICENSE file... ---" -ForegroundColor Cyan
    if (Test-Path "LICENSE") {
        Write-Host "LICENSE already exists. Skipping." -ForegroundColor Yellow
        return
    }

    $copyrightHolder = Read-Host -Prompt "Enter the full name for the copyright holder (e.g., Russ Morefield)"
    if ([string]::IsNullOrWhiteSpace($copyrightHolder)) {
        $copyrightHolder = "Russ Morefield" # Default value
    }
    $currentYear = Get-Date -Format "yyyy"

    $licenseContent = @"
MIT License

Copyright (c) $currentYear $copyrightHolder

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@
    Set-Content -Path "LICENSE" -Value $licenseContent
    Write-Host "✅ LICENSE (MIT) created successfully." -ForegroundColor Green
}

function Create-Changelog {
    Write-Host "`n--- Creating CHANGELOG.md file... ---" -ForegroundColor Cyan
    if (Test-Path "CHANGELOG.md") {
        Write-Host "CHANGELOG.md already exists. Skipping." -ForegroundColor Yellow
        return
    }

    $changelogContent = @"
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - Unreleased

### Added
- Initial creation of the master bootstrap script.
- Functionality for secure user creation and SSH hardening.
- Functionality for Oh My Posh installation and uninstallation.
- Functionality for Docker installation.
- Automatic system discovery on script startup.
"@
    Set-Content -Path "CHANGELOG.md" -Value $changelogContent
    Write-Host "✅ CHANGELOG.md created successfully." -ForegroundColor Green
}

function Create-ShellcheckWorkflow {
    Write-Host "`n--- Creating GitHub Actions workflow for ShellCheck... ---" -ForegroundColor Cyan
    $workflowDir = ".github/workflows"
    $workflowFile = Join-Path -Path $workflowDir -ChildPath "shellcheck.yml"

    if (Test-Path $workflowFile) {
        Write-Host "ShellCheck workflow already exists. Skipping." -ForegroundColor Yellow
        return
    }

    New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null

    $workflowContent = @"
# GitHub Action for ShellCheck
#
# This workflow automatically runs the ShellCheck linter on all shell scripts
# in the repository every time a change is pushed to the 'main' branch.
# This helps catch common bugs and syntax errors.

name: ShellCheck Linter

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  shellcheck:
    name: Run ShellCheck
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Run ShellCheck
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: './'
"@
    Set-Content -Path $workflowFile -Value $workflowContent
    Write-Host "✅ GitHub Actions workflow created successfully at $workflowFile." -ForegroundColor Green
}

# --- Script Execution ---
Create-Gitignore
Create-License
Create-Changelog
Create-ShellcheckWorkflow

Write-Host "`n--- ✅ Repository setup complete! ---" -ForegroundColor Yellow
Write-Host "Next steps:"
Write-Host "1. Review the newly created files."
Write-Host "2. Add, commit, and push them to your GitHub repository:"
Write-Host "   git add ." -ForegroundColor Cyan
Write-Host "   git commit -m `"feat: Add repository standards and CI workflow`"" -ForegroundColor Cyan
Write-Host "   git push" -ForegroundColor Cyan
Write-Host "3. Monitor the GitHub Actions tab for the ShellCheck results." -ForegroundColor Cyan
Write-Host "4. Enjoy your standardized repository!" -ForegroundColor Green
Write-Host "`n--- Thank you for using this setup script! ---" -ForegroundColor Magenta
# End of script
# --- End of Main Functions ---