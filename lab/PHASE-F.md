# Phase F — Daily-driver extras

Started 2026-09-20 on **voyager** (ASUS ROG Zephyrus G15 GA503RM). Phase E (hybrid Prime) is closed. This phase is “willing to daily-drive,” not a new ISO gate. v0.1 ISO remains Phase D.

Suggested product order was Origin → LibreOffice → daily bits → games → LUKS last → AI last. **F1 jumped the line:** Alacritty on this machine was falling back to DejaVu Sans (proportional), so letters ran together or showed gaps.

Do **not** LUKS voyager’s current disk first. Firefox ESR can stay until Origin is packaged. OS must work with zero AI.

| Id | Item | Status |
| --- | --- | --- |
| F1 | Alacritty / Nerd Font actually installed; monospace, not DejaVu Sans | fix applied on voyager (user fonts); confirm in a new Alacritty. `sartoria-desktop` 0.0.3 built; `dpkg -i` needs sudo |
| F2 | Brave Origin (pinned Brave apt repo, `brave-origin`) | not started |
| F3 | LibreOffice from Excalibur + floating dialog rules | not started |
| F4 | Remaining daily bits (file manager, screenshots, laptop DPI) | not started |
| F5 | Optional `sartoria-games` | not started |
| F6 | Laptop LUKS profile on a **spare** disk / second install | not started |
| F7 | Optional `sartoria-ai` (last) | not started |

Not this gate: desktop dGPU, reverse-PRIME HDMI, `nvidia-persistenced` as a required daemon, `sartoria-nvidia` on the v0.1 ISO.

## F1 — Terminal font

`sartoria-desktop` 0.0.2 shipped an empty `/usr/share/fonts/truetype/sartoria` because the desktop build only extracted Nerd Fonts if `lab/cache/JetBrainsMonoNerdFont.zip` already existed. It never downloaded the zip. The session config asked for `JetBrainsMono Nerd Font`; `fc-match` returned **DejaVu Sans**.

That is the spacing bug: a proportional font in a terminal cell grid.

Fix in `sartoria-desktop` 0.0.3:

- Build downloads Nerd Fonts v3.4.0 if the zip is missing.
- Package ships Regular + Bold of **Nerd Font** (polybar/rofi/GTK) and **Nerd Font Mono** (Alacritty).
- Alacritty uses `JetBrainsMono Nerd Font Mono` (Nerd Fonts’ monospaced flavor; icons stay inside the cell).
- fontconfig aliases those families through `JetBrains Mono` then `monospace`, never a proportional default.

```bash
fc-match "JetBrainsMono Nerd Font Mono"
# expect: JetBrainsMonoNerdFontMono-Regular.ttf, not DejaVuSans.ttf
fc-match "JetBrainsMono Nerd Font"
# expect: JetBrainsMonoNerdFont-Regular.ttf
```

Restart Alacritty after install. Existing `~/.config/alacritty/alacritty.toml` is not overwritten by `seed-user-config`; copy the family name from `/usr/share/sartoria/config/alacritty/alacritty.toml` if the session was seeded before 0.0.3.

Panel is 2560×1440 at ~189 DPI; `Xft.dpi` is still 96. That makes glyphs small, not unevenly spaced. DPI is F4 if 96 is wrong for daily use.

## F2 — Brave Origin (next)

Pinned extra repo, same shape as XLibre. Official Debian instructions:

```bash
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
  https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
sudo apt-get update
sudo apt-get install brave-origin
```

Do not install `brave-browser` (the AI-capable product). Ship this as a signed, documented pin — not `curl | sh`. Not on the v0.1 ISO.

## Later

- **F3.** `libreoffice` from Excalibur. herbstluftwm floating rules for dialogs.
- **F4.** Daily bits only after the terminal, browser, and office do not block work.
- **F5.** `sartoria-games` after NVIDIA; optional.
- **F6.** LUKS installer profile. Prove on a spare disk. v0.1 stays whole-disk ext4, no encryption.
- **F7.** `sartoria-ai` last and optional.

## Exit

Willing to daily-drive this G15.
