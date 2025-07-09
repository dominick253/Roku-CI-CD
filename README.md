# Roku CI/CD Pipeline Guide

Roll your own Roku CI/CD pipeline—leveraging BrighterScript (`bsc`) for builds and giving you full control over webhook‑driven builds, device deploys, and ECP‑based tests.

---

## 1. Repository Layout & Branch Strategy

1. **Monorepo or Single‑Channel Repo**  
```
/src ← Your channel code (BrightScript & assets)
/tests ← ECP‑driven ATF tests (JSON test specs)
/ci ← CI helper scripts (build, deploy, test)
.github/workflows ← (Optional) GitHub Actions for auxiliary jobs
```
2. **Branch Model**  
1. `main` (production)  
2. `develop` (integration)  
3. `feature/{…}` for in‑flight work  

---

## 2. GitHub Webhook → Build Server

1. **Webhook Receiver**  
- A tiny Node.js (Express) or Python (Flask) service with an endpoint like `/github-webhook`.  
- Verifies GitHub HMAC signature.  
- Filters for `push` (or `workflow_dispatch`) on `develop` or PR events.  

2. **Pull & Checkout**
  
```bash
git clone --depth=1 https://github.com/dominick253/Roku-CI-CD.git $WORKDIR
cd $WORKDIR
git checkout $GITHUB_REF


    Dependency Install

    npm ci       # for any JS tooling or test runners
    pip install -r requirements.txt  # if using Python helpers
```

3. Build with BrighterScript (bsc)

    Build Script (ci/build.sh):
```bash
#!/usr/bin/env bash
set -e
bsc --config=bsconfig.json
zip -r dist/Channel.zip out/manifest out/source out/components
```

bsconfig.json should include:

```json
    {
      "entries": ["src/manifest"],
      "outDir": "out",
      "rootDir": "src",
      "files": ["src/components", "src/source"]
    }
```

    Output

        A deployable ZIP in dist/Channel.zip.

4. Device Deployment via ECP

    Prerequisites

        Roku in Developer Mode at 10.71.71.152

        A device PIN set for installs.

    Deploy Script (ci/deploy.sh):

```bash
#!/usr/bin/env bash
set -e
DEVICE_IP="10.71.71.152"
DEVICE_PIN="<YOUR_DEVICE_PIN>"
curl -d @"dist/Channel.zip" \
  -u :$DEVICE_PIN \
  -H "Content-Type: application/zip" \
  "http://$DEVICE_IP/plugin_install"
```

Verify Install

```bash
    curl "http://10.71.71.152/query/apps" | grep "Your Channel Name"
```

5. Automated Testing with ECP (ATF)

    Trigger Tests (ci/test.sh):

```bash
#!/usr/bin/env bash
set -e
DEVICE_IP="10.71.71.152"
curl \
  -H "Content-Type: application/json" \
  -d @tests/atf-spec.json \
  "http://$DEVICE_IP/robot/run"
```

Poll for Results:

```bash
    # wait for completion, then:
    curl "http://10.71.71.152/robot/log" > reports/atf.log
```

    Parse & Report
```bash
        grep "FAILED" reports/atf.log → exit code
```
        Archive logs/screenshots to your CI dashboard or S3.

6. Orchestration & Notifications

    Orchestrator Script (ci/pipeline.sh):
```bash
    #!/usr/bin/env bash
    set -e
    ./ci/build.sh
    ./ci/deploy.sh
    ./ci/test.sh
```

    Status Hooks

        On success/failure, POST back to GitHub via the Status API.

        Send Slack/Webhook alerts with test logs.

7. Scaling & Enhancements

    Parallel Devices: maintain a small device‑farm, pass device IP via matrix orchestrator.

    Containerize: Dockerize build/test toolchain for consistent environments.

    Caching: Persist node_modules or bsc cache between runs.

    Security: Store your device PIN and webhook secret in an encrypted vault (e.g., AWS Secrets Manager).

8. Alternative: Hybrid with GitHub Actions + Self‑Hosted Runners

Use the roku-ci GitHub Action for a quicker setup:

```yml
# .github/workflows/ci.yml
on:
  push:
    branches: [ develop, main ]
  pull_request:

jobs:
  build-deploy-test:
    runs-on: self-hosted   # your runner with network access to 10.71.71.152
    steps:
      - uses: actions/checkout@v3
      - name: Build
        uses: rokucommunity/roku-ci@v1
        with:
          action: build
      - name: Deploy
        uses: rokucommunity/roku-ci@v1
        with:
          action: deploy
          device_ip: 10.71.71.152
          device_pin: ${{ secrets.ROKU_PIN }}
      - name: Test
        uses: rokucommunity/roku-ci@v1
        with:
          action: test
```
