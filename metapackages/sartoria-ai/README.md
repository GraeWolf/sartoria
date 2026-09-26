# sartoria-ai

One optional terminal recipe (Phase F7). Not a VM package. Not on the installer ISO. The desktop, network, NVIDIA driver, and updates work with this package absent.

`sartoria ai` on a system without this package prints that AI is optional and sends nothing. With the package installed, the recipe still sends nothing until a key exists.

The key is `XAI_API_KEY`, or one line in `~/.config/sartoria/ai/key` with mode 600. The package does not ship a key. A prompt goes to `https://api.x.ai/v1/responses` (`grok-4.7`, `store: false`). `SARTORIA_AI_MODEL` overrides the model.

The recipe may read, and may discuss edits to, `~/.config/sartoria` (except the key) and `~/.config/herbstluftwm/autostart`. It does not write them. The bootloader, LUKS, apt sources, and the installer are outside the recipe. Brave Origin is unchanged.

```bash
./scripts/build-sartoria-desktop.sh
./scripts/build-sartoria-ai.sh
sudo apt-get install ./lab/cache/sartoria-desktop_0.0.9_all.deb ./lab/cache/sartoria-ai_0.0.1_all.deb
sartoria ai status
sartoria ai policy
```

There is no session key for this. Nothing in the installer calls it.
