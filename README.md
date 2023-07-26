<div align="center">
    <a href="https://github.com/ElliotKillick/Mido">
        <img width="160" src="logo.png" alt="Logo" />
    </a>
</div>

<h3 align="center">
    Mido
</h3>

<p align="center">
    The <b>Microsoft Windows Downloader</b> — designed to save you time
</p>

Mido makes downloading the latest release of Windows from **official** Microsoft servers a breeze so you can quickly get your VMs (or even physical machines) up & running in no time! No jumping though hoops to download the newest release of Windows the **second** Microsoft releases it required: just one command and you're done! It's very well-suited to full automation if you just want to set it and forget it too.

All in one super simple & secure script. Comes with advanced features like download resumption, SHA-256 checksum verification, and downloading many different Windows versions in a single command. Did I mention it's written in *pure* POSIX sh (w/ few coreutils) + curl so it will run anywhere (even on Windows with WSL or MSYS2)? So robust, very minimalist!

#### ❌ `https://www.microsoft.com/en-us/software-download/windows11`

<p align="center">
    <img src="bloatware.png" width="200" alt="Microsoft's bloatware"></img>
</p>

no

#### ✔️ Mido, the Microsoft Windows Downloader (using the **same** official Microsoft servers)

<p align="center">
    <img src="demo.gif" width="400" alt="Project demo GIF"></img>
</p>

## How does Mido work??

It interacts with Microsoft's [proprietary downloading API](https://www.microsoft.com/en-us/software-download/windows11) (reverse engineered thanks to Pete Batard, @pbatard) to grab the latest release of Windows and generate a fresh download link (valid for 24 hours). Then we grab that link and get the file over to you as quickly as possible!

## What else can Mido do?

Other than the consumer versions of Windows like 11 and 10, it can also automatically download the latest Server (e.g. Windows Server 2022) and Enterprise editions of every Windows version all the way back to Windows 7 (or Server 2008 R2)!

Want a more secure and minimalist Windows installation out-of-the-box that's officially provided by Microsoft? Then download the LTSC version of Windows. It comes with way less bloat and supports Microsoft's ["Security"](https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization#diagnostic-data-settings) telemetry mode (plus it comes with long-term support). Microsoft is yet to release an LTSC version of Windows 11 (so 10 only for now) but it is planned.

## Want to save more time?

Check out the `create-media.sh` script in [Qvm-Create-Windows-Qube](https://github.com/ElliotKillick/qvm-create-windows-qube/tree/master/windows)! Now complete with Mido Windows downloader *and* an answer file to go with each provided download. With that you will be saving time in downloading Windows *and* installing it to a VM. This is all very well-tested and could easily save you many hours of time over doing it manually. I tend to reinstall my Windows VMs quite often because they tend to get slow over time and so a refresh always helps.

## How secure is it *really*?

Mido is very secure. Every chance to reduce attack surface is taken. Untrusted data is treated as such with proper validation steps. The highest possible version of TLS is always used (up to TLS 1.3). Easily verify security properties yourself in the transparent shell script.

No web browser (e.g headless Chromium running JavaScript) reduces the attack surface by *many* orders of magnitude.

The next [Shellshock/Bashdoor](https://en.wikipedia.org/wiki/Shellshock_(software_bug))? POSIX sh compatible.
- Plus, automatically switches to a more secure shell if available

Frequent [Curl HTTP 2.0 & 3.0 bugs](https://github.com/curl/curl/issues?q=is%3Aissue+label%3Acrash)? Force HTTP/1.1.
- Comes at zero cost to performance for downloading files

Coreutil bugs? Only builtins are used for critical components.

Still bugs? Wrap it in bubble wrap: `bwrap --ro-bind / / --dev-bind /dev/null /dev/null --bind "$PWD" "$PWD" --ro-bind "$PWD/Mido.sh" "$PWD/Mido.sh" --unshare-all --share-net -- ./Mido.sh --help`
- This is the same sandbox used by Flatpak
- Compartmentalize further by running Mido in its own unprivileged user account or even it's own disposable VM on Qubes OS

With sandbox/VM escape or privilege escalation bugs? GG, you win!!

## Todo

- [ ] Make a small GUI wrapper for people who don't like running a single command
    - Ideally something lightweight and cross-platform (a GTK app that runs an embedded script?)
    - Should have a download progress bar (likely read from `curl` `stderr`) and shows an error log if anything goes wrong
    - Contributions are very welcome

## License

MIT License - Copyright (C) 2023 Elliot Killick <contact@elliotkillick.com>
