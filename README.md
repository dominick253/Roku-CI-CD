#CI-CD-Roku

🚀 Automated CI/CD Pipeline for Roku SceneGraph & BrighterScript Projects

This project provides a fully automated, self-hosted CI/CD pipeline for Roku app development, leveraging:

    GitHub Actions for webhook-triggered builds

    Custom Linux runner for local signing & deployment

    BrighterScript (bsc) for clean builds & linting

    ECP device deployment & automated smoke tests

#Features

✅ **Automatic build on push or PR to main / develop
✅ BrighterScript linting & compilation checks
✅ Packaging with developer certificate & password
✅ Deploys to a Roku device via ECP for smoke tests
✅ Version tagging & artifact archiving for releases
✅ Modular, extensible structure for team pipelines


#Project Structure

```
.
├── .github/workflows/         # GitHub Actions workflows
├── scripts/                   # Helper scripts for build/deploy
├── src/                       # Roku source code (SceneGraph / BrighterScript)
└── README.md
```

    roku-deploy.yml — CI workflow for lint, build, deploy

    scripts/package.sh — Packages your Roku app

    scripts/deploy.sh — Pushes package to Roku device via ECP

    scripts/lint.sh — Runs bsc linting & compile checks

#Prerequisites

    GitHub repository

    Roku device on same LAN (developer mode enabled)

    Developer certificate & password

    Self-hosted Linux runner (or local machine) with:

        Node.js (bsc)

        curl

        zip/unzip

        GitHub Actions runner

#Setup
1️⃣ Enable Developer Mode on Roku

    Home 3x, Up 2x, Right, Left, Right, Left, Right

    Enable Developer Mode, set password, note IP address.

2️⃣ Configure Secrets

Add these repository secrets on GitHub:
Secret Name	Description
ROKU_DEV_IP	Roku device IP address
ROKU_DEV_USER	Usually rokudev
ROKU_DEV_PASSWORD	Your developer mode password
ROKU_SIGNING_KEY	Your developerID or path to .pkg
ROKU_SIGNING_PASSWORD	Signing password
3️⃣ Install & Configure Runner (if self-hosting)

# On your self-hosted Linux box:
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.325.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.325.0/actions-runner-linux-x64-2.325.0.tar.gz
tar xzf actions-runner-linux-x64-2.325.0.tar.gz
./config.sh --url https://github.com/YOUR_USERNAME/CI-CD-Roku --token YOUR_TOKEN
./run.sh

4️⃣ Push to Trigger Build

Commit & push to test, and GitHub Actions will:

    Run lint & build

    Package the app

    Deploy to Roku device

    Run ECP-based smoke tests
