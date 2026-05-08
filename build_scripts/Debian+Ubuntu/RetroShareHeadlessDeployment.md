# RetroShare Debian 12 Headless Deployment

This guide matches the artifact produced by `.github/workflows/build-debian12-service.yml`.

## 1. Trigger the build

From GitHub Web UI:

1. Open `Actions`.
2. Select `Build Debian 12 Headless Service`.
3. Click `Run workflow`.

From `gh` CLI:

```bash
gh workflow run build-debian12-service.yml
gh run watch
gh run download --name retroshare-debian12-service --dir ./retroshare-artifact
```

After download, the payload layout is expected to be:

```text
retroshare-artifact/
  bin/retroshare-service
  lib/libretroshare.so*
  share/retroshare/webui/
  deploy/retroshare.service
  README-DEPLOY.md
```

## 2. Prepare the Debian 12 server

Create a dedicated service user:

```bash
sudo useradd \
  --system \
  --home /var/lib/retroshare \
  --create-home \
  --shell /usr/sbin/nologin \
  retroshare
```

Create an install directory and unpack the artifact:

```bash
sudo mkdir -p /opt/retroshare-headless
sudo cp -a ./retroshare-artifact/. /opt/retroshare-headless/
sudo chown -R root:root /opt/retroshare-headless
```

Install runtime libraries from Debian repositories. The exact package set may
vary with your base image, so use the `deploy/ldd-retroshare-service.txt` file
from the artifact as the source of truth if you need to resolve missing shared
libraries.

## 3. Bootstrap the RetroShare profile once

The Web UI cannot create a new RetroShare node from scratch. Create the node on
another machine first, then copy that RetroShare profile into the same base
directory you will pass to `--base-dir`, for example `/var/lib/retroshare`.

Before enabling `systemd`, do one interactive bootstrap run as the `retroshare`
user so you can:

1. Select the existing account.
2. Enter the profile password.
3. Register the Web UI password.

Example:

```bash
sudo -u retroshare env LD_LIBRARY_PATH=/opt/retroshare-headless/lib \
  /opt/retroshare-headless/bin/retroshare-service \
  --base-dir /var/lib/retroshare \
  --jsonApiPort 9092 \
  --jsonApiBindAddress 127.0.0.1 \
  --webui-directory /opt/retroshare-headless/share/retroshare/webui \
  -U list \
  -W
```

After that initial bootstrap, stop the foreground process with `Ctrl+C`.

## 4. Install the systemd unit

Copy the provided unit file:

```bash
sudo cp /opt/retroshare-headless/deploy/retroshare.service \
  /etc/systemd/system/retroshare.service
```

Reload `systemd`, enable the service, and start it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now retroshare.service
sudo systemctl status retroshare.service
```

Useful diagnostics:

```bash
sudo journalctl -u retroshare.service -f
sudo -u retroshare env LD_LIBRARY_PATH=/opt/retroshare-headless/lib \
  /opt/retroshare-headless/bin/retroshare-service --help
```

## 5. Access the Web UI through SSH forwarding

Keep the JSON API bound to `127.0.0.1`. Then create an SSH tunnel from your
local machine:

```bash
ssh -L 9092:127.0.0.1:9092 <user>@<azure-vm> -N
```

Open this URL locally:

```text
http://127.0.0.1:9092/index.html
```

## 6. Important notes

- This workflow builds the CMake headless service target with `RS_JSON_API`,
  `RS_WEBUI`, and `RS_RNPLIB`.
- It does not enable `rs_autologin`; the service still expects an already
  bootstrapped profile and a password-capable first run.
- The artifact intentionally ships the Web UI static files in
  `share/retroshare/webui/`. Shipping only `retroshare-service` and
  `libretroshare.so` is not enough for Web UI deployment.
