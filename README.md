## Individual Lab- Chrys Elisée Gnagne
```markdown
# deploy_agent_Pirate13Thebes

A shell script that automates the bootstrapping of a Student Attendance Tracker project workspace.

## Repository Structure

```
deploy_agent_Pirate13Thebes/
├── setup_project.sh
├── README.md
├── .gitignore
├── attendance_checker.py
├── assets.csv
├── config.json
└── reports.log
```

## How to Run

```bash
chmod +x setup_project.sh
./setup_project.sh
```

You will be prompted to:
1. Enter a project name (e.g. `v1`) — creates `attendance_tracker_v1/`
2. Optionally update the warning/failure attendance thresholds
3. A health check will verify your Python3 installation and directory structure

## Generated Project Structure

```
attendance_tracker_{input}/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
└── reports/
    └── reports.log
```

## How to Trigger the Archive Feature

While the script is running, press **Ctrl+C** at any point.

The script will:
- Catch the SIGINT signal
- Bundle the incomplete project into `attendance_tracker_{input}_archive.tar.gz`
- Delete the incomplete directory
- Exit cleanly

## Threshold Configuration

When prompted during setup, you can override the default thresholds:
- **Warning** (default: 75%) — students below this receive a warning
- **Failure** (default: 50%) — students below this are at risk of failing

The script uses `sed` to edit `config.json` in-place with the new values.

## Run-Through Video

[Watch the full walkthrough here]
https://drive.google.com/file/d/1F0yutrzY7ZOAcvXuk-7YGepU8abtawTy/view?usp=sharing


