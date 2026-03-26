@echo off
REM ============================================================
REM SSVEP_Demo_Sel — Push to GitHub
REM Run this from the SSVEP_Demo_Sel\SSVEP_Demo_Sel folder
REM ============================================================

echo.
echo === Step 1: Initialize git repo ===
git init -b main
git add -A
git status

echo.
echo === Step 2: Create first commit ===
git commit -m "Initial commit: SSVEP BCI system with 15/20 Hz frequencies"

echo.
echo === Step 3: Create GitHub repo and push ===
echo You need the GitHub CLI (gh) installed. Get it from: https://cli.github.com
echo.
echo Running: gh repo create SSVEP_Demo_Sel --public --source=. --remote=origin --push
gh repo create SSVEP_Demo_Sel --public --source=. --remote=origin --push

echo.
echo === Done! ===
echo Your repo should now be at: https://github.com/maxporter016/SSVEP_Demo_Sel
echo.
echo To add collaborators, go to: Settings > Collaborators > Add people
pause
