# Roku CI/CD Pipeline

This is my setup for a CI/CD pipeline for Roku apps using BrightScript, SceneGraph, and BrighterScript. It automates testing, building, and deploying to a physical Roku device when I push to the Test branch. I’m using an Ubuntu 25 LXC container with VS Code remote, so everything’s tailored to that. Here’s how it works and how to set it up.

# Goals
1. Run automated tests on a physical Roku device.
2. Build Roku apps with the BrighterScript CLI (bsc).
3. Trigger builds via GitHub Webhooks and Actions on Test branch pushes.
4. Run a web server to handle Webhooks and kick off builds.
5. Deploy the built app to a Roku device automatically.

Prerequisites
1. Ubuntu 25 LXC container (or similar Linux setup).
2. Roku device on the same network with developer mode enabled (http://<ROKU_IP>).
3. VS Code with Remote - SSH and BrightScript Language extension.
4. GitHub repo with a Test branch.

