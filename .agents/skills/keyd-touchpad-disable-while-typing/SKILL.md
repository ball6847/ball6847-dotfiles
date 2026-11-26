---
name: keyd-touchpad-disable-while-typing
description: >
  Configure libinput so disable-while-typing keeps working when keyd grabs the
  physical keyboard and emits a uinput virtual keyboard. Use when a Linux
  laptop's touchpad stays active while typing after installing keyd, when
  copying a working keyd setup to another machine, or when adding the libinput
  quirk for keyd virtual keyboard. Trigger on "keyd touchpad", "disable while
  typing keyd", "touchpad still active while typing", "keyd libinput quirk",
  "copy keyd setup", "ตั้งค่า keyd เครื่องใหม่", "touchpad ยังขยับตอนพิมพ์".
---

# keyd and touchpad disable while typing

## What this fixes

keyd grabs the physical keyboard with `EVIOCGRAB`, then emits a new keyboard
through `/dev/uinput` named `keyd virtual keyboard`. libinput sees that virtual
device instead of the laptop's real keyboard.

libinput decides whether disable-while-typing applies by checking whether the
keyboard is internal. The keyd virtual keyboard looks like an external USB
keyboard unless a quirk marks it internal. The fix lives in libinput, not in
systemd. `keyd.service` only starts the daemon.

## Scope

Use this on Linux with:

1. keyd running as a system service
2. libinput handling input in GNOME, KDE, or another libinput based session
3. a touchpad that should stop responding while keys are pressed

Skip this on macOS, Windows, or systems using a different input stack without
libinput.

## Procedure

### 1. Install and start keyd

Install keyd using the method supported on the target machine. On the reference
host it was built under `/opt/keyd`, with `/usr/local/bin/keyd` and
`/usr/local/lib/systemd/system/keyd.service`. Do not copy those paths blindly.
Check the real paths first.

```bash
command -v keyd
systemctl status keyd --no-pager
```

If keyd is installed but the service is not enabled:

```bash
sudo systemctl enable --now keyd
```

### 2. Make sure keyd matches the physical keyboard

Inspect `/etc/keyd/default.conf`. It needs an `[ids]` section that matches the
physical keyboard. A wildcard is fine.

```ini
[ids]

*

[main]
```

If keyd ignores the keyboard, it never grabs the events and this quirk will
not help. Check the journal for `DEVICE: ignoring` lines.

```bash
journalctl -u keyd --no-pager | tail -40
```

### 3. Add the libinput quirk

Inspect `/etc/libinput/local-overrides.quirks` first. Do not overwrite other
quirks. Append this block if the section is not already there. On libinput
1.31, `MatchUdevType=keyboard` is required; a `MatchName`-only block may verify
with the quirk CLI yet fail to pair in GNOME.

```bash
sudo install -d -m 0755 /etc/libinput
sudo touch /etc/libinput/local-overrides.quirks
if sudo grep -q '^\[Serial Keyboards\]$' /etc/libinput/local-overrides.quirks; then
  echo 'Section already exists. Inspect it before adding another block.'
else
  sudo tee -a /etc/libinput/local-overrides.quirks >/dev/null <<'EOF'

[Serial Keyboards]
MatchUdevType=keyboard
MatchName=keyd*keyboard
AttrKeyboardIntegration=internal
EOF
fi
```

The canonical block is:

```ini
[Serial Keyboards]
MatchUdevType=keyboard
MatchName=keyd*keyboard
AttrKeyboardIntegration=internal
```

If the section exists with different values, replace its four lines with the
canonical block.

### 4. Recreate the virtual keyboard

Restart keyd so libinput sees a fresh virtual device and reads the new quirk.

```bash
sudo systemctl restart keyd
```

The keyboard may pause briefly. Run this over SSH when working on a laptop you
cannot easily recover if input stalls.

An alternative is to unplug and replug the physical keyboard, or log out and
back into the graphical session.

### 5. Enable disable-while-typing in the desktop session

GNOME:

```bash
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
```

KDE:

Open System Settings, then Input Devices, then Touchpad, then enable
"Disable while typing".

Other desktops need their own touchpad setting, or a libinput configuration
that sets `DisableWhileTyping` for the touchpad.

### 6. Verify

```bash
systemctl is-active keyd
gsettings get org.gnome.desktop.peripherals.touchpad disable-while-typing
grep -A8 -i 'keyd virtual keyboard' /proc/bus/input/devices
cat /etc/libinput/local-overrides.quirks
```

Verify the quirk on the virtual keyboard itself. Install `libinput-tools` if
`libinput` is missing. Use the `eventN` from the `H: Handlers=` line in the
`keyd virtual keyboard` block.

```bash
libinput quirks validate
libinput quirks list /dev/input/eventN
```

Expected output includes `AttrKeyboardIntegration=internal`.

Then test in a graphical session. Hold any key for about one second and swipe
the touchpad during that time. The pointer should not move.

A TTY session cannot prove this works. Check the session type if the result is
unclear.

```bash
echo "$XDG_SESSION_TYPE"
```

## Troubleshooting

1. `keyd virtual keyboard` is missing from `/proc/bus/input/devices`

   keyd is not running or failed to create its uinput device. Check
   `systemctl status keyd --no-pager` and `journalctl -u keyd`.

2. The virtual keyboard has a different name

   Change `MatchName` to match the `N: Name=` line from
   `/proc/bus/input/devices`, then restart keyd.

3. The setting is true but the touchpad still moves

   Confirm you are testing in the same graphical session that owns the
   touchpad. Restart keyd after changing the quirk. Log out and back in if the
   compositor cached the old device properties. On libinput 1.31, verify the
   quirk has `MatchUdevType=keyboard`; a `MatchName`-only block can still print
   `AttrKeyboardIntegration=internal` from the quirk CLI but not pair the
   keyboard in an already-running GNOME session.

4. `gsettings` reports no schema

   You are likely in a TTY, a container, or a non-GNOME session. Use the
   touchpad settings for the active desktop instead.

5. The keyboard is external and you only want this behavior on the internal keyboard

   keyd merges keyboards into one virtual device. The quirk marks all keyd
   keyboards as internal on purpose. Narrow the `[ids]` section in keyd if that
   matters.

## What not to change

Do not add touchpad commands to `keyd.service`. That service only starts keyd.
Do not permanently disable the touchpad with `xinput` or a similar tool, since
that removes all pointer movement instead of pausing it during typing.
