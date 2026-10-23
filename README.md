# Synaptics 06cb:009a on Arch and Omarchy

Packaging of [python-validity](https://github.com/uunicorn/python-validity) 0.15 for the Synaptics Metallica MIS fingerprint reader (`06cb:009a`), with the init-recovery patch from [python-validity pull request 290](https://github.com/uunicorn/python-validity/pull/290).

`libfprint` 1.94 talks to other Synaptics sensors. It does not list product `009a`, so `fprintd` reports "No devices available" on this hardware. `python-validity` is the free driver that does speak to it. Release 0.15 then fails to initialize on Python 3.14 and libusb 1.0.30: the sensor answers the first flash command before its firmware is loaded, the service crashes, and the Arch unit restarts it forever. The patch retries the busy replies, loads the firmware before touching the flash, resets the USB device when init fails, and caps those restarts.

## Tested

| | |
| --- | --- |
| Reader | `06cb:009a` Synaptics Metallica MIS, sensor `57K0 FM-3367-003` |
| Machine | Lenovo ThinkPad X1 Carbon 6th (`20KHCTO1WW`) |
| System | Omarchy, kernel `7.1.9-arch1-2` |
| Stack | Python 3.14.7, libusb 1.0.30, python-pyusb 1.3.1 |
| Result | Service stays up (`NRestarts=0`). Right index finger enrolled and `fprintd-verify` returned `verify-match`. |

The same USB id is on other Lenovo machines from that generation (ThinkPad T480, T480s, X1 Yoga, L390). The driver covers that id. Those machines were not part of this run.

## Install

Build tools and the two AUR dependencies come first. `fprintd-clients` conflicts with `fprintd`; remove `fprintd` when pacman asks. `libfprint` can stay installed.

```bash
sudo pacman -S --needed base-devel python-setuptools glib2-devel python-pyusb innoextract
yay -S fprintd-clients open-fprintd
```

Then build this package:

```bash
git clone https://github.com/Mauricio-xx/python-validity-06cb009a.git
cd python-validity-06cb009a
makepkg -si
```

The install masks the leftover `fprintd.service` (it would grab the same D-Bus name and point at a binary that is no longer there), turns off `--debug` on `open-fprintd`, and starts `python3-validity`. The first start needs a network connection: the daemon fetches the sensor firmware once.

```bash
fprintd-list "$USER"    # "found 1 devices"
fprintd-enroll          # rest the finger, lift it, repeat until enroll-completed
fprintd-verify
```

On Omarchy, after a finger is enrolled:

```bash
./setup-omarchy-pam.sh
```

That is the same sudo, polkit, and lock-screen PAM the Omarchy fingerprint wizard writes. The wizard itself also tries to install stock `fprintd`, which conflicts with this stack, so use the script here.

On other distributions, add `pam_fprintd.so` the way that distribution documents. `auth sufficient pam_fprintd.so` keeps the password as the fallback.

## After sleep

`python3-validity-suspend-hotfix.service` restarts the driver when the machine wakes. `open-fprintd` 0.7 has no `Resume` method on the manager, so the in-process resume from the patch is not what runs today. The password still unlocks the machine while the reader comes back.

## Updating

This package is `python-validity` 0.15-2. The AUR package of the same name is 0.15-1 and does not carry the patch. Installing that one over this build brings the restart loop back. Keep this package until the pull request is in an upstream release, then switch to that release.

## Credit

* Driver: [uunicorn/python-validity](https://github.com/uunicorn/python-validity), MIT, Copyright (c) 2020 uunicorn.
* Init fix: [pull request 290](https://github.com/uunicorn/python-validity/pull/290), from the diagnosis in [issue 272](https://github.com/uunicorn/python-validity/issues/272).
* D-Bus service in front of it: [uunicorn/open-fprintd](https://github.com/uunicorn/open-fprintd).

## License

MIT. See [LICENSE](LICENSE).
