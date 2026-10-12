<div align="center">
    <a href="https://github.com/BENDER35/Mido_2026">
        <img width="160" src="assets/logo.png" alt="Logo" />
    </a>
</div>

<h3 align="center">
    Mido 2026
</h3>

<p align="center">
    The <b>Secure</b> Microsoft Windows Downloader
</p>

<p align="center">
    <a href="README.md">English</a> · <a href="README.es.md">Español</a>
</p>

Mido is a secure and open source download client for Microsoft's (reverse engineered) proprietary downloading API! Downloads are sourced from **official** Microsoft servers and you only have to run one command to go from start to finish in no time!

Comes with advanced features like download resumption, SHA-256 checksum verification, retry logic, multilingual ISOs (English, Spanish and Mexican Spanish) and downloading many different Windows versions in a single command. Did I mention it's written in *pure* POSIX sh (w/ few coreutils) + curl so it will run anywhere (even on Windows with WSL or a Cygwin shell)? So robust, very minimalist!

> **2026 update:** Microsoft replaced their old HTML download API with a JSON
> `software-download-connector` API protected by an anti-abuse service
> (Microsoft Sentinel). Mido 2026 implements the new API and the required
> handshake, fixes several shell bugs, adds retry logic and adds Spanish
> language support. See [docs/TECHNICAL.md](docs/TECHNICAL.md) for the details.

#### ❌ Microsoft's Media Creation Tool (`mediacreationtool.exe` proprietary bloatware)

<p align="center">
    <img src="assets/bloatware1.png" alt="Microsoft's proprietary bloatware executable"></img>
    <br />
    <img src="assets/bloatware2.png" width="250px" alt="Microsoft's proprietary bloatware"></img>
    <img src="assets/bloatware3.png" width="200px" alt="Microsoft's bloatware"></img>
</p>

Bloated website: `https://www.microsoft.com/en-us/software-download/windows11`
- Mido provides the exact same downloads as this website (it uses the same API)

#### ✅ Mido (using the **same** official Microsoft servers; <img src="https://awesome.re/badge.svg" style="position: relative; top: 5px;"></img> open source software)

<p align="center">
    <img src="assets/demo.gif" width="400" alt="Project demo GIF"></img>
</p>

## Get Mido

Get [Mido.sh](https://raw.githubusercontent.com/BENDER35/Mido_2026/main/Mido.sh) by opening the link, right-clicking and then selecting "Save [Page] as..."

### Requirements

Mido is written in **pure POSIX `sh`** and only needs a few tools that are
already present on almost every Linux system. On a normal desktop install you
do **not** have to install anything except, on some minimal images, **`curl`**.

| Tool | Used for | Package |
|---|---|---|
| `sh` | running the script (Dash is preferred and used automatically if present) | `dash` / `bash` |
| `curl` | talking to Microsoft's servers | `curl` |
| `sha256sum` | verifying downloaded ISOs | `coreutils` |
| `grep`, `sed`, `tr`, `cut`, `head`, `tail`, `fold`, `printf` | parsing the download API responses | `coreutils`, `grep`, `sed` |
| `tput` | colored output (optional) | `ncurses` |
| `uuidgen` | generating a session ID **only** on systems without `/proc` (macOS/BSD — never needed on Linux) | `util-linux` / built-in on macOS |

If something is missing, install it with your distribution's package manager:

| Distribution | Command |
|---|---|
| Debian / Ubuntu / Mint / Pop!\_OS / Kali / Raspberry Pi OS | `sudo apt update && sudo apt install -y curl` |
| Fedora | `sudo dnf install -y curl` |
| RHEL / CentOS Stream / Rocky / AlmaLinux | `sudo dnf install -y curl` (older: `sudo yum install -y curl`) |
| openSUSE Leap / Tumbleweed / SLES | `sudo zypper install -y curl` |
| Arch / Manjaro / EndeavourOS / Garuda | `sudo pacman -S --needed curl` |
| Alpine | `sudo apk add curl` |
| Void | `sudo xbps-install -S curl` |
| Gentoo / Funtoo | `sudo emerge net-misc/curl` |
| NixOS | `nix-shell -p curl` (or add `pkgs.curl` to `environment.systemPackages`) |
| Slackware | `sudo slackpkg install curl` |
| Solus | `sudo eopkg install curl` |
| Clear Linux | `sudo swupd bundle-add curl` |
| FreeBSD | `sudo pkg install curl` (coreutils and util-linux are preinstalled) |
| macOS | `curl` and `uuidgen` are preinstalled; install GNU coreutils for `sha256sum`: `brew install coreutils` and add `$(brew --prefix coreutils)/libexec/gnubin` to your `PATH` |

> You can confirm everything is in place by running `./Mido.sh --help`, which
> prints the media list without touching the network.

### Mac & Linux

Download `Mido.sh`, then open a terminal, give the file execution permissions
and run it (as seen in the GIF above):

```sh
chmod +x Mido.sh
./Mido.sh win11x64
```

### Windows

Mido is a POSIX shell script, so it does **not** run natively in `cmd.exe` or
PowerShell — on Windows you run it inside **WSL (Windows Subsystem for Linux)**,
which provides a real Linux environment. This is the recommended and fully
supported way. The bundled `Mido.bat` / `Mido.ps1` wrappers detect WSL and do
this for you (see *Windows Native Wrappers* below).

Alternatively you can use a POSIX emulation layer such as
[Cygwin](https://www.cygwin.com/install.html) or
[MSYS2](https://www.msys2.org/#installation), installed in one command with
WinGet:

```
winget install -e --id Cygwin.Cygwin
winget install -e --id MSYS2.MSYS2
```

#### Step 1 — Install WSL on Windows 11

Open **PowerShell as Administrator** (right-click the Start button →
*Terminal (Admin)*) and run:

```powershell
wsl --install
```

This enables the required Windows features, installs the WSL2 Linux kernel and
a Linux distribution (Ubuntu by default), then asks you to reboot. After the
reboot, Ubuntu opens and asks you to create a username and password. That's it.

#### Step 1 (alternative) — Install WSL on Windows 10

> **Windows 10 support status.** Windows 10 reached **end of support on
> 14 October 2025**. Home/Pro devices can join the **Consumer ESU** program,
> which only delivers security updates until **13 October 2026**. Commercial
> devices (Enterprise/Education/Pro used commercially) get up to **three years**
> of ESU — Year 1 ends **13 Oct 2026**, Year 2 ends **12 Oct 2027** and Year 3
> ends **10 Oct 2028**. WSL2 keeps working on Windows 10, but the OS itself only
> receives fixes while it is still being serviced. See the
> [ESU FAQ](https://learn.microsoft.com/en-us/lifecycle/faq/extended-security-updates).

**Windows 10 version 2004 (build 19041) and newer** — which is every currently
supported 22H2 install — use the same single command as Windows 11:

```powershell
wsl --install
```

On **older Windows 10 builds**, and on **Windows 10 LTSC / IoT Enterprise LTSC**
(which do not ship the Microsoft Store), `wsl --install` may be missing or
unable to fetch a distribution. Use the manual steps instead:

1. Search **"Turn Windows features on or off"**, enable **Windows Subsystem for
   Linux** and **Virtual Machine Platform**, and reboot. (Equivalent commands:
   `dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart`
   and the same for `VirtualMachinePlatform`.)
2. To use WSL2, install the **WSL2 Linux kernel update package** from
   <https://aka.ms/wsl2kernel> and reboot (`wsl --update` also works once WSL is
   present).
3. Install a distribution. Without the Store, download the distro bundle from
   <https://aka.ms/wslstore>, rename the `.AppxBundle`/`.Appx` file to `.zip`,
   extract it and run the included `ubuntu.exe` (or `debian.exe`, …). Then run
   `wsl --set-default-version 2`.

#### Step 2 — Run Mido

Inside the WSL shell, download Mido and run it exactly like on Linux:

```sh
curl -O https://raw.githubusercontent.com/BENDER35/Mido_2026/main/Mido.sh
chmod +x Mido.sh
./Mido.sh win11x64
```

Files land in the current WSL directory; use `/mnt/c/Users/<you>/Downloads` if
you want them on the Windows drive.

#### Windows Server

WSL is supported on **Windows Server 2019 and newer**. The Server releases map
to the desktop versions as follows:

| Desktop | Server equivalent | WSL support |
|---|---|---|
| Windows 10 1809 | Windows Server 2019 | **WSL 1 only** (build 17763 < 18362); no `wsl --install`, enable the feature manually |
| Windows 11 21H2 / 22H2 | Windows Server 2022 | WSL 1 & 2 — `wsl --install` |
| Windows 11 24H2 | Windows Server 2025 | WSL 1 & 2, including Server Core — `wsl --install` |

- **Windows Server 2022 / 2025:** in an **administrator** PowerShell run
  `wsl --install`, then reboot. The Microsoft Store is not available on Server,
  so `wsl --install` (or `wsl --install -d <Distro>`) downloads the distribution
  directly.
- **Windows Server 2019 (and Server Core):** run
  `Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux, VirtualMachinePlatform`
  in an administrator PowerShell, reboot, then install a distribution manually
  (the `aka.ms/wslstore` bundles). WSL2 needs build 18362+, so Server 2019 is
  limited to **WSL 1**.

#### Windows Native Wrappers

Mido includes native Windows wrappers for convenience:

- **`Mido.bat`** - Batch file wrapper (run by double-clicking or from cmd)
- **`Mido.ps1`** - PowerShell wrapper (run from PowerShell)

Both wrappers automatically detect WSL and run `Mido.sh` through it, passing all arguments. Example usage:

```
Mido.bat win11x64
Mido.ps1 win10x64 win11x64
```

If WSL is not installed, the wrappers will prompt you to install it.

## Usage

```
./Mido.sh <windows_media>...
```

Examples:

```
./Mido.sh win11x64                       # Windows 11, English (US)
MIDO_LANG=es-ES ./Mido.sh win10x64       # Windows 10, Spanish (Spain)
MIDO_LANG=es-MX ./Mido.sh win11x64       # Windows 11, Mexican Spanish
./Mido.sh win7x64-ultimate win10x64      # Multiple ISOs in one command
./Mido.sh all                            # Every supported media
```

### Available media

| Argument | Description |
|---|---|
| `vista-x64-sp1` | Windows Vista SP1 x64 (English, sourced from archive.org) |
| `vista-x86-sp1` | Windows Vista SP1 x86 (English, sourced from archive.org) |
| `vista-es-x64-sp1` | Windows Vista SP1 x64 Spanish (sourced from archive.org) |
| `vista-es-x86-sp1` | Windows Vista SP1 x86 Spanish (sourced from archive.org) |
| `vista-x64-sp2` | Windows Vista **Enterprise** SP2 x64 (English, sourced from archive.org) |
| `vista-x86-sp2` | Windows Vista **Enterprise** SP2 x86 (English, sourced from archive.org) |
| `vista-es-x64-sp2` | Windows Vista **Enterprise** SP2 x64 Spanish (sourced from archive.org) |
| `vista-es-x86-sp2` | Windows Vista **Enterprise** SP2 x86 Spanish (sourced from archive.org) |
| `vista-x64-sp2-n` | Windows Vista N SP2 x64 (Home Basic N + Business N, English, sourced from archive.org) |
| `vista-x64-sp2-business-n` | Windows Vista Business N SP2 x64 (English, sourced from archive.org) |
| `vista-x86-sp2-business-n` | Windows Vista Business N SP2 x86 (English, sourced from archive.org) |
| `win7x64-ultimate` | Windows 7 Ultimate x64 (sourced from the Wayback Machine) |
| `win7x64-ultimate-esp` | Windows 7 Ultimate x64 Spanish — Microsoft official first, archive.org fallback |
| `win7x86-ultimate` | Windows 7 Ultimate x86 (32-bit, sourced from archive.org) |
| `win7x86-ultimate-esp` | Windows 7 Ultimate x86 Spanish (32-bit) — Microsoft official first, archive.org fallback |
| `win81x64` | Windows 8.1 x64 (**retired by Microsoft**, use the Enterprise Eval) |
| `win81x64-ent-32-espa` | Windows 8.1 Enterprise 32-bit Spanish (sourced from archive.org) |
| `win81x64-ent-64-esp` | Windows 8.1 Enterprise 64-bit Spanish (sourced from archive.org) |
| `win10x64` | Windows 10 x64 (multi-edition) |
| `win10x64-esp` | Windows 10 x64 Spanish (Spain) — Microsoft official first, archive.org fallback |
| `win10x64-es-mx` | Windows 10 x64 Spanish (Mexico) — Microsoft official first, archive.org fallback |
| `win10x86` | Windows 10 x86 (32-bit, multi-edition) — Microsoft official first, archive.org fallback |
| `win10x86-esp` | Windows 10 x86 (32-bit) Spanish (Spain) — Microsoft official first, archive.org fallback |
| `win10x86-es-mx` | Windows 10 x86 (32-bit) Mexican Spanish — Microsoft official first, archive.org fallback |
| `win11x64` | Windows 11 x64 (multi-edition) |
| `win11x64-esp` | Windows 11 x64 Spanish (Spain) — Microsoft official first, archive.org fallback |
| `win11x64-es-mx` | Windows 11 x64 Spanish (Mexico) — Microsoft official first, archive.org fallback |
| `win81x64-enterprise-eval` | Windows 8.1 Enterprise Evaluation |
| `win81x64` | Windows 8.1 x64 (**retired by Microsoft**, use the Enterprise Eval) |
| `win81x86` | Windows 8.1 x86 (32-bit, archive.org) |
| `win81x64-ent-32-espa` | Windows 8.1 Enterprise 32-bit Spanish (sourced from archive.org) |
| `win81x64-ent-64-esp` | Windows 8.1 Enterprise 64-bit Spanish (sourced from archive.org) |
| `win10x64-enterprise-eval` | Windows 10 Enterprise Evaluation |
| `win10x86-enterprise-eval` | Windows 10 Enterprise 32-bit Evaluation (LTSC 21H2 x86, sourced from archive.org) |
| `win11x64-enterprise-eval` | Windows 11 Enterprise Evaluation |
| `win10x64-enterprise-ltsc-eval` | Windows 10 Enterprise LTSC Evaluation (most secure) |
| `win11x64-enterprise-ltsc-eval` | Windows 11 Enterprise LTSC Evaluation (most secure) |
| `win11x64-iot-enterprise-ltsc-eval` | Windows 11 IoT Enterprise LTSC Evaluation |
| `win11x64-iot-enterprise-26h2` | Windows 11 IoT Enterprise 26H2 (annual channel, English, sourced from archive.org) |
| `win11x64-iot-enterprise-ltsc-2024` | Windows 11 IoT Enterprise LTSC 2024 (full, English, x64, sourced from archive.org) |
| `win10x64-iot-enterprise-22h2` | Windows 10 IoT Enterprise 22H2 (annual channel, English, x64, sourced from archive.org) |
| `win10x64-iot-enterprise-ltsc-2021` | Windows 10 IoT Enterprise LTSC 2021 (full, English, x64, sourced from archive.org) |
| `win10x64-iot-enterprise-ltsc-2019` | Windows 10 IoT Enterprise LTSC 2019 (full, English, x64, sourced from archive.org) |
| `win10x86-iot-enterprise-ltsc-2019` | Windows 10 IoT Enterprise LTSC 2019 (full, English, x86/32-bit, sourced from archive.org) |
| `win81-serial` | Windows 8.1 setup serial keys (for installation, not activation) |
| `win11x64-enterprise-ltsc-2024` | Windows 11 Enterprise LTSC 2024 (full, English, x64, sourced from archive.org) |
| `win11x64-enterprise-ltsc-2024-esp` | Windows 11 Enterprise LTSC 2024 (full, Spanish (Spain), x64, sourced from archive.org) |
| `win11x64-enterprise-ltsc-2024-es-mx` | Windows 11 Enterprise LTSC 2024 (full, Mexican Spanish, x64, sourced from archive.org) |
| `win10x64-enterprise-ltsc-2021` | Windows 10 Enterprise LTSC 2021 (full, English, x64, sourced from archive.org) |
| `win10x64-enterprise-ltsc-2021-esp` | Windows 10 Enterprise LTSC 2021 (full, Spanish (Spain), x64, sourced from archive.org) |
| `win10x64-enterprise-ltsc-2021-es-mx` | Windows 10 Enterprise LTSC 2021 (full, Mexican Spanish, x64, sourced from archive.org) |
| `win10x86-enterprise-ltsc-2021` | Windows 10 Enterprise LTSC 2021 (full, English, x86/32-bit, sourced from archive.org) |
| `win10x86-enterprise-ltsc-2021-esp` | Windows 10 Enterprise LTSC 2021 (full, Spanish (Spain), x86/32-bit, sourced from archive.org) |
| `win10x86-enterprise-ltsc-2021-es-mx` | Windows 10 Enterprise LTSC 2021 (full, Mexican Spanish, x86/32-bit, sourced from archive.org) |
| `win10x64-enterprise-ltsb-2016` | Windows 10 Enterprise LTSB 2016 (full, English, x64, sourced from archive.org) |
| `win10x64-enterprise-ltsb-2016-esp` | Windows 10 Enterprise LTSB 2016 (full, Spanish, x64, sourced from archive.org) |
| `win10x86-enterprise-ltsb-2016` | Windows 10 Enterprise LTSB 2016 (full, English, x86/32-bit, sourced from archive.org) |
| `win10x86-enterprise-ltsb-2016-esp` | Windows 10 Enterprise LTSB 2016 (full, Spanish, x86/32-bit, sourced from archive.org) |
| `win10x64-enterprise-ltsb-2015` | Windows 10 Enterprise LTSB 2015 (full, English, x64, sourced from archive.org) |
| `win10x64-enterprise-ltsb-2015-esp` | Windows 10 Enterprise LTSB 2015 (full, Spanish, x64, sourced from archive.org) |
| `win10x86-enterprise-ltsb-2015` | Windows 10 Enterprise LTSB 2015 (full, English, x86/32-bit, sourced from archive.org) |
| `win10x86-enterprise-ltsb-2015-esp` | Windows 10 Enterprise LTSB 2015 (full, Spanish, x86/32-bit, sourced from archive.org) |
| `win2008r2` | Windows Server 2008 R2 SP1 (x64, English) |
| `win2008r2-espa` | Windows Server 2008 R2 SP1 (x64, Spanish eval, sourced from archive.org) |
| `win2008-server-x64` | Windows Server 2008 SP2 (x64, English, all editions, sourced from archive.org) |
| `win2008-server-x64-espa` | Windows Server 2008 SP2 (x64, Spanish, all editions, sourced from archive.org) |
| `win2008-server-x86` | Windows Server 2008 SP2 (x86, English, all editions, sourced from archive.org) |
| `win2008-server-x86-espa` | Windows Server 2008 SP2 (x86, Spanish, all editions, sourced from archive.org) |
| `win2000-pro` | Windows 2000 Professional SP4 (English, sourced from archive.org) |
| `win2000-pro-espa` | Windows 2000 Professional SP4 Spanish (sourced from archive.org) |
| `win2000-pro-oem` | Windows 2000 Professional SP3 OEM (English, sourced from archive.org) |
| `win2000-pro-retail` | Windows 2000 Professional SP4 Retail (English, sourced from archive.org) |
| `win2000-pro-oem-espa` | Windows 2000 Professional SP1 OEM Spanish (sourced from archive.org) |
| `win2000-pro-retail-espa` | Windows 2000 Professional RTM Retail Spanish (sourced from archive.org) |
| `win-xp-pro` | Windows XP Professional SP3 (English, sourced from archive.org) |
| `win-xp-pro-espa` | Windows XP Professional SP3 Spanish (sourced from archive.org) |
| `win-xp-pro-32` | Windows XP Professional x86 (32-bit, sourced from archive.org) |
| `win-xp-pro-32-espa` | Windows XP Professional x86 SP3 Spanish (32-bit, sourced from archive.org) |
| `win-xp-pro-64` | Windows XP Professional x64 SP2 (64-bit, English, sourced from archive.org) |
| `win-xp-home` | Windows XP Home Edition SP3 (English, sourced from archive.org) |
| `win-xp-home-espa` | Windows XP Home Edition SP3 Spanish (sourced from archive.org) |
| `win-xp-home-oem` | Windows XP Home Edition RTM OEM (English, sourced from archive.org) |
| `win-xp-home-retail` | Windows XP Home Edition SP3 Retail (English, sourced from archive.org) |
| `win-xp-home-oem-espa` | Windows XP Home Edition SP2 OEM Spanish (sourced from archive.org) |
| `win-xp-home-retail-espa` | Windows XP Home Edition SP3 Retail Spanish (sourced from archive.org) |
| `win-xp-pro-oem` | Windows XP Professional SP2 OEM (English, sourced from archive.org) |
| `win-xp-pro-retail` | Windows XP Professional SP3 Retail (English, sourced from archive.org) |
| `win-xp-pro-oem-espa` | Windows XP Professional SP2 OEM Spanish (sourced from archive.org) |
| `win-xp-pro-retail-espa` | Windows XP Professional SP1 Retail Spanish (sourced from archive.org) |
| `win7x64-pro` | Windows 7 Professional x64 (sourced from archive.org) |
| `win7x64-pro-esp` | Windows 7 Professional x64 Spanish — Microsoft official first, archive.org fallback |
| `win7x86-pro` | Windows 7 Professional x86 (32-bit, sourced from archive.org) |
| `win7x86-pro-esp` | Windows 7 Professional x86 Spanish (32-bit) — Microsoft official first, archive.org fallback |
| `win7x64-homepremium` | Windows 7 Home Premium x64 (sourced from archive.org) |
| `win7x64-homepremium-esp` | Windows 7 Home Premium x64 Spanish — Microsoft official first, archive.org fallback |
| `win7x86-homepremium` | Windows 7 Home Premium x86 (32-bit, sourced from archive.org) |
| `win7x86-homepremium-esp` | Windows 7 Home Premium x86 Spanish (32-bit) — Microsoft official first, archive.org fallback |
| `win7x64-enterprise` | Windows 7 Enterprise x64 (sourced from archive.org) |
| `win7x64-enterprise-esp` | Windows 7 Enterprise x64 Spanish — Microsoft official first, archive.org fallback |
| `win7x86-enterprise` | Windows 7 Enterprise x86 (32-bit, sourced from archive.org) |
| `win7x86-enterprise-esp` | Windows 7 Enterprise x86 Spanish (32-bit) — Microsoft official first, archive.org fallback |
| `win7x64-sp1` | Windows 7 SP1 x64 (sourced from archive.org) |
| `win7x86-sp1` | Windows 7 SP1 x86 (32-bit, sourced from archive.org) |
| `win81x64-pro` | Windows 8.1 Pro x64 — Microsoft retired automation, use archive.org |
| `win81x64-pro-esp` | Windows 8.1 Pro Spanish (Spain) — Microsoft official first, archive.org fallback |
| `win81x86-pro` | Windows 8.1 Pro x86 (32-bit, sourced from archive.org) |
| `win81x86-pro-esp` | Windows 8.1 Pro x86 Spanish (32-bit) — Microsoft official first, archive.org fallback |
| `win2003-server` | Windows Server 2003 Enterprise (x86, English, sourced from archive.org) |
| `win2003-server-espa` | Windows Server 2003 Enterprise (x86, Spanish, sourced from archive.org) |
| `win2003-server-x64` | Windows Server 2003 R2 Enterprise x64 SP2 (English, sourced from archive.org) |
| `win2003-server-x64-espa` | Windows Server 2003 R2 Enterprise x64 SP2 (Spanish, sourced from archive.org) |
| `win2012r2-eval` | Windows Server 2012 R2 Evaluation (sourced from archive.org, updated ISO) |
| `win2016-essentials` | Windows Server 2016 Essentials x64 English (sourced from archive.org) |
| `win2019-iso` | Windows Server 2019 x64 English (full ISO, sourced from archive.org) |
| `win2000-server` | Windows 2000 Server SP4 (English, sourced from archive.org) |
| `win2000-server-espa` | Windows 2000 Server SP4 (Spanish, sourced from archive.org) |
| `win2000-advanced-server` | Windows 2000 Advanced Server SP1 (English, sourced from archive.org) |
| `win2000-advanced-server-espa` | Windows 2000 Advanced Server SP1 (Spanish, sourced from archive.org) |
| `win2000-datacenter` | Windows 2000 Datacenter Server RTM OEM (SP1, English, sourced from archive.org) |
| `win2000-datacenter-sp4` | Windows 2000 Datacenter Server SP4 (English, sourced from archive.org) |
| `win2012r2-eval` | Windows Server 2012 R2 Evaluation |
| `win2016-eval` | Windows Server 2016 Evaluation |
| `win2019-eval` | Windows Server 2019 Evaluation |
| `win2022-eval` | Windows Server 2022 Evaluation |
| `win2025-eval` | Windows Server 2025 Evaluation |
| `win2025-enterprise-64` | Windows Server 2025 Enterprise x64 (64-bit) |
| `win2025-enterprise-64-esp` | Windows Server 2025 Enterprise x64 Spanish (64-bit) |
| `win2025-datacenter-64` | Windows Server 2025 Datacenter x64 (64-bit) |
| `win2025-datacenter-64-esp` | Windows Server 2025 Datacenter x64 Spanish (64-bit) |
| `win2022-eval` | Windows Server 2022 Evaluation |
| `win2022-enterprise-64` | Windows Server 2022 Enterprise x64 (64-bit) |
| `win2022-enterprise-64-esp` | Windows Server 2022 Enterprise x64 Spanish (64-bit) |
| `win2022-datacenter-64` | Windows Server 2022 Datacenter x64 (64-bit) |
| `win2022-datacenter-64-esp` | Windows Server 2022 Datacenter x64 Spanish (64-bit) |
| `win2012r2-essentials-eval` | Windows Server 2012 R2 Essentials Evaluation |
| `win2016-essentials-eval` | Windows Server 2016 Essentials Evaluation |
| `win2019-essentials-eval` | Windows Server 2019 Essentials Evaluation |
| `hyperv2012-eval` | Hyper-V Server 2012 Evaluation |
| `hyperv2012r2-eval` | Hyper-V Server 2012 R2 Evaluation |
| `hyperv2016-eval` | Hyper-V Server 2016 Evaluation |
| `hyperv2019-eval` | Hyper-V Server 2019 Evaluation |
| `win30` | Windows 3.0 (English, sourced from archive.org; ZIP of the original diskettes) |
| `win30-espa` | Windows 3.0a Spanish (sourced from archive.org; ZIP) |
| `win31` | Windows 3.1 (English, sourced from archive.org) |
| `win31-espa` | Windows 3.1 Spanish (sourced from archive.org) |
| `wfw31` | Windows for Workgroups 3.1 (English, build 014e, sourced from archive.org; RAR of the original diskettes) |
| `wfw31-espa` | Windows for Workgroups 3.1 Spanish (sourced from archive.org; 7z diskette images) |
| `win311` | Windows 3.11 / Windows for Workgroups 3.11 (English, sourced from archive.org) |
| `win311-espa` | Windows 3.11 Spanish (sourced from archive.org) |
| `wfw311` | Windows for Workgroups 3.11 (English, same media as `win311`, sourced from archive.org) |
| `wfw311-espa` | Windows for Workgroups 3.11 Spanish (sourced from archive.org) |
| `win95` | Windows 95 (English, sourced from archive.org) |
| `win95-espa` | Windows 95 Spanish (sourced from archive.org) |
| `win98` | Windows 98 Second Edition (English, sourced from archive.org) |
| `win98-espa` | Windows 98 Second Edition Spanish (sourced from archive.org) |
| `winme` | Windows Millennium Edition (English, sourced from archive.org) |
| `winme-espa` | Windows Millennium Edition Spanish (sourced from archive.org) |
| `winnt31` | Windows NT 3.1 Workstation (English, sourced from archive.org) |
| `winnt35` | Windows NT 3.5 Workstation (English, sourced from archive.org) |
| `winnt351` | Windows NT 3.51 Workstation (English, sourced from archive.org) |
| `winnt40` | Windows NT 4.0 Workstation (English, sourced from archive.org) |
| `backoffice` | Microsoft BackOffice Small Business Server 4.0 (x86, sourced from archive.org) |
| `winframe` | Citrix WinFrame 1.6 (Windows NT 3.51 Terminal Server Edition, sourced from archive.org) |

## Language support

Set the `MIDO_LANG` environment variable to one of:

| Value | Language |
|---|---|
| `en-US` | English (United States) — default |
| `es-ES` | Spanish (Spain) |
| `es-MX` | Spanish (Mexico) |

Spanish ISOs are available for the **consumer** versions (`win10x64`, `win11x64`).
Besides `MIDO_LANG`, dedicated arguments exist for Spanish (Spain) and Mexican
Spanish: `win10x64-esp`, `win10x64-es-mx`, `win11x64-esp` and `win11x64-es-mx`.
These try Microsoft's official download first and, if the request is rejected
(for example by the Sentinel anti-abuse system), fall back to an identical
archive.org copy. Additionally, Windows 10 32-bit (x86) ISOs are available via archive.org
for English (`win10x86`), Spain (`win10x86-esp`) and Mexico (`win10x86-es-mx`).
Windows 8.1 Enterprise Spanish ISOs are also available via archive.org for both
32-bit (`win81x64-ent-32-espa`) and 64-bit (`win81x64-ent-64-esp`).
A Spanish Windows Server 2008 R2 SP1 evaluation ISO is available via archive.org
(`win2008r2-espa`). Windows Server 2008 (non-R2) SP2 is available via archive.org
in both English and Spanish, for 64-bit (`win2008-server-x64`,
`win2008-server-x64-espa`) and 32-bit (`win2008-server-x86`,
`win2008-server-x86-espa`). Windows Server 2003 Enterprise and Windows 2000 Server SP4 are
also available in both English and Spanish via archive.org
(`win2003-server`, `win2003-server-espa`, `win2000-server`, `win2000-server-espa`).
64-bit Server 2003 R2 Enterprise x64 SP2 is available in English
(`win2003-server-x64`) and Spanish (`win2003-server-x64-espa`).
Windows Vista SP1 ISOs in Spanish are also available via archive.org
(`vista-es-x64-sp1`, `vista-es-x86-sp1`).
Windows Vista **Enterprise** SP2 ISOs in Spanish are also available via archive.org
(`vista-es-x64-sp2`, `vista-es-x86-sp2`).
The Windows Vista **N** media (which satisfies the EU ruling and excludes the
bundled media software) is available in English: the N all-in-one x64 DVD with
Home Basic N and Business N (`vista-x64-sp2-n`) and the Business N x64 and x86
ISOs (`vista-x64-sp2-business-n`, `vista-x86-sp2-business-n`). Note that
**Windows Vista Enterprise N** was never released as standalone MSDN media (the
"N" DVD only ships Home Basic N and Business N), and no Spanish Vista N ISOs are
available on archive.org, so no `-es`/`-es-mx` N arguments are offered.
Windows 7 SP1 ISOs are also available in English (`win7x64-sp1`, `win7x86-sp1`)
via archive.org. Windows 7 Ultimate Spanish media is available via Microsoft
official first, then archive.org fallback (`win7x64-ultimate-esp`), and genuine
Spanish SP1 ISOs are archived for every SKU (`win7x64-ultimate-esp`,
`win7x86-ultimate-esp`, `win7x64-pro-esp`, `win7x86-pro-esp`,
`win7x64-homepremium-esp`, `win7x86-homepremium-esp`, `win7x64-enterprise-esp`,
`win7x86-enterprise-esp`).
Windows 2000 Professional, Windows XP Professional, Windows XP Home Edition and
Windows 7 Professional Spanish ISOs are also available via archive.org. Windows 8.1 Pro Spanish ISOs
are also available via archive.org for Spain (`win81x64-pro-esp`). Enterprise, Server and Evaluation media are otherwise
English-only, as published by Microsoft. Non-English ISOs are written with a locale
suffix (e.g. `win11x64.es-MX.iso`) or a `-espa`/`-esp`/`-es-mexico` filename as
appropriate, so they never overwrite the English ones. Because Microsoft does not
publish public checksums for every localized release, localized ISOs may report
`NO KNOWN CHECKSUM (skipping verification)`.

Windows 2000 Professional and Windows XP are additionally available in the
original **OEM** and **Retail** (FPP) license channels, in English and Spanish:
`win2000-pro-oem`, `win2000-pro-retail`, `win2000-pro-oem-espa`,
`win2000-pro-retail-espa`, `win-xp-home-oem`, `win-xp-home-retail`,
`win-xp-home-oem-espa`, `win-xp-home-retail-espa`, `win-xp-pro-oem`,
`win-xp-pro-retail`, `win-xp-pro-oem-espa` and `win-xp-pro-retail-espa`.
Windows XP Home Edition and Windows XP Professional are available in English and
Spanish (`win-xp-home`, `win-xp-home-espa`, `win-xp-pro`, `win-xp-pro-espa`,
`win-xp-pro-32-espa`).

> **Note on Mexican Spanish availability:** Microsoft only localized Windows to a
> separate Mexican Spanish (`es-MX`) build starting with **Windows 10**. Earlier
> releases (Windows 3.x, 95, 98, Me, NT, 2000, XP, Vista, Windows 7 and Windows
> 8/8.1) were published with a **single Spanish build** (`es-ES`) that serves all
> Spanish-speaking regions, so no `-es-mx` arguments are offered for them. The
> genuine `-es-mx` arguments (and `MIDO_LANG=es-MX`) therefore exist only for
> Windows 10, Windows 11 and their Enterprise LTSC editions, for which Microsoft
> actually published separate Spanish (Mexico) media. The former Windows 7 and
> Windows 8.1 `-es-mx` arguments were removed because the archive.org mirrors of
> those (never-official) builds went dark.

The retro releases (`win30`, `win31`, `wfw31`, `win311`/`wfw311`, `win95`,
`win98`, `winme`, `winnt31`, `winnt35`, `winnt351`, `winnt40`, `backoffice`,
`winframe`) are sourced from `archive.org` and have no published checksums.
Windows 3.x, Windows 95, Windows 98 Second Edition and Windows Millennium
Edition are also available in Spanish (`win30-espa`, `win31-espa`,
`wfw31-espa`, `win311-espa`, `wfw311-espa`, `win95-espa`, `win98-espa`,
`winme-espa`); the remaining retro releases are English-only. Note that
`win311` and `wfw311` refer to the same product (Windows 3.11 for Workgroups)
and share the same English media; the Spanish releases distinguish a
"Windows 3.11" media (`win311-espa`) from a "Windows 3.11 para Trabajo en
Grupo" media (`wfw311-espa`). Because Microsoft never localized these versions
to Mexican Spanish, no `-es-mx` arguments exist for them.

## How does Mido work?

It interacts with Microsoft's proprietary downloading API to grab the latest
release of Windows and generate a fresh download link (valid for 24 hours). Then
it downloads the file, verifies its SHA-256 checksum and resumes partial
downloads automatically.

In detail:

1. Scrapes the official download page to obtain the *product edition ID* for the
   requested release.
2. Whitelists a random *session ID* and completes Microsoft's *Sentinel*
   anti-abuse handshake.
3. Queries the JSON API for the *SKU ID* matching the requested language.
4. Requests a fresh download link and downloads it to `<file>.PART`.
5. Verifies the SHA-256 checksum and renames the file to either `<file>` (OK) or
   `<file>.UNVERIFIED` (needs manual review).

See [docs/TECHNICAL.md](docs/TECHNICAL.md) for a full walk-through.

## What else can Mido do?

Other than the consumer versions of Windows like 11 and 10, it can also automatically download the latest Server (e.g. Windows Server 2025) and Enterprise editions of every Windows version all the way back to Windows 7 (or Windows Server 2008 R2, and even Server 2003 and 2000 Server). Retro releases all the way back to the early 1990s are included too: Windows 3.0, Windows 3.1, Windows for Workgroups 3.1, Windows 3.11 for Workgroups, Windows 95, Windows 98 Second Edition, Windows Millennium Edition, Windows NT 3.1, 3.5 and 3.51 Workstation and Windows NT 4.0 Workstation (`win30`, `win31`, `wfw31`, `win311`/`wfw311`, `win95`, `win98`, `winme`, `winnt31`, `winnt35`, `winnt351`, `winnt40`, sourced from archive.org). It also offers the Windows NT 3.51-era server products Microsoft BackOffice Small Business Server 4.0 (`backoffice`) and Citrix WinFrame 1.6 (Windows NT 3.51 Terminal Server Edition, `winframe`). Windows 3.x, Windows 95, 98 and Millennium Edition also have Spanish media (`win30-espa`, `win31-espa`, `wfw31-espa`, `win311-espa`, `wfw311-espa`, `win95-espa`, `win98-espa`, `winme-espa`), and Windows 2000 Professional / Windows XP come in the original OEM and Retail license channels (see the media table above).

Want a more secure and minimalist Windows installation out-of-the-box that's officially provided by Microsoft? Then download the LTSC version of Windows. It comes with way less bloat and supports Microsoft's ["Security"](https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization#diagnostic-data-settings) telemetry mode (plus it comes with long-term support).

### IoT Enterprise editions

Windows **IoT Enterprise** is the edition Microsoft ships for dedicated devices
(ATMs, kiosks, digital signage, medical equipment, thin clients). It is the same
OS as Enterprise but with **relaxed hardware requirements** — TPM, Secure Boot,
UEFI and 4 GB RAM are *not* required — and, for the LTSC releases, up to **10
years** of security updates. Mido offers the full (non-evaluation) English ISOs:

| Argument | Product | Architecture | Support ends |
|---|---|---|---|
| `win11x64-iot-enterprise-ltsc-2024` | Windows 11 IoT Enterprise LTSC 2024 | x64 | Oct 2034 |
| `win11x64-iot-enterprise-26h2` | Windows 11 IoT Enterprise 26H2 (annual channel) | x64 | per annual channel |
| `win10x64-iot-enterprise-22h2` | Windows 10 IoT Enterprise 22H2 (annual channel) | x64 | Windows 10 ESU |
| `win10x64-iot-enterprise-ltsc-2021` | Windows 10 IoT Enterprise LTSC 2021 | x64 | 2032-01-13 |
| `win10x64-iot-enterprise-ltsc-2019` | Windows 10 IoT Enterprise LTSC 2019 | x64 | 2029-01-09 |
| `win10x86-iot-enterprise-ltsc-2019` | Windows 10 IoT Enterprise LTSC 2019 | x86 (32-bit) | 2029-01-09 |

> **On 32-bit availability:** Microsoft only ever published an x86 (32-bit) ISO
> for the **IoT Enterprise LTSC 2019** release. The annual-channel Windows 10
> IoT Enterprise 22H2 and the newer IoT Enterprise LTSC 2021 exist **only as
> x64** (and arm64), so there is no 32-bit ISO for them.

## Windows 8.1 setup serial keys

The following setup keys can be used during Windows 8.1 installation to proceed
past the setup screen, but **do not activate Windows**:

- **Windows 8.1 Enterprise (x64):** `NF3MJ-Q9W3X-7Y9K3-RJR8C-3X3CQ`
- **Windows 8.1 Enterprise (x86 32-bit):** `KJYVW-2R2YX-2V9Y2-T8YV3-WRHYD`
- **Windows 8.1 Pro (x64):** `GCRJD-8NW9H-F2HCX-Y66R6-C8BMC`
- **Windows 8.1 Pro (x86 32-bit):** `W83YN-4R2Y3-2FWY4-T92JY-W3YXK`
- **Windows 8.1 N (x64):** `MWMSY-FVGGT-6X7JK-PPMRW-TRT0D`
- **Windows 8.1 N (x86 32-bit):** `VBN20-8R2YX-7WJ4C-YJJ26-G3YXK`

> **Important:** These are volume license / setup keys that allow installation
> to complete. They do **not** provide a licensed, activated copy of Windows.
> For activation, you must use a genuine product key or digital license.

### Windows Embedded setup serial keys

The following setup keys can be used during installation of the Windows Embedded
editions to proceed past the setup screen, but **do not activate Windows**:

**Windows Embedded 8.1 Industry**

- **Windows Embedded 8.1 Industry Pro:** `NMMPB-38DD4-R2823-62W8D-VXKJB`
- **Windows Embedded 8.1 Industry Enterprise:** `FNFKF-PWTVT-9RC8H-32HB2-JB34X`
- **Windows Embedded 8.1 Industry (180-day evaluation ISO):** `N3QJR-YCWKK-RVJGK-GQFMX-T82BF`

**Windows Embedded 8 Industry**

- **Windows Embedded 8 Industry Professional:** `RYXVT-BNQG7-VD29F-DBMRY-HT73M`
- **Windows Embedded 8 Industry Enterprise:** `NKB3R-R2F8T-3XCDP-7Q2KW-XWYQ2`

**Windows Embedded 8 Standard**

- **Windows Embedded 8 Standard runtime image (180-day evaluation key):** `MPVW4-JNF4W-MGM8P-G2WYY-CWDFY`
- **Windows Embedded 8 Standard toolkit — Image Configuration Editor (also licenses the toolkit in perpetuity):** `D9XDH-78JX9-2KJG8-K7CY9-KF2Q3`

> **Note:** Microsoft never defined a KMS client setup key (GVLK) for Windows
> Embedded 8 Standard, so the evaluation and toolkit keys above are provided
> instead. All of these keys only allow setup to continue; they do **not**
> activate Windows. For activation, use a genuine product key.

### Enterprise LTSC & LTSB editions

Mido also offers the full (non-evaluation) **Enterprise** long-term-servicing
ISOs, in English and Spanish (Spain and Mexico where Microsoft published them).
These are the same LTSC/LTSB editions as the "Evaluation" downloads above, but
with the normal (non-expiring) licence:

| Argument | Product | Architecture | Support ends |
|---|---|---|---|
| `win11x64-enterprise-ltsc-2024` | Windows 11 Enterprise LTSC 2024 | x64 | 2029-10-09 |
| `win11x64-enterprise-ltsc-2024-esp` / `-es-mx` | Windows 11 Enterprise LTSC 2024 (es-ES / es-MX) | x64 | 2029-10-09 |
| `win10x64-enterprise-ltsc-2021` | Windows 10 Enterprise LTSC 2021 | x64 | 2027-01-12 |
| `win10x64-enterprise-ltsc-2021-esp` / `-es-mx` | Windows 10 Enterprise LTSC 2021 (es-ES / es-MX) | x64 | 2027-01-12 |
| `win10x86-enterprise-ltsc-2021` | Windows 10 Enterprise LTSC 2021 | x86 (32-bit) | 2027-01-12 |
| `win10x86-enterprise-ltsc-2021-esp` / `-es-mx` | Windows 10 Enterprise LTSC 2021 (es-ES / es-MX) | x86 (32-bit) | 2027-01-12 |
| `win10x64-enterprise-ltsb-2016` | Windows 10 Enterprise LTSB 2016 (= "LTSC 2016") | x64 | 2026-10-13 |
| `win10x64-enterprise-ltsb-2016-esp` | Windows 10 Enterprise LTSB 2016 (Spanish) | x64 | 2026-10-13 |
| `win10x86-enterprise-ltsb-2016` | Windows 10 Enterprise LTSB 2016 (= "LTSC 2016") | x86 (32-bit) | 2026-10-13 |
| `win10x86-enterprise-ltsb-2016-esp` | Windows 10 Enterprise LTSB 2016 (Spanish) | x86 (32-bit) | 2026-10-13 |
| `win10x64-enterprise-ltsb-2015` | Windows 10 Enterprise LTSB 2015 | x64 | ended 2025-10-14 |
| `win10x64-enterprise-ltsb-2015-esp` | Windows 10 Enterprise LTSB 2015 (Spanish) | x64 | ended 2025-10-14 |
| `win10x86-enterprise-ltsb-2015` | Windows 10 Enterprise LTSB 2015 | x86 (32-bit) | ended 2025-10-14 |
| `win10x86-enterprise-ltsb-2015-esp` | Windows 10 Enterprise LTSB 2015 (Spanish) | x86 (32-bit) | ended 2025-10-14 |

> **"LTSC 2016" and "LTSB 2016" are the same product.** Microsoft used the name
> **LTSB** (Long-Term Servicing *Branch*) for the 2015 and 2016 releases and
> renamed it to **LTSC** (Long-Term Servicing *Channel*) with the 2019 release,
> so the 2016 ISO is listed under either name — there was never a separate
> "Windows 10 LTSC 2016".
>
> **On 32-bit availability:** every Windows 10 LTSC/LTSB release above ships both
> x86 (32-bit) and x64 ISOs. Windows 11 (including Enterprise LTSC 2024) is
> **x64/arm64 only** — there is no 32-bit build. Spanish Windows 11 Enterprise
> LTSC 2024 exists as es-ES and es-MX, but the Windows 10 LTSB 2015/2016 ISOs
> only ever had a single Spanish build (es-ES), so no `-es-mx` argument is offered
> for them.
>
> **IoT vs. Enterprise:** the `-iot-` arguments are the IoT Enterprise editions
> (relaxed hardware requirements); the ones above are the regular Enterprise
> editions. For the 2021 LTSC the IoT variant is supported until 2032-01-13 while
> the regular Enterprise variant ends 2027-01-12.

### Maximum installable Office version

Microsoft Office has its own, much stricter operating-system requirements than
Windows itself. The table below shows the **newest Office release that officially
supports each Windows version** — installing anything newer is either blocked by
the Office installer or left unsupported:

| Windows release | Newest supported Office | Notes |
|---|---|---|
| Windows 95 | **Office 2000** | Office 2000 requires Windows 95 or later. |
| Windows 98 / Me / NT 4.0 | **Office XP (2002)** | Office XP requires Windows 98/Me/NT 4.0 SP6a. Office 2003 needs 2000 SP3/XP. |
| Windows 2000 | **Office 2003** | Requires Windows 2000 SP3. Office 2007 needs XP SP2/Vista. |
| Windows XP | **Office 2010** | Last version to support XP SP3; Office 2013+ require Windows 7. |
| Windows Vista | **Office 2010** | Last version to support Vista SP2; Office 2013+ require Windows 7. |
| Windows 7 | **Office 2016** | Office 2019+ officially require Windows 10. Microsoft 365 Apps ran on 7 until Jan 2023. |
| Windows 8 | **Office 2013** | Office 2016 requires Windows 8.1+, so Windows 8 is skipped. |
| Windows 8.1 | **Office 2016** | Microsoft 365 Apps ran on 8.1 until Jan 2023. |
| Windows 10 LTSB 2015 | **Office 2016** | Office 2019/2021/LTSC 2024 do not support the 2015/2016 LTSB builds. |
| Windows 10 LTSB 2016 | **Office 2016** | Office 2019/2021/LTSC 2024 do not support the 2015/2016 LTSB builds. |
| Windows 10 LTSC 2019 | **Office LTSC 2024** | Also Office 2019, Office LTSC 2021 and Microsoft 365. |
| Windows 10 LTSC 2021 | **Office LTSC 2024** | Also Office 2019, Office LTSC 2021 and Microsoft 365. |
| Windows 10 (22H2, Home/Pro/Enterprise) | **Office 2024 / Microsoft 365** | Office **LTSC** 2024 is *not* supported on 22H2 — use retail **Office 2024** there. |
| Windows 11 (incl. LTSC 2024) | **Office LTSC 2024 / Office 2024 / Microsoft 365** | Any current Office release. |
| Windows Server 2016 | **Office 2016** | Server matching its client generation. |
| Windows Server 2019 | **Office 2019 / LTSC 2021** | Server 2019 is listed for Office 2019. |
| Windows Server 2022 / 2025 | **Office LTSC 2024** | Office LTSC 2024 supports Server 2022 and 2025. |

> **Architecture:** 64-bit Office first appeared with **Office 2010**;
> Office 2003 and 2007 are 32-bit only. 32-bit Office is still the recommended
> default for maximum add-in compatibility — install 64-bit Office only if you
> need it (very large Excel/PowerPoint files, >2 GB memory per app, or 4K+).
> 64-bit Office requires 64-bit Windows.
>
> **Installing newer Office than listed** is sometimes possible with tweaks
> (or an extended kernel — see below), but it is unsupported and may break parts
> of the suite.
>
> **Server editions** follow the client generation they are based on:
> Server 2008/2008 R2 (Vista/7 era) → Office 2010/2013, Server 2012/2012 R2
> (8/8.1 era) → Office 2013/2016, Server 2016 → Office 2016, Server 2019 →
> Office 2019, Server 2022/2025 → Office LTSC 2024.

## Product activation: telephone activation retired, replaced by internet activation

Windows NT 3.1, 3.5 and 3.51 (and every media in this project older than
Windows XP) have **no product activation at all**. Microsoft introduced product
activation with Windows XP and Office XP in 2001, and it was later used by
Windows Vista, 7, 8.1, 10, 11, the Windows Server line and Microsoft Office.

Microsoft has now **suppressed the old telephone-based activation system** and
**replaced it with an internet-based activation system**: the **Product
Activation Portal**. Beginning **3 December 2025** the traditional
telephone-based product activation automation was moved from telephone to
online. If you call the old activation phone number you now hear a recording
telling you to use the online portal. Offline activation is still supported —
only the way the *Confirmation ID* is obtained has changed (a web portal
instead of the automated phone system).

Steps for the new internet activation:

1. On the machine that needs activation, open the Windows activation dialog and
   choose **Activate by telephone** (or run `SLUI 04`) to display the
   **Installation ID**. The machine itself may stay offline — write the ID down.
2. From **any other device with internet access**, open the **Product
   Activation Portal**: <https://visualsupport.microsoft.com> (short link:
   `aka.ms/aoh`).
3. Complete the CAPTCHA, select **Proceed to Sign In** and sign in with a
   supported account (personal Microsoft account, work/school account, Microsoft
   Entra ID or an Azure Government tenant). The sign-in account is only for
   secure portal access and is **not** tied to the product license.
4. Choose **Activate a Microsoft product** and enter the **Installation ID**
   from step 1.
5. The portal returns a **Confirmation ID**.
6. Type the **Confirmation ID** back into the activation dialog on the offline
   machine to finish activation.

Windows 10 Pro for Workstations and Windows 10/11 Pro Education must be
activated over the internet and do not support the offline flow. Volume
customers can use the Volume Activation Management Tool (VAMT) for proxy
activation or KMS / Active Directory-based activation instead.

## NewShell ("Shell Technology Preview") for Windows NT 3.51

The retro Windows NT 3.1/3.5/3.51 desktop is the old Program Manager/File
Manager shell. In 1995 Microsoft released a shell refresh called **NewShell**
(also known as the **Shell Technology Preview**) that backports the Windows 95
Explorer shell — Taskbar, Start menu and Desktop — to **Windows NT 3.51**. It
is a beta whose only purpose was to demonstrate how the upcoming Windows NT 4.0
would look, and it is a very popular patch to give classic NT a usable desktop.

> **Important:** NewShell was produced **only for Windows NT 3.51**. It does
> **not** work on Windows NT 3.1 or on the original Windows NT 3.5 (build 807).
> An early "Chicago shell" preview did ship with the leaked Windows NT 3.5
> build 854, which is archived separately (see below).

Downloads:

- **Windows NT 3.51 NewShell / Shell Technology Preview** (both public
  releases: 26 May 1995 and the 8 August 1995 "Shell Technology Preview
  Update"): <https://winworldpc.com/product/newshell/beta>
- **Windows NT 3.5 build 854 NewShell** (early preview, complete
  `WINSRV.DLL`): <https://archive.org/details/newshell.3.50.854>
  — direct download:
  <https://archive.org/download/newshell.3.50.854/NT_854_newshell.zip>

Installation for the **Windows NT 3.51 Shell Technology Preview**:

1. Install Windows NT 3.51 Workstation (or Server) first, and it is
   recommended to apply the latest NT 3.51 service pack.
2. Download the NewShell archive and extract it (it contains the updated
   Explorer shell files).
3. Read the `readme.wri` shipped in the archive — it lists the exact copy
   commands for the specific release. In short, the update backs up the
   original shell, copies the new Explorer shell files (for example
   `shell32.dll`, `explorer.exe`, `comctl32.dll`, `shdocvw.dll`) over
   `%SystemRoot%\System32`, updates the registry and replaces Program Manager /
   File Manager with the new shell.
4. Take a snapshot or back up the system before applying it, since NewShell is
   an unsupported beta.
5. Reboot. You should get the Windows 95-style Taskbar and Start menu.

Installation for the **Windows NT 3.5 build 854 NewShell**:

1. Copy the `IDW`, `MSTOOLS` and `UI` directories from the `NEWSHELL`/`GUI`
   folder of the media into the Windows directory (usually `\WINNT35`).
2. Open Control Panel → **System** and append
   `%SystemRoot%\idw;%SystemRoot%\mstools;%SystemRoot%\ui` to the `Path`
   environment variable.
3. Reboot.

## Windows Update on unsupported Windows

Newer media is not the whole story: once Windows is installed you still have to
update it. Microsoft has progressively shut down the services older Windows
versions rely on, so a fresh installation may not be able to find updates at all.

- **Windows Vista and older (including Windows Server 2008 and older).** The
  classic **Windows Update / Microsoft Update** service is permanently shut down.
  These systems can no longer reach Microsoft's update servers on their own.
- **Windows 7 / Windows Server 2008 R2.** Microsoft's **Microsoft Update for
  "other Microsoft products"** (Office, etc.) has been closed, and even the
  Windows updates only work after a set of prerequisite updates are installed.
  The community project *Legacy Update* restores both.
- **Windows 8.1 / Windows Server 2012 R2.** Normal Windows Update still works,
  but these versions are out of support, so only the legacy tools below keep
  offering the full update list.

### Community revival projects

Because Microsoft removed the original services, the community rebuilt them:

- **Legacy Update** — <https://legacyupdate.net/> — the recommended option for
  **Windows 2000, XP, Vista, 7, 8, 8.1, 10 and 11** and the equivalent Windows
  Server releases (x86, x64, Itanium and ARM64). It proxies the modern Windows
  Update v6 protocol to Microsoft's official servers and automatically installs
  the prerequisite updates that fresh installations lack (SHA-2 code-signing
  support `KB4474419`/`KB4490628`, the servicing-stack update, and more).
- **Windows Update Restored** — <https://windowsupdaterestored.com/> — the sister
  project that revives the **original** Windows Update and Microsoft Update
  websites for **Windows 95, NT 4.0, 98, Me, 2000 and XP**. It requires
  **Internet Explorer 4.0–6.0** (IE 5.5 at 800×600 gives the classic look) and is
  designed for those older versions.

> Both projects are unofficial, community-run and not affiliated with Microsoft.
> They are the only realistic way to update these systems today. Use them on a
> machine you can afford to reinstall and keep backups. Even fully patched, these
> operating systems remain a security risk — prefer a supported OS when possible.

### Windows 7: enabling updates for "other Microsoft products"

On a fresh Windows 7 install the **"Get updates for other Microsoft products"**
(Microsoft Update) option is often missing, so Windows Update only offers
updates for Windows itself. To restore the full Microsoft Update:

1. Install the prerequisite updates first. The easiest way is to run **Legacy
   Update**, which identifies and installs everything missing. Manually you need
   `KB4474419` (SHA-2 code-signing support) and `KB4490628` (servicing stack),
   followed by a reboot and the latest servicing-stack update.
2. Install **Office 2010** (any edition). Its setup installs the newer
   **Microsoft Update** agent, which re-registers the "other Microsoft products"
   update source that modern Windows 7 requires.
3. Reboot, then in Internet Explorer visit <http://update.microsoft.com> and/or
   open **Windows Update** and click **Find out more** next to *"Get updates for
   other Microsoft products"* to opt in. (If the option stays hidden, open an
   Office application such as Word once and accept the "recommended updates"
   prompt.)
4. Go to **Windows Update → Change settings** and confirm the *Microsoft Update*
   section has reappeared.

> If Office 2010 is installed **before** running Legacy Update, checking for
> updates may hang forever — a documented Legacy Update issue. Run Legacy Update
> first.

### How to search for and install updates, step by step

**Modern Windows (8.1 / 10 / 11) still served by Windows Update:**

1. Open **Settings → Update & Security → Windows Update**.
2. Click **Check for updates** and let it download and install.
3. For optional software and driver updates click **View optional updates**
   (Windows 10/11) and select what you need.
4. Reboot and repeat until no more updates are found.

**Legacy Windows (2000 – 8.1) with Legacy Update:**

1. Download `LegacyUpdateSetup.exe` from <https://legacyupdate.net/> and run it
   on the target machine (Windows 2000/XP may need the documented workaround and
   the latest Internet Explorer first).
2. Accept the prompt to install the **prerequisite updates**. Legacy Update
   detects and installs everything missing and reboots as needed.
3. Open **Start → All Programs → Legacy Update** (or the site's **Install
   Updates** link) to load the classic Windows Update page.
4. Click **Express** to install all critical/security updates automatically, or
   **Custom** to choose individual updates, drivers and optional software.
5. Review the list, click **Install Updates**, accept the licenses when prompted,
   and let it install.
6. Reboot when asked and **re-run the check until no new updates appear**. The
   first check on Vista/7 can take 30–60 minutes — be patient.

**Very old Windows (95 / 98 / Me / NT 4.0) with Windows Update Restored:**

1. On the target machine open `windowsupdaterestored.com` in **Internet Explorer
   4.0–6.0**.
2. Follow the site's **Prerequisites Installer** (or the manual steps); the site
   loads the original Microsoft ActiveX control that scans for updates.
3. Use **Windows Update** for OS updates and **Microsoft Update** for Office and
   other Microsoft products.
4. Install the offered updates, reboot, and check again until the list is empty.

**Manual fallback:** almost every update is also published on the **Microsoft
Update Catalog** (<https://catalog.update.microsoft.com/>). Search by KB number,
download the `.msu`/`.cab` and install it by double-clicking it (or with
`wusa`/`dism`). This is the most reliable way to patch a machine that cannot
reach any update service.

## Extended kernels: running newer software on old Windows

An **extended kernel** (also called an *API extension pack*) is an unofficial
patch that adds **newer Windows APIs to an older Windows installation**. Instead
of emulating Windows, it modifies the real kernel and system DLLs (`kernel32.dll`,
`ntdll.dll`, `user32.dll`, `advapi32.dll`, …) so that programs written for a later
Windows release find the functions they expect and start normally. The result is a
genuine, native Windows install that can run software from one or more
generations ahead of it.

### Main projects

| Project | Target OS | Adds compatibility for | Notes |
|---|---|---|---|
| **KernelEx** | Windows 98 / Me | Windows 2000/XP applications | Open source; needs the `unicows` runtime. |
| **Windows 2000 Extended Kernel** (BlackWingCat) | Windows 2000 | Windows XP applications + modern software (VS2013 apps, Media Player 11, newer browsers) | Works on non-SSE2 CPUs; installed like a service pack. |
| **One-Core-API** (shorthorn-project) | Windows XP SP3, XP x64 SP2, Server 2003 SP2 | Vista/7/8/10 APIs — modern Chromium/Firefox, Steam, VS Code, .NET up to 4.8, DirectX 9–11 games via a `wined3d` wrapper, Office 2013/2016 | Based on ReactOS; actively developed. |
| **VxKex / VxKex NEXT** | Windows 7 (+ Server 2008 R2) | Windows 8/8.1/10/11-only applications (Chromium, Firefox, Blender, Python, VSCode, Spotify, …) | Per-application opt-in; patches each app's import table. |

### Advantages

- **Native performance and full driver support.** The app runs on the genuine NT
  kernel with real hardware drivers, so there is no CPU emulation overhead and no
  GPU/driver translation layer.
- **Whole-system effect.** Once installed, *every* compatible program benefits —
  no per-app configuration (except VxKex, which is per-app by design).
- **Runs on real, already-licensed Windows.** You keep your existing install,
  files and licences.
- **Often the only way to run a modern app on old hardware** (e.g. Windows 2000 on
  a Pentium III with no SSE2).

### Disadvantages

- **Unofficial and unsupported.** A bad update can make the system unbootable;
  always image/backup first (extended kernels can also conflict with Windows
  Update).
- **Security.** You are running newer, more complex code on an OS that no longer
  receives security fixes — do not use it on a network-exposed machine.
- **Incomplete.** Only a subset of APIs is implemented; some apps still crash and
  features (printing, DRM, hardware acceleration) may be missing or unstable.
- **Antivirus / EDR may flag it**, and it breaks system-file integrity
  (`sfc`/`dism` will complain).
- **Maintenance burden.** You must track a third-party project's releases.

### Extended kernel vs. Wine

| Aspect | Extended kernel | Wine |
|---|---|---|
| What it is | Patch to a **real** Windows install | **Userspace compatibility layer** that re-implements the Windows API on Linux/macOS/BSD |
| Host OS | Genuine Windows (old) | Linux/macOS/BSD (no Windows needed) |
| Kernel | Modifies the actual NT kernel/DLLs | Runs as a normal process; no kernel changes |
| Performance | Native (near 100%) | Usually good, sometimes lower; no real kernel drivers |
| Drivers | **Full** real drivers work | **No** kernel drivers; hardware support is limited/emulated |
| Compatibility | Very high for the targeted Windows generation | Broad but hit-or-miss; often needs tweaks/`winetricks` |
| Risk | Can break/corrupt the OS; unsupported | Sandboxed; removing it is trivial |
| Licensing | Needs a Windows licence | Free (Wine is open source) |
| Typical use | Squeeze modern apps out of old Windows hardware | Run Windows games/apps on Linux without Windows |

In short: **Wine** is the safer, portable choice if you are on Linux and can live
with compatibility gaps; an **extended kernel** is the higher-performance choice if
you are committed to a genuine old Windows install and want native drivers.

### How to install (examples)

> Always take a full disk image (or VM snapshot) before installing any extended
> kernel. Do these installs on a fresh Windows installation.

**1. KernelEx (Windows 98 / Me)**

1. Install the **Unofficial Service Pack** and the **`unicows`** runtime first.
2. Download the latest KernelEx installer from the project and run it.
3. Reboot. Then right-click any `.exe` → **Properties → Compatibility** to choose
   which KernelEx mode that program should use.

**2. Windows 2000 Extended Kernel (BlackWingCat)**

1. Install **Windows 2000 SP4** + Update Rollup 1 and reboot.
2. Download the latest **Extended Kernel** package (v3.0e or newer).
3. Run the installer as Administrator, accept the prompts and **reboot twice**.
4. Install the Visual C++ 2013 runtime it needs in order to run modern apps.

**3. One-Core-API (Windows XP / Server 2003)**

1. Install **Windows XP SP3** (or XP x64 SP2 / Server 2003 SP2) with all updates.
2. Enable **System Restore** and create a restore point first.
3. Download the latest **One-Core-API** release (`ocapi_*` installer).
4. Right-click the installer → **Run as administrator**.
5. Reboot. For DirectX 9+ games, copy the bundled `wined3d` DLLs into the game
   folder, and set the app's **compatibility mode** to Windows Vista/7 when asked.

**4. VxKex (Windows 7 / Server 2008 R2)**

1. Install **Windows 7 SP1** with the SHA-2 and (for modern apps) the Universal C
   Runtime updates.
2. Download and run the **VxKex** installer (Administrator), then reboot.
3. Right-click the target program → **Properties → VxKex** tab → tick **Enable
   VxKex for this program**.
4. If the app still refuses to start, set its **compatibility mode** to
   Windows 8/10 in the same Properties window (some apps also need a version
   spoof, configured in **VxKex Global Settings**).

## Knowledge base / troubleshooting

- **"Sentinel marked this request as rejected"** — Microsoft's anti-abuse system
  blocked the request based on your IP reputation. Wait 24–48 hours, use a VPN, or
  download manually from the official page. This is *not* a bug in Mido — the
  maintainer of Fido documents the same behaviour. The `win10x64-esp`,
  `win10x64-es-mx`, `win11x64-esp` and `win11x64-es-mx` arguments sidestep this by
  automatically falling back to an archive.org copy.
- **archive.org fallback** — the dedicated Spanish ISOs try Microsoft's official
  download first and, if Sentinel rejects it, download an identical copy from
  `archive.org` (slower than Microsoft's CDN). Mido retries and resumes
  automatically.
- **Windows 8.1 (`win81x64`) fails with HTTP 404** — Microsoft retired the
  automated Windows 8.1 download. Use `win81x64-enterprise-eval` instead.
- **Windows 7 is slow** — it is sourced from `web.archive.org`, which is much
  slower and less reliable than Microsoft's CDN. Mido retries automatically and
  resumes partial downloads.
- **Windows 10 x86 ISOs (English, Spanish)** — the official download is tried
  first; the `archive.org` fallback (Windows 10 22H2 builds) may be slower than
  Microsoft's CDN. Mido retries and resumes automatically.
- **Windows 8.1 Enterprise Spanish ISOs** — sourced from `archive.org`, which may
  be slower than Microsoft's CDN. Mido retries and resumes automatically.
- **Windows Server 2008 R2 Spanish ISO** — sourced from `archive.org`, which may be
  slower than Microsoft's CDN. Mido retries and resumes automatically.
- **Windows Server 2003 / Windows 2000 Server ISOs** — sourced from `archive.org`,
  which may be slower than Microsoft's CDN. Mido retries and resumes automatically.
- **Windows Vista ISOs** — sourced from `archive.org`, which may be slower than
  Microsoft's CDN. Mido retries and resumes automatically.
- **Retro Windows media (`win30`, `win31`, `wfw31`, `win311`/`wfw311`, `win95`,
  `win98`, `winme`, `winnt31`, `winnt35`, `winnt351`, `winnt40`, `backoffice`,
  `winframe`, plus the Spanish `win30-espa`, `win31-espa`, `wfw31-espa`,
  `win311-espa`, `wfw311-espa`, `win95-espa`, `win98-espa`, `winme-espa`)** —
  sourced from `archive.org`, which may be slower than Microsoft's CDN. Some of
  the oldest entries ship as ZIP/RAR/7z diskette images rather than ISOs. Mido
  retries and resumes automatically.
- **Enterprise/Server "no download link"** — Microsoft periodically changes the
  Evaluation Center pages. Please open an issue with the affected version.

## Want to save more time?

Check out the `create-media.sh` script in [Qvm-Create-Windows-Qube](https://github.com/ElliotKillick/qvm-create-windows-qube/tree/master/windows)! Now complete with Mido *and* an answer file to go with each provided download.

## How secure is it *really*?

Mido is reasonably secure software. Every chance to reduce attack surface is taken. Untrusted data is treated as such with proper validation steps. The highest possible version of TLS is always used (up to TLS 1.3). Easily verify security properties yourself in the transparent shell script.

- No web browser (headless Chromium running JavaScript) reduces the attack surface by *many* orders of magnitude.
- Force TLS 1.2 or TLS 1.3 (the latter when Microsoft servers support it).
- POSIX sh compatible and automatically switches to a more secure shell (Dash) if available.
- Force HTTP/1.1 to avoid frequent [curl HTTP/2 & HTTP/3 bugs](https://github.com/curl/curl/issues?q=is%3Aissue+label%3Acrash).
- Only shell builtins are used for the most critical functionality.
- Verify SHA-256 checksums of every downloaded ISO.

Still bugs? Wrap it in bubble wrap: `bwrap --ro-bind /bin /bin --ro-bind /usr/bin /usr/bin --ro-bind /lib /lib --ro-bind /usr/lib /usr/lib --ro-bind /lib64 /lib64 --ro-bind /usr/lib64 /usr/lib64 --ro-bind /usr/share /usr/share --ro-bind /etc /etc --dev-bind /dev/null /dev/null --bind "$PWD" "$PWD" --ro-bind "$PWD/Mido.sh" "$PWD/Mido.sh" --unshare-all --share-net -- ./Mido.sh --help`

## Testing

```sh
sh -n Mido.sh          # syntax check
shellcheck -s sh Mido.sh
```

## License

MIT License - Copyright (C) 2024 Elliot Killick <contact@elliotkillick.com>
