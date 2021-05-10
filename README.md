# StopContainers

StopContainers is a function that stops subscription containers that have been active for more than N minutes, with N being a variable $minutes defined in the profile.ps1 file.

## Triggers

The function has a single trigger that is activated every 5 minutes, and makes the check explained above.