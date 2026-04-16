# deploy_agent_Pirate13Thebes

## Description

A shell script that automates the bootstrapping of a Student Attendance Tracker project workspace.

## How to Run

```bash

chmod +x setup_project.sh

./setup_project.sh

```

You will be prompted to:

1. Enter a project name (e.g. `v1`) — creates `attendance_tracker_v1/`

2. Optionally update the warning/failure attendance thresholds

3. A health check will verify your Python3 installation and directory structure

## How to Trigger the Archive Feature

While the script is running, press **Ctrl+C** at any point.

The script will:

- Catch the SIGINT signal

- Bundle the current (incomplete) project into `attendance_tracker_{input}_archive.tar.gz`

- Delete the incomplete directory

- Exit cleanly

## Project Structure Created

```

attendance_tracker_{input}/

├── attendance_checker.py

├── Helpers/

│   ├── assets.csv

│   └── config.json

└── reports/

    └── reports.log

```
