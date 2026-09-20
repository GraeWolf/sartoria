# sartoria-origin

Brave Origin apt overlay (Phase F2). Not a VM package. Not on the installer ISO.

Ships Brave’s signed release repo, an apt pin that allows `brave-origin` and blocks `brave-browser`, and `sartoria-browser` (Super+b). Firefox ESR may stay until Origin is installed. Do not run `curl | sh`.

```bash
./scripts/build-sartoria-origin.sh
sudo apt-get install ./lab/cache/sartoria-origin_0.0.1_all.deb
sudo apt-get update
sudo apt-get install brave-origin
```

`postinst` cannot `apt-get` (dpkg holds the lock). Same two-step as XLibre.

The PATH binary from the Origin package is `brave-origin-stable`. WM class is `brave-origin`.
