<div align="center">
    <a href="https://github.com/BENDER35/Mido_2026">
        <img width="160" src="assets/logo.png" alt="Logo" />
    </a>
</div>

<h3 align="center">
    Mido 2026
</h3>

<p align="center">
    El descargador <b>seguro</b> de Microsoft Windows
</p>

<p align="center">
    <a href="README.md">English</a> · <a href="README.es.md">Español</a>
</p>

¡Mido es un cliente de descarga libre y seguro para la API de descargas
(reverse-engineered) de Microsoft! Las descargas provienen de servidores
**oficiales** de Microsoft y solo necesitas ejecutar un comando para ir de
principio a fin.

Incluye funciones avanzadas como reanudación de descargas, verificación de
checksums SHA-256, lógica de reintentos, ISOs multiidioma (inglés, español y
español de México) y la descarga de varias versiones de Windows en un solo
comando. Está escrito en *POSIX sh puro* (con pocos coreutils) + curl, por lo que
funciona en cualquier sitio (incluso en Windows con WSL o Cygwin).

> **Actualización 2026:** Microsoft reemplazó su antigua API HTML de descargas
> por una API JSON (`software-download-connector`) protegida por un servicio
> antiabuso (Microsoft Sentinel). Mido 2026 implementa la API nueva y el
> handshake necesario, corrige varios bugs de shell, añade reintentos y soporte
> de español. Consulta [docs/TECHNICAL.es.md](docs/TECHNICAL.es.md) para los detalles.

#### ❌ La herramienta de creación de medios de Microsoft (`mediacreationtool.exe`, software privativo con bloatware)

<p align="center">
    <img src="assets/bloatware1.png" alt="Ejecutable de bloatware privativo de Microsoft"></img>
    <br />
    <img src="assets/bloatware2.png" width="250px" alt="Bloatware privativo de Microsoft"></img>
    <img src="assets/bloatware3.png" width="200px" alt="Bloatware de Microsoft"></img>
</p>

Sitio web con bloatware: `https://www.microsoft.com/en-us/software-download/windows11`
- Mido ofrece exactamente las mismas descargas que este sitio web (usa la misma API)

#### ✅ Mido (usando los **mismos** servidores oficiales de Microsoft; software libre)

<p align="center">
    <img src="assets/demo.gif" width="400" alt="GIF de demostración del proyecto"></img>
</p>

## Obtener Mido

Descarga [Mido.sh](https://raw.githubusercontent.com/BENDER35/Mido_2026/main/Mido.sh) abriendo el enlace, haciendo clic derecho y seleccionando "Guardar [página] como...".

### Requisitos

Mido está escrito en **POSIX `sh` puro** y solo necesita unas pocas herramientas
que ya están presentes en casi cualquier sistema Linux. En una instalación de
escritorio normal **no** tienes que instalar nada, salvo en algunas imágenes
mínimas, donde puede faltar **`curl`**.

| Herramienta | Para qué se usa | Paquete |
|---|---|---|
| `sh` | ejecutar el script (se prefiere Dash y se usa automáticamente si está) | `dash` / `bash` |
| `curl` | comunicarse con los servidores de Microsoft | `curl` |
| `sha256sum` | verificar las ISOs descargadas | `coreutils` |
| `grep`, `sed`, `tr`, `cut`, `head`, `tail`, `fold`, `printf` | analizar las respuestas de la API de descargas | `coreutils`, `grep`, `sed` |
| `tput` | salida con color (opcional) | `ncurses` |
| `uuidgen` | generar un session ID **solo** en sistemas sin `/proc` (macOS/BSD — nunca hace falta en Linux) | `util-linux` / incluido en macOS |

Si falta algo, instálalo con el gestor de paquetes de tu distribución:

| Distribución | Comando |
|---|---|
| Debian / Ubuntu / Mint / Pop!\_OS / Kali / Raspberry Pi OS | `sudo apt update && sudo apt install -y curl` |
| Fedora | `sudo dnf install -y curl` |
| RHEL / CentOS Stream / Rocky / AlmaLinux | `sudo dnf install -y curl` (antiguos: `sudo yum install -y curl`) |
| openSUSE Leap / Tumbleweed / SLES | `sudo zypper install -y curl` |
| Arch / Manjaro / EndeavourOS / Garuda | `sudo pacman -S --needed curl` |
| Alpine | `sudo apk add curl` |
| Void | `sudo xbps-install -S curl` |
| Gentoo / Funtoo | `sudo emerge net-misc/curl` |
| NixOS | `nix-shell -p curl` (o añade `pkgs.curl` a `environment.systemPackages`) |
| Slackware | `sudo slackpkg install curl` |
| Solus | `sudo eopkg install curl` |
| Clear Linux | `sudo swupd bundle-add curl` |
| FreeBSD | `sudo pkg install curl` (coreutils y util-linux ya vienen) |
| macOS | `curl` y `uuidgen` ya vienen; instala GNU coreutils para `sha256sum`: `brew install coreutils` y añade `$(brew --prefix coreutils)/libexec/gnubin` a tu `PATH` |

> Puedes comprobar que todo está listo ejecutando `./Mido.sh --help`, que
> imprime la lista de medios sin tocar la red.

### Mac y Linux

Descarga `Mido.sh`, abre una terminal, da permisos de ejecución al archivo y
ejecútalo (como en el GIF de arriba):

```sh
chmod +x Mido.sh
./Mido.sh win11x64
```

### Windows

Mido es un script de shell POSIX, así que **no** se ejecuta de forma nativa en
`cmd.exe` ni en PowerShell — en Windows se ejecuta dentro de **WSL (Windows
Subsystem for Linux)**, que proporciona un entorno Linux real. Esta es la forma
recomendada y totalmente soportada. Los wrappers `Mido.bat` / `Mido.ps1`
incluidos detectan WSL y lo hacen por ti (ver *Wrappers nativos para Windows*
más abajo).

Como alternativa puedes usar una capa de emulación POSIX como
[Cygwin](https://www.cygwin.com/install.html) o
[MSYS2](https://www.msys2.org/#installation), instalables en un solo comando con
WinGet:

```
winget install -e --id Cygwin.Cygwin
winget install -e --id MSYS2.MSYS2
```

#### Paso 1 — Instalar WSL en Windows 11

Abre **PowerShell como Administrador** (clic derecho en el botón Inicio →
*Terminal (Admin)*) y ejecuta:

```powershell
wsl --install
```

Esto habilita las características necesarias, instala el kernel de Linux de WSL2
y una distribución de Linux (Ubuntu por defecto), y te pide reiniciar. Tras el
reinicio, Ubuntu se abre y te pide crear un usuario y una contraseña. Ya está.

#### Paso 1 (alternativa) — Instalar WSL en Windows 10

> **Estado de soporte de Windows 10.** Windows 10 llegó a su **fin de soporte el
> 14 de octubre de 2025**. Los equipos Home/Pro pueden unirse al programa
> **Consumer ESU**, que solo entrega actualizaciones de seguridad hasta el
> **13 de octubre de 2026**. Los equipos comerciales (Enterprise/Education/Pro
> de uso comercial) obtienen hasta **tres años** de ESU: el Año 1 termina el
> **13 oct 2026**, el Año 2 el **12 oct 2027** y el Año 3 el **10 oct 2028**.
> WSL2 sigue funcionando en Windows 10, pero el sistema solo recibe parches
> mientras siga teniendo servicio. Consulta las
> [preguntas frecuentes de ESU](https://learn.microsoft.com/es-es/lifecycle/faq/extended-security-updates).

**Windows 10 versión 2004 (build 19041) y posteriores** — que es toda
instalación 22H2 con soporte — usan el mismo comando único que Windows 11:

```powershell
wsl --install
```

En **compilaciones antiguas de Windows 10** y en **Windows 10 LTSC / IoT
Enterprise LTSC** (que no incluyen Microsoft Store), `wsl --install` puede no
existir o no poder descargar una distribución. Usa entonces los pasos manuales:

1. Busca **"Activar o desactivar características de Windows"**, habilita
   **Windows Subsystem for Linux** y **Virtual Machine Platform**, y reinicia.
   (Comandos equivalentes:
   `dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart`
   y lo mismo para `VirtualMachinePlatform`.)
2. Para usar WSL2, instala el **paquete de actualización del kernel de Linux para
   WSL2** desde <https://aka.ms/wsl2kernel> y reinicia (`wsl --update` también
   funciona una vez que WSL está presente).
3. Instala una distribución. Sin Store, descarga el paquete de la distribución
   desde <https://aka.ms/wslstore>, renombra el archivo `.AppxBundle`/`.Appx` a
   `.zip`, descomprímelo y ejecuta el `ubuntu.exe` (o `debian.exe`, …) incluido.
   Después ejecuta `wsl --set-default-version 2`.

#### Paso 2 — Ejecutar Mido

Dentro del shell de WSL, descarga Mido y ejecútalo igual que en Linux:

```sh
curl -O https://raw.githubusercontent.com/BENDER35/Mido_2026/main/Mido.sh
chmod +x Mido.sh
./Mido.sh win11x64
```

Los archivos se guardan en el directorio actual de WSL; usa
`/mnt/c/Users/<usuario>/Downloads` si los quieres en la unidad de Windows.

#### Windows Server

WSL es compatible con **Windows Server 2019 y posteriores**. Las versiones
Server se corresponden con las de escritorio así:

| Escritorio | Equivalente Server | Soporte WSL |
|---|---|---|
| Windows 10 1809 | Windows Server 2019 | **solo WSL 1** (build 17763 < 18362); no hay `wsl --install`, hay que habilitar la característica a mano |
| Windows 11 21H2 / 22H2 | Windows Server 2022 | WSL 1 y 2 — `wsl --install` |
| Windows 11 24H2 | Windows Server 2025 | WSL 1 y 2, incluido Server Core — `wsl --install` |

- **Windows Server 2022 / 2025:** en un PowerShell **como Administrador** ejecuta
  `wsl --install` y reinicia. Microsoft Store no está disponible en Server, así
  que `wsl --install` (o `wsl --install -d <Distro>`) descarga la distribución
  directamente.
- **Windows Server 2019 (y Server Core):** ejecuta
  `Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux, VirtualMachinePlatform`
  en un PowerShell como Administrador, reinicia e instala una distribución
  manualmente (los paquetes de `aka.ms/wslstore`). WSL2 necesita build 18362+, así
  que Server 2019 se limita a **WSL 1**.

#### Wrappers nativos para Windows

Mido incluye wrappers nativos para Windows para mayor comodidad:

- **`Mido.bat`** - Wrapper de archivo por lotes (ejecutar con doble clic o desde cmd)
- **`Mido.ps1`** - Wrapper de PowerShell (ejecutar desde PowerShell)

Ambos wrappers detectan automáticamente WSL y ejecutan `Mido.sh` a través de él,
pasando todos los argumentos. Ejemplos de uso:

```
Mido.bat win11x64
Mido.ps1 win10x64 win11x64
```

Si WSL no está instalado, los wrappers te pedirán que lo instales.

## Uso

```
./Mido.sh <windows_media>...
```

Ejemplos:

```
./Mido.sh win11x64                       # Windows 11, inglés (EE. UU.)
MIDO_LANG=es-ES ./Mido.sh win10x64       # Windows 10, español (España)
MIDO_LANG=es-MX ./Mido.sh win11x64       # Windows 11, español (México)
./Mido.sh win7x64-ultimate win10x64      # Varias ISOs en un solo comando
./Mido.sh all                            # Todos los medios soportados
```

### Medios disponibles

| Argumento | Descripción |
|---|---|
| `vista-x64-sp1` | Windows Vista SP1 x64 (inglés, obtenido de archive.org) |
| `vista-x86-sp1` | Windows Vista SP1 x86 (inglés, obtenido de archive.org) |
| `vista-es-x64-sp1` | Windows Vista SP1 x64 español (obtenido de archive.org) |
| `vista-es-x86-sp1` | Windows Vista SP1 x86 español (obtenido de archive.org) |
| `vista-x64-sp2` | Windows Vista **Enterprise** SP2 x64 (inglés, obtenido de archive.org) |
| `vista-x86-sp2` | Windows Vista **Enterprise** SP2 x86 (inglés, obtenido de archive.org) |
| `vista-es-x64-sp2` | Windows Vista **Enterprise** SP2 x64 español (obtenido de archive.org) |
| `vista-es-x86-sp2` | Windows Vista **Enterprise** SP2 x86 español (obtenido de archive.org) |
| `vista-x64-sp2-n` | Windows Vista N SP2 x64 (Home Basic N + Business N, inglés, obtenido de archive.org) |
| `vista-x64-sp2-business-n` | Windows Vista Business N SP2 x64 (inglés, obtenido de archive.org) |
| `vista-x86-sp2-business-n` | Windows Vista Business N SP2 x86 (inglés, obtenido de archive.org) |
| `win7x64-ultimate` | Windows 7 Ultimate x64 (obtenido de Wayback Machine) |
| `win7x64-ultimate-esp` | Windows 7 Ultimate x64 en español — primero Microsoft oficial, si falla archive.org |
| `win7x86-ultimate` | Windows 7 Ultimate x86 (32-bit) — sourced from archive.org |
| `win7x86-ultimate-esp` | Windows 7 Ultimate x86 Spanish (32-bit) — Microsoft official first, archive.org fallback |
| `win10x64` | Windows 10 x64 (multiedición) |
| `win10x64-esp` | Windows 10 x64 español (España) — primero Microsoft oficial, si falla archive.org |
| `win10x64-es-mx` | Windows 10 x64 español (México) — primero Microsoft oficial, si falla archive.org |
| `win10x86` | Windows 10 x86 (32-bit, multiedición) — primero Microsoft oficial, si falla archive.org |
| `win10x86-esp` | Windows 10 x86 (32-bit) español (España) — primero Microsoft oficial, si falla archive.org |
| `win10x86-es-mx` | Windows 10 x86 (32-bit) español (México) — primero Microsoft oficial, si falla archive.org |
| `win11x64` | Windows 11 x64 (multiedición) |
| `win11x64-esp` | Windows 11 x64 español (España) — primero Microsoft oficial, si falla archive.org |
| `win11x64-es-mx` | Windows 11 x64 español (México) — primero Microsoft oficial, si falla archive.org |
| `win81-serial` | Claves de instalación de Windows 8.1 (para continuar la instalación, no para activar) |
 |
| `win10x86-enterprise-eval` | Windows 10 Enterprise 32-bit Evaluation (LTSC 21H2 x86, obtenido de archive.org) |
| `win11x64-enterprise-eval` | Windows 11 Enterprise Evaluation |
| `win10x64-enterprise-ltsc-eval` | Windows 10 Enterprise LTSC Evaluation (la más segura) |
| `win11x64-enterprise-ltsc-eval` | Windows 11 Enterprise LTSC Evaluation (la más segura) |
| `win11x64-iot-enterprise-ltsc-eval` | Windows 11 IoT Enterprise LTSC Evaluation |
| `win11x64-iot-enterprise-26h2` | Windows 11 IoT Enterprise 26H2 (canal anual, inglés, obtenido de archive.org) |
| `win11x64-iot-enterprise-ltsc-2024` | Windows 11 IoT Enterprise LTSC 2024 (completa, inglés, x64, obtenido de archive.org) |
| `win10x64-iot-enterprise-22h2` | Windows 10 IoT Enterprise 22H2 (canal anual, inglés, x64, obtenido de archive.org) |
| `win10x64-iot-enterprise-ltsc-2021` | Windows 10 IoT Enterprise LTSC 2021 (completa, inglés, x64, obtenido de archive.org) |
| `win10x64-iot-enterprise-ltsc-2019` | Windows 10 IoT Enterprise LTSC 2019 (completa, inglés, x64, obtenido de archive.org) |
| `win10x86-iot-enterprise-ltsc-2019` | Windows 10 IoT Enterprise LTSC 2019 (completa, inglés, x86/32 bits, obtenido de archive.org) |
| `win81x64` | Windows 8.1 x64 (**retirado por Microsoft**, usa la Enterprise Eval) |
| `win81x86` | Windows 8.1 x86 (32-bit) — sourced from archive.org |
| `win81x64-ent-32-espa` | Windows 8.1 Enterprise 32 bits español (obtenido de archive.org) |
| `win81x64-ent-64-esp` | Windows 8.1 Enterprise 64 bits español (obtenido de archive.org) |
| `win81-serial` | Claves de instalación de Windows 8.1 (para continuar la instalación, no para activar) |

| `win11x64-enterprise-ltsc-2024` | Windows 11 Enterprise LTSC 2024 (completa, inglés, x64, obtenido de archive.org) |
| `win11x64-enterprise-ltsc-2024-esp` | Windows 11 Enterprise LTSC 2024 (completa, español de España, x64, obtenido de archive.org) |
| `win11x64-enterprise-ltsc-2024-es-mx` | Windows 11 Enterprise LTSC 2024 (completa, español de México, x64, obtenido de archive.org) |
| `win10x64-enterprise-ltsc-2021` | Windows 10 Enterprise LTSC 2021 (completa, inglés, x64, obtenido de archive.org) |
| `win10x64-enterprise-ltsc-2021-esp` | Windows 10 Enterprise LTSC 2021 (completa, español de España, x64, obtenido de archive.org) |
| `win10x64-enterprise-ltsc-2021-es-mx` | Windows 10 Enterprise LTSC 2021 (completa, español de México, x64, obtenido de archive.org) |
| `win10x86-enterprise-ltsc-2021` | Windows 10 Enterprise LTSC 2021 (completa, inglés, x86/32 bits, obtenido de archive.org) |
| `win10x86-enterprise-ltsc-2021-esp` | Windows 10 Enterprise LTSC 2021 (completa, español de España, x86/32 bits, obtenido de archive.org) |
| `win10x86-enterprise-ltsc-2021-es-mx` | Windows 10 Enterprise LTSC 2021 (completa, español de México, x86/32 bits, obtenido de archive.org) |
| `win10x64-enterprise-ltsb-2016` | Windows 10 Enterprise LTSB 2016 (completa, inglés, x64, obtenido de archive.org) |
| `win10x64-enterprise-ltsb-2016-esp` | Windows 10 Enterprise LTSB 2016 (completa, español, x64, obtenido de archive.org) |
| `win10x86-enterprise-ltsb-2016` | Windows 10 Enterprise LTSB 2016 (completa, inglés, x86/32 bits, obtenido de archive.org) |
| `win10x86-enterprise-ltsb-2016-esp` | Windows 10 Enterprise LTSB 2016 (completa, español, x86/32 bits, obtenido de archive.org) |
| `win10x64-enterprise-ltsb-2015` | Windows 10 Enterprise LTSB 2015 (completa, inglés, x64, obtenido de archive.org) |
| `win10x64-enterprise-ltsb-2015-esp` | Windows 10 Enterprise LTSB 2015 (completa, español, x64, obtenido de archive.org) |
| `win10x86-enterprise-ltsb-2015` | Windows 10 Enterprise LTSB 2015 (completa, inglés, x86/32 bits, obtenido de archive.org) |
| `win10x86-enterprise-ltsb-2015-esp` | Windows 10 Enterprise LTSB 2015 (completa, español, x86/32 bits, obtenido de archive.org) |
| `win2008r2` | Windows Server 2008 R2 SP1 (x64, Inglés) |
| `win2008r2-espa` | Windows Server 2008 R2 SP1 (x64, eval en español, obtenido de archive.org) |
| `win2008-server-x64` | Windows Server 2008 SP2 (x64, Inglés, todas las ediciones, obtenido de archive.org) |
| `win2008-server-x64-espa` | Windows Server 2008 SP2 (x64, Español, todas las ediciones, obtenido de archive.org) |
| `win2008-server-x86` | Windows Server 2008 SP2 (x86, Inglés, todas las ediciones, obtenido de archive.org) |
| `win2008-server-x86-espa` | Windows Server 2008 SP2 (x86, Español, todas las ediciones, obtenido de archive.org) |
| `win2000-pro` | Windows 2000 Professional SP4 (Inglés, obtenido de archive.org) |
| `win2000-pro-espa` | Windows 2000 Professional SP4 en Español (obtenido de archive.org) |
| `win2000-pro-oem` | Windows 2000 Professional SP3 OEM (Inglés, obtenido de archive.org) |
| `win2000-pro-retail` | Windows 2000 Professional SP4 Retail (Inglés, obtenido de archive.org) |
| `win2000-pro-oem-espa` | Windows 2000 Professional SP1 OEM en Español (obtenido de archive.org) |
| `win2000-pro-retail-espa` | Windows 2000 Professional RTM Retail en Español (obtenido de archive.org) |
| `win-xp-pro` | Windows XP Professional SP3 (Inglés, obtenido de archive.org) |
| `win-xp-pro-espa` | Windows XP Professional SP3 en Español (obtenido de archive.org) |
| `win-xp-pro-32` | Windows XP Professional x86 (32-bit, obtenido de archive.org) |
| `win-xp-pro-32-espa` | Windows XP Professional x86 SP3 en Español (32-bit, obtenido de archive.org) |
| `win-xp-pro-64` | Windows XP Professional x64 SP2 (64-bit, Inglés, obtenido de archive.org) |
| `win-xp-home` | Windows XP Home Edition SP3 (Inglés, obtenido de archive.org) |
| `win-xp-home-espa` | Windows XP Home Edition SP3 en Español (obtenido de archive.org) |
| `win-xp-home-oem` | Windows XP Home Edition RTM OEM (Inglés, obtenido de archive.org) |
| `win-xp-home-retail` | Windows XP Home Edition SP3 Retail (Inglés, obtenido de archive.org) |
| `win-xp-home-oem-espa` | Windows XP Home Edition SP2 OEM en Español (obtenido de archive.org) |
| `win-xp-home-retail-espa` | Windows XP Home Edition SP3 Retail en Español (obtenido de archive.org) |
| `win-xp-pro-oem` | Windows XP Professional SP2 OEM (Inglés, obtenido de archive.org) |
| `win-xp-pro-retail` | Windows XP Professional SP3 Retail (Inglés, obtenido de archive.org) |
| `win-xp-pro-oem-espa` | Windows XP Professional SP2 OEM en Español (obtenido de archive.org) |
| `win-xp-pro-retail-espa` | Windows XP Professional SP1 Retail en Español (obtenido de archive.org) |
| `win7x64-pro` | Windows 7 Professional x64 (sourced from archive.org) |
| `win7x64-pro-esp` | Windows 7 Professional x64 en español — primero Microsoft oficial, si falla archive.org |
| `win7x86-pro` | Windows 7 Professional x86 (32-bit) — sourced from archive.org |
| `win7x86-pro-esp` | Windows 7 Professional x86 Spanish (32-bit) — Microsoft official first, archive.org fallback |
| `win7x64-homepremium` | Windows 7 Home Premium x64 (sourced from archive.org) |
| `win7x64-homepremium-esp` | Windows 7 Home Premium x64 en español — primero Microsoft oficial, si falla archive.org |
| `win7x86-homepremium` | Windows 7 Home Premium x86 (32-bit) — sourced from archive.org |
| `win7x86-homepremium-esp` | Windows 7 Home Premium x86 Spanish (32-bit) — Microsoft official first, archive.org fallback |
| `win7x64-enterprise` | Windows 7 Enterprise x64 (sourced from archive.org) |
| `win7x64-enterprise-esp` | Windows 7 Enterprise x64 en español — primero Microsoft oficial, si falla archive.org |
| `win7x86-enterprise` | Windows 7 Enterprise x86 (32-bit) — sourced from archive.org |
| `win7x86-enterprise-esp` | Windows 7 Enterprise x86 Spanish (32-bit) — Microsoft official first, archive.org fallback |
| `win7x64-sp1` | Windows 7 SP1 x64 (sourced from archive.org) |
| `win7x86-sp1` | Windows 7 SP1 x86 (32-bit, sourced from archive.org) |
| `win81x64-pro` | Windows 8.1 Pro x64 — Microsoft retiró la automatización, usa archive.org |
| `win81x64-pro-esp` | Windows 8.1 Pro en español (España) — primero Microsoft oficial, si falla archive.org |
| `win81x86-pro` | Windows 8.1 Pro x86 (32-bit) — sourced from archive.org |
| `win81x86-pro-esp` | Windows 8.1 Pro x86 Spanish (32-bit) — Microsoft official first, archive.org fallback |
| `win2003-server` | Windows Server 2003 Enterprise (x86, Inglés, obtenido de archive.org) |
| `win2003-server-espa` | Windows Server 2003 Enterprise (x86, Español, obtenido de archive.org) |
| `win2003-server-x64` | Windows Server 2003 R2 Enterprise x64 SP2 (Inglés, obtenido de archive.org) |
| `win2003-server-x64-espa` | Windows Server 2003 R2 Enterprise x64 SP2 (Español, obtenido de archive.org) |
| `win2012r2-eval` | Windows Server 2012 R2 Evaluation (obtenido de archive.org, ISO actualizada) |
| `win2016-essentials` | Windows Server 2016 Essentials x64 Inglés (obtenido de archive.org) |
| `win2019-iso` | Windows Server 2019 x64 Inglés (ISO completa, obtenido de archive.org) |
| `win2000-server` | Windows 2000 Server SP4 (Inglés, obtenido de archive.org) |
| `win2000-server-espa` | Windows 2000 Server SP4 (Español, obtenido de archive.org) |
| `win2000-advanced-server` | Windows 2000 Advanced Server SP1 (Inglés, obtenido de archive.org) |
| `win2000-advanced-server-espa` | Windows 2000 Advanced Server SP1 (Español, obtenido de archive.org) |
| `win2000-datacenter` | Windows 2000 Datacenter Server RTM OEM (SP1, Inglés, obtenido de archive.org) |
| `win2000-datacenter-sp4` | Windows 2000 Datacenter Server SP4 (Inglés, obtenido de archive.org) |
| `win2012r2-eval` | Windows Server 2012 R2 Evaluation |
| `win2016-eval` | Windows Server 2016 Evaluation |
| `win2019-eval` | Windows Server 2019 Evaluation |
| `win2022-eval` | Windows Server 2022 Evaluation |
| `win2025-eval` | Windows Server 2025 Evaluation |
| `win2025-enterprise-64` | Windows Server 2025 Enterprise x64 (64-bit) |
| `win2025-enterprise-64-esp` | Windows Server 2025 Enterprise x64 español (64-bit) |
| `win2025-datacenter-64` | Windows Server 2025 Datacenter x64 (64-bit) |
| `win2025-datacenter-64-esp` | Windows Server 2025 Datacenter x64 español (64-bit) |
| `win2022-eval` | Windows Server 2022 Evaluation |
| `win2022-enterprise-64` | Windows Server 2022 Enterprise x64 (64-bit) |
| `win2022-enterprise-64-esp` | Windows Server 2022 Enterprise x64 español (64-bit) |
| `win2022-datacenter-64` | Windows Server 2022 Datacenter x64 (64-bit) |
| `win2022-datacenter-64-esp` | Windows Server 2022 Datacenter x64 español (64-bit) |
| `win2012r2-essentials-eval` | Windows Server 2012 R2 Essentials Evaluation |
| `win2016-essentials-eval` | Windows Server 2016 Essentials Evaluation |
| `win2019-essentials-eval` | Windows Server 2019 Essentials Evaluation |
| `hyperv2012-eval` | Hyper-V Server 2012 Evaluation |
| `hyperv2012r2-eval` | Hyper-V Server 2012 R2 Evaluation |
| `hyperv2016-eval` | Hyper-V Server 2016 Evaluation |
| `hyperv2019-eval` | Hyper-V Server 2019 Evaluation |
| `win30` | Windows 3.0 (inglés, obtenido de archive.org; ZIP de los disquetes originales) |
| `win30-espa` | Windows 3.0a en Español (obtenido de archive.org; ZIP) |
| `win31` | Windows 3.1 (inglés, obtenido de archive.org) |
| `win31-espa` | Windows 3.1 en Español (obtenido de archive.org) |
| `wfw31` | Windows for Workgroups 3.1 (inglés, compilación 014e, obtenido de archive.org; RAR de los disquetes originales) |
| `wfw31-espa` | Windows for Workgroups 3.1 en Español (obtenido de archive.org; imágenes de disquete en 7z) |
| `win311` | Windows 3.11 / Windows for Workgroups 3.11 (inglés, obtenido de archive.org) |
| `win311-espa` | Windows 3.11 en Español (obtenido de archive.org) |
| `wfw311` | Windows for Workgroups 3.11 (inglés, los mismos medios que `win311`, obtenido de archive.org) |
| `wfw311-espa` | Windows for Workgroups 3.11 en Español (obtenido de archive.org) |
| `win95` | Windows 95 (inglés, obtenido de archive.org) |
| `win95-espa` | Windows 95 en Español (obtenido de archive.org) |
| `win98` | Windows 98 Second Edition (inglés, obtenido de archive.org) |
| `win98-espa` | Windows 98 Second Edition en Español (obtenido de archive.org) |
| `winme` | Windows Millennium Edition (inglés, obtenido de archive.org) |
| `winme-espa` | Windows Millennium Edition en Español (obtenido de archive.org) |
| `winnt31` | Windows NT 3.1 Workstation (inglés, obtenido de archive.org) |
| `winnt35` | Windows NT 3.5 Workstation (inglés, obtenido de archive.org) |
| `winnt351` | Windows NT 3.51 Workstation (inglés, obtenido de archive.org) |
| `winnt40` | Windows NT 4.0 Workstation (inglés, obtenido de archive.org) |
| `backoffice` | Microsoft BackOffice Small Business Server 4.0 (x86, obtenido de archive.org) |
| `winframe` | Citrix WinFrame 1.6 (Windows NT 3.51 Terminal Server Edition, obtenido de archive.org) |

## Soporte de idiomas

Define la variable de entorno `MIDO_LANG` con uno de estos valores:

| Valor | Idioma |
|---|---|
| `en-US` | Inglés (Estados Unidos) — por defecto |
| `es-ES` | Español (España) |
| `es-MX` | Español (México) |

Las ISOs en español están disponibles para las versiones de **consumidor**
(`win10x64`, `win11x64`). Además de la variable `MIDO_LANG`, existen argumentos
dedicados para español de España y de México: `win10x64-esp`,
`win10x64-es-mx`, `win11x64-esp` y `win11x64-es-mx`. Estos intentan primero la
descarga oficial de Microsoft y, si la petición es rechazada (por ejemplo por el
sistema antiabuso Sentinel), usan una copia idéntica de archive.org como
respaldo. Windows 10 de 32 bits (x86) está disponible vía archive.org
para inglés (`win10x86`), España (`win10x86-esp`) y México (`win10x86-es-mx`).
Windows 8.1 Enterprise en español también está disponible vía archive.org tanto
para 32 bits (`win81x64-ent-32-espa`) como para 64 bits (`win81x64-ent-64-esp`).
Una ISO de evaluación en español de Windows Server 2008 R2 SP1 está disponible
vía archive.org (`win2008r2-espa`). Windows Server 2008 (sin R2) SP2 está
disponible vía archive.org en inglés y español, tanto para 64 bits
(`win2008-server-x64`, `win2008-server-x64-espa`) como para 32 bits
(`win2008-server-x86`, `win2008-server-x86-espa`). Windows Server 2003 Enterprise y Windows 2000
Server SP4 también están disponibles en inglés y español vía archive.org
(`win2003-server`, `win2003-server-espa`, `win2000-server`, `win2000-server-espa`).
Windows Server 2003 R2 Enterprise x64 SP2 de 64 bits está disponible en inglés
(`win2003-server-x64`) y español (`win2003-server-x64-espa`).
Windows Vista SP1 en español también está disponible vía archive.org
(`vista-es-x64-sp1`, `vista-es-x86-sp1`).
Windows Vista **Enterprise** SP2 en español también está disponible vía archive.org
(`vista-es-x64-sp2`, `vista-es-x86-sp2`).
Los medios **N** de Windows Vista (que cumplen la sentencia de la UE y excluyen
el software multimedia incluido) están disponibles en inglés: el DVD N todo en
uno x64 con Home Basic N y Business N (`vista-x64-sp2-n`) y las ISOs Business N
x64 y x86 (`vista-x64-sp2-business-n`, `vista-x86-sp2-business-n`). Ten en cuenta
que **Windows Vista Enterprise N** nunca se publicó como medio MSDN
independiente (el DVD "N" solo incluye Home Basic N y Business N) y que no hay
ISOs N de Vista en español en archive.org, por lo que no se ofrecen argumentos
`-es` para las N.
Las ISOs en español de Windows 7 (Ultimate, Professional, Home Premium y
Enterprise, x64 y x86) también están disponibles vía archive.org
(`win7x64-ultimate-esp`, `win7x86-ultimate-esp`, `win7x64-pro-esp`,
`win7x86-pro-esp`, `win7x64-homepremium-esp`, `win7x86-homepremium-esp`,
`win7x64-enterprise-esp`, `win7x86-enterprise-esp`); el medio Ultimate intenta
primero la descarga oficial de Microsoft y, si falla, archive.org.
Los medios Enterprise, Server y Evaluation son, por lo demás, únicamente en inglés,
tal como los publica Microsoft. Las ISOs en otros idiomas se guardan con un sufijo
de idioma (por ejemplo `win11x64.es-MX.iso`) o con un nombre `-espa`/`-esp`/
`-es-mexico` según corresponda, para no sobrescribir las inglesas.

Windows 2000 Professional, Windows XP Professional, Windows XP Home Edition y
  Windows XP Professional x64 en español también están disponibles vía archive.org. Windows 8.1 Pro en español
  también está disponible vía archive.org (`win81x64-pro-esp`). Como Microsoft no publica checksums
oficiales de cada versión localizada, las ISOs localizadas pueden mostrar
  `NO KNOWN CHECKSUM (skipping verification)`.

Windows 2000 Professional y Windows XP están además disponibles en los canales
de licencia originales **OEM** y **Retail** (FPP), en inglés y español:
`win2000-pro-oem`, `win2000-pro-retail`, `win2000-pro-oem-espa`,
`win2000-pro-retail-espa`, `win-xp-home-oem`, `win-xp-home-retail`,
`win-xp-home-oem-espa`, `win-xp-home-retail-espa`, `win-xp-pro-oem`,
`win-xp-pro-retail`, `win-xp-pro-oem-espa` y `win-xp-pro-retail-espa`.
Windows XP Home Edition y Windows XP Professional están disponibles en inglés y
español (`win-xp-home`, `win-xp-home-espa`, `win-xp-pro`, `win-xp-pro-espa`,
`win-xp-pro-32-espa`).

> **Nota sobre la disponibilidad del español de México:** Microsoft solo localizó
> Windows a una versión aparte de español de México (`es-MX`) a partir de
> **Windows 10**. Las versiones anteriores (Windows 3.x, 95, 98, Me, NT, 2000,
> XP, Vista, Windows 7 y Windows 8/8.1) se publicaron con una **única versión en
> español** (`es-ES`) que sirve a todas las regiones hispanohablantes, por lo que
> no se ofrecen argumentos `-es-mx` para ellas. Los argumentos genuinos `-es-mx`
> (y `MIDO_LANG=es-MX`) existen solo para Windows 10, Windows 11 y sus ediciones
> Enterprise LTSC, para las que Microsoft sí publicó medios separados de español
> (México). Los antiguos argumentos `-es-mx` de Windows 7 y Windows 8.1 se
> eliminaron porque los espejos en archive.org de esas versiones (que nunca fueron
> oficiales) dejaron de estar disponibles.

Las versiones retro (`win30`, `win31`, `wfw31`, `win311`/`wfw311`, `win95`,
`win98`, `winme`, `winnt31`, `winnt35`, `winnt351`, `winnt40`, `backoffice`,
`winframe`) provienen de `archive.org` y no tienen checksums publicados. Windows
3.x, Windows 95, Windows 98 Second Edition y Windows Millennium Edition también
están disponibles en español (`win30-espa`, `win31-espa`, `wfw31-espa`,
`win311-espa`, `wfw311-espa`, `win95-espa`, `win98-espa`, `winme-espa`); el
resto de las versiones retro son únicamente en inglés. Ten en cuenta que `win311`
y `wfw311` se refieren al mismo producto (Windows 3.11 para Trabajo en Grupo) y
comparten los mismos medios en inglés; en español se distingue un medio
"Windows 3.11" (`win311-espa`) de un medio "Windows 3.11 para Trabajo en Grupo"
(`wfw311-espa`). Como Microsoft nunca localizó estas versiones al español de
México, no existen argumentos `-es-mx` para ellas.

## ¿Cómo funciona Mido?

Interactúa con la API propietaria de descargas de Microsoft para obtener la
última versión de Windows y generar un enlace de descarga fresco (válido 24
horas). Después descarga el archivo, verifica su checksum SHA-256 y reanuda las
descargas parciales automáticamente.

En detalle:

1. Extrae de la página oficial el *product edition ID* de la versión solicitada.
2. Registra un *session ID* aleatorio y completa el handshake antiabuso de
   Microsoft (*Sentinel*).
3. Consulta la API JSON para obtener el *SKU ID* del idioma solicitado.
4. Solicita un enlace de descarga fresco y lo descarga en `<archivo>.PART`.
5. Verifica el checksum SHA-256 y renombra el archivo a `<archivo>` (OK) o
   `<archivo>.UNVERIFIED` (requiere revisión manual).

Consulta [docs/TECHNICAL.es.md](docs/TECHNICAL.es.md) para el recorrido completo.

## ¿Qué más puede hacer Mido?

Además de las versiones de consumidor (Windows 10 y 11), puede descargar
automáticamente las últimas ediciones Server (por ejemplo Windows Server 2025) y
Enterprise de casi todas las versiones, desde Windows 7 (o Server 2008 R2, e
incluso Server 2003 y 2000 Server) en adelante. También incluye versiones retro
de principios de los años 90: Windows 3.0, Windows 3.1, Windows for Workgroups
3.1, Windows 3.11 para Trabajo en Grupo, Windows 95, Windows 98 Second Edition,
Windows Millennium Edition, Windows NT 3.1, 3.5 y 3.51 Workstation y Windows NT
4.0 Workstation (`win30`, `win31`, `wfw31`, `win311`/`wfw311`, `win95`, `win98`,
`winme`, `winnt31`, `winnt35`, `winnt351`, `winnt40`, obtenidas de archive.org).
También ofrece los productos de servidor de la era Windows NT 3.51: Microsoft
BackOffice Small Business Server 4.0 (`backoffice`) y Citrix WinFrame 1.6
(Windows NT 3.51 Terminal Server Edition, `winframe`). Windows 3.x, Windows 95,
98 y Millennium Edition también tienen medios en español (`win30-espa`,
`win31-espa`, `wfw31-espa`, `win311-espa`, `wfw311-espa`, `win95-espa`,
`win98-espa`, `winme-espa`), y Windows 2000 Professional / Windows XP están
disponibles en los canales de licencia OEM y Retail originales (consulta la
tabla de medios más arriba).

¿Quieres una instalación de Windows más segura y minimalista, pero oficial de
Microsoft? Descarga la versión LTSC de Windows. Incluye mucho menos bloatware y
soporta el modo de telemetría ["Security"](https://learn.microsoft.com/es-es/windows/privacy/configure-windows-diagnostic-data-in-your-organization#diagnostic-data-settings)
de Microsoft (además de soporte a largo plazo).

### Ediciones IoT Enterprise

Windows **IoT Enterprise** es la edición que Microsoft distribuye para
dispositivos dedicados (cajeros automáticos, kioscos, cartelería digital,
equipos médicos, clientes ligeros). Es el mismo SO que Enterprise pero con
**requisitos de hardware relajados** — TPM, Secure Boot, UEFI y 4 GB de RAM
*no* son obligatorios — y, en las versiones LTSC, hasta **10 años** de
actualizaciones de seguridad. Mido ofrece las ISOs completas (no de evaluación)
en inglés:

| Argumento | Producto | Arquitectura | Fin de soporte |
|---|---|---|---|
| `win11x64-iot-enterprise-ltsc-2024` | Windows 11 IoT Enterprise LTSC 2024 | x64 | oct 2034 |
| `win11x64-iot-enterprise-26h2` | Windows 11 IoT Enterprise 26H2 (canal anual) | x64 | según canal anual |
| `win10x64-iot-enterprise-22h2` | Windows 10 IoT Enterprise 22H2 (canal anual) | x64 | ESU de Windows 10 |
| `win10x64-iot-enterprise-ltsc-2021` | Windows 10 IoT Enterprise LTSC 2021 | x64 | 13-01-2032 |
| `win10x64-iot-enterprise-ltsc-2019` | Windows 10 IoT Enterprise LTSC 2019 | x64 | 09-01-2029 |
| `win10x86-iot-enterprise-ltsc-2019` | Windows 10 IoT Enterprise LTSC 2019 | x86 (32 bits) | 09-01-2029 |

> **Sobre la disponibilidad de 32 bits:** Microsoft solo publicó una ISO x86
> (32 bits) para **IoT Enterprise LTSC 2019**. El Windows 10 IoT Enterprise 22H2
> (canal anual) y el más reciente IoT Enterprise LTSC 2021 existen **solo en
> x64** (y arm64), por lo que no hay ISO de 32 bits para ellos.

> **Windows 8.1 claves de configuración**

> Las siguientes claves de configuración se pueden usar durante la instalación
> de Windows 8.1 para avanzar más allá de la pantalla de configuración, pero **no
> activan Windows**:

> - **Windows 8.1 Enterprise (x64):** `NF3MJ-Q9W3X-7Y9K3-RJR8C-3X3CQ`
> - **Windows 8.1 Enterprise (x86 32-bit):** `KJYVW-2R2YX-2V9Y2-T8YV3-WRHYD`
> - **Windows 8.1 Pro (x64):** `GCRJD-8NW9H-F2HCX-Y66R6-C8BMC`
> - **Windows 8.1 Pro (x86 32-bit):** `W83YN-4R2Y3-2FWY4-T92JY-W3YXK`
> - **Windows 8.1 N (x64):** `MWMSY-FVGGT-6X7JK-PPMRW-TRT0D`
> - **Windows 8.1 N (x86 32-bit):** `VBN20-8R2YX-7WJ4C-YJJ26-G3YXK`

> **Importante:** Estas son claves de licencia por volumen que permiten que la
> instalación finalice. **No** proporcionan una copia de Windows con licencia
> activada. Para activar, debe usar una clave de producto genuina o una licencia
> digital.

> **Windows Embedded claves de configuración**

> Las siguientes claves de configuración se pueden usar durante la instalación
> de las ediciones Windows Embedded para avanzar más allá de la pantalla de
> configuración, pero **no activan Windows**:

> **Windows Embedded 8.1 Industry**

> - **Windows Embedded 8.1 Industry Pro:** `NMMPB-38DD4-R2823-62W8D-VXKJB`
> - **Windows Embedded 8.1 Industry Enterprise:** `FNFKF-PWTVT-9RC8H-32HB2-JB34X`
> - **Windows Embedded 8.1 Industry (ISO de evaluación de 180 días):** `N3QJR-YCWKK-RVJGK-GQFMX-T82BF`

> **Windows Embedded 8 Industry**

> - **Windows Embedded 8 Industry Professional:** `RYXVT-BNQG7-VD29F-DBMRY-HT73M`
> - **Windows Embedded 8 Industry Enterprise:** `NKB3R-R2F8T-3XCDP-7Q2KW-XWYQ2`

> **Windows Embedded 8 Standard**

> - **Imagen de tiempo de ejecución de Windows Embedded 8 Standard (clave de evaluación de 180 días):** `MPVW4-JNF4W-MGM8P-G2WYY-CWDFY`
> - **Toolkit de Windows Embedded 8 Standard — Image Configuration Editor (también licencia el toolkit a perpetuidad):** `D9XDH-78JX9-2KJG8-K7CY9-KF2Q3`

> **Nota:** Microsoft nunca definió una clave de configuración de cliente KMS
> (GVLK) para Windows Embedded 8 Standard, por lo que se proporcionan en su
> lugar las claves de evaluación y de toolkit anteriores. Todas estas claves
> solo permiten que la instalación continúe; **no** activan Windows. Para
> activar, use una clave de producto genuina.

### Ediciones Enterprise LTSC y LTSB

Mido también ofrece las ISOs **Enterprise** completas (no de evaluación) de largo
plazo, en inglés y español (de España y de México cuando Microsoft las publicó).
Son las mismas ediciones LTSC/LTSB que las descargas "Evaluation" anteriores,
pero con la licencia normal (sin caducidad):

| Argumento | Producto | Arquitectura | Fin de soporte |
|---|---|---|---|
| `win11x64-enterprise-ltsc-2024` | Windows 11 Enterprise LTSC 2024 | x64 | 09-10-2029 |
| `win11x64-enterprise-ltsc-2024-esp` / `-es-mx` | Windows 11 Enterprise LTSC 2024 (es-ES / es-MX) | x64 | 09-10-2029 |
| `win10x64-enterprise-ltsc-2021` | Windows 10 Enterprise LTSC 2021 | x64 | 12-01-2027 |
| `win10x64-enterprise-ltsc-2021-esp` / `-es-mx` | Windows 10 Enterprise LTSC 2021 (es-ES / es-MX) | x64 | 12-01-2027 |
| `win10x86-enterprise-ltsc-2021` | Windows 10 Enterprise LTSC 2021 | x86 (32 bits) | 12-01-2027 |
| `win10x86-enterprise-ltsc-2021-esp` / `-es-mx` | Windows 10 Enterprise LTSC 2021 (es-ES / es-MX) | x86 (32 bits) | 12-01-2027 |
| `win10x64-enterprise-ltsb-2016` | Windows 10 Enterprise LTSB 2016 (= "LTSC 2016") | x64 | 13-10-2026 |
| `win10x64-enterprise-ltsb-2016-esp` | Windows 10 Enterprise LTSB 2016 (español) | x64 | 13-10-2026 |
| `win10x86-enterprise-ltsb-2016` | Windows 10 Enterprise LTSB 2016 (= "LTSC 2016") | x86 (32 bits) | 13-10-2026 |
| `win10x86-enterprise-ltsb-2016-esp` | Windows 10 Enterprise LTSB 2016 (español) | x86 (32 bits) | 13-10-2026 |
| `win10x64-enterprise-ltsb-2015` | Windows 10 Enterprise LTSB 2015 | x64 | finalizó el 14-10-2025 |
| `win10x64-enterprise-ltsb-2015-esp` | Windows 10 Enterprise LTSB 2015 (español) | x64 | finalizó el 14-10-2025 |
| `win10x86-enterprise-ltsb-2015` | Windows 10 Enterprise LTSB 2015 | x86 (32 bits) | finalizó el 14-10-2025 |
| `win10x86-enterprise-ltsb-2015-esp` | Windows 10 Enterprise LTSB 2015 (español) | x86 (32 bits) | finalizó el 14-10-2025 |

> **"LTSC 2016" y "LTSB 2016" son el mismo producto.** Microsoft usó el nombre
> **LTSB** (Long-Term Servicing *Branch*) para las versiones de 2015 y 2016 y lo
> renombró a **LTSC** (Long-Term Servicing *Channel*) con la versión de 2019, por
> lo que la ISO de 2016 aparece con cualquiera de los dos nombres — nunca existió
> un "Windows 10 LTSC 2016" aparte.
>
> **Sobre la disponibilidad de 32 bits:** todas las versiones LTSC/LTSB de
> Windows 10 anteriores incluyen ISOs x86 (32 bits) y x64. Windows 11 (incluida
> Enterprise LTSC 2024) es **solo x64/arm64** — no hay versión de 32 bits. El
> español de Windows 11 Enterprise LTSC 2024 existe como es-ES y es-MX, pero las
> ISOs de Windows 10 LTSB 2015/2016 solo tuvieron una única versión en español
> (es-ES), así que no se ofrece el argumento `-es-mx` para ellas.
>
> **IoT frente a Enterprise:** los argumentos `-iot-` son las ediciones IoT
> Enterprise (requisitos de hardware relajados); los de arriba son las ediciones
> Enterprise normales. Para la LTSC 2021, la variante IoT tiene soporte hasta el
> 13-01-2032, mientras que la Enterprise normal termina el 12-01-2027.

### Versión máxima de Office instalable

Microsoft Office tiene requisitos de sistema mucho más estrictos que el propio
Windows. La tabla siguiente muestra la **versión de Office más reciente que
Microsoft admite oficialmente en cada versión de Windows** — instalar algo más
nuevo queda bloqueado por el instalador o sin soporte:

| Versión de Windows | Office más reciente admitido | Notas |
|---|---|---|
| Windows 95 | **Office 2000** | Office 2000 requiere Windows 95 o posterior. |
| Windows 98 / Me / NT 4.0 | **Office XP (2002)** | Office XP requiere Windows 98/Me/NT 4.0 SP6a. Office 2003 necesita 2000 SP3/XP. |
| Windows 2000 | **Office 2003** | Requiere Windows 2000 SP3. Office 2007 necesita XP SP2/Vista. |
| Windows XP | **Office 2010** | Última versión compatible con XP SP3; Office 2013+ requieren Windows 7. |
| Windows Vista | **Office 2010** | Última versión compatible con Vista SP2; Office 2013+ requieren Windows 7. |
| Windows 7 | **Office 2016** | Office 2019+ requieren oficialmente Windows 10. Microsoft 365 funcionó en 7 hasta ene 2023. |
| Windows 8 | **Office 2013** | Office 2016 requiere Windows 8.1+, por lo que Windows 8 queda descartado. |
| Windows 8.1 | **Office 2016** | Microsoft 365 funcionó en 8.1 hasta ene 2023. |
| Windows 10 LTSB 2015 | **Office 2016** | Office 2019/2021/LTSC 2024 no admiten las versiones LTSB 2015/2016. |
| Windows 10 LTSB 2016 | **Office 2016** | Office 2019/2021/LTSC 2024 no admiten las versiones LTSB 2015/2016. |
| Windows 10 LTSC 2019 | **Office LTSC 2024** | También Office 2019, Office LTSC 2021 y Microsoft 365. |
| Windows 10 LTSC 2021 | **Office LTSC 2024** | También Office 2019, Office LTSC 2021 y Microsoft 365. |
| Windows 10 (22H2, Home/Pro/Enterprise) | **Office 2024 / Microsoft 365** | Office **LTSC** 2024 *no* es compatible con 22H2 — usa **Office 2024** normal. |
| Windows 11 (incl. LTSC 2024) | **Office LTSC 2024 / Office 2024 / Microsoft 365** | Cualquier versión actual de Office. |
| Windows Server 2016 | **Office 2016** | El Server correspondiente a su generación de cliente. |
| Windows Server 2019 | **Office 2019 / LTSC 2021** | Server 2019 aparece en la lista de Office 2019. |
| Windows Server 2022 / 2025 | **Office LTSC 2024** | Office LTSC 2024 admite Server 2022 y 2025. |

> **Arquitectura:** Office de 64 bits apareció con **Office 2010**; Office 2003 y
> 2007 son solo de 32 bits. Office de 32 bits sigue siendo la opción recomendada
> por compatibilidad con complementos — instala Office de 64 bits solo si lo
> necesitas (archivos de Excel/PowerPoint muy grandes, >2 GB de memoria por
> aplicación o 4K+). Office de 64 bits requiere Windows de 64 bits.
>
> **Instalar un Office más nuevo** de lo indicado a veces es posible con trucos
> (o con un kernel extendido — véase más abajo), pero no tiene soporte y puede
> romper partes de la suite.
>
> **Las ediciones Server** siguen la generación de cliente en la que se basan:
> Server 2008/2008 R2 (era Vista/7) → Office 2010/2013, Server 2012/2012 R2
> (era 8/8.1) → Office 2013/2016, Server 2016 → Office 2016, Server 2019 →
> Office 2019, Server 2022/2025 → Office LTSC 2024.

## Activación de producto: se elimina la activación telefónica y se sustituye por activación por internet

Windows NT 3.1, 3.5 y 3.51 (y todos los medios de este proyecto anteriores a
Windows XP) **no tienen ningún sistema de activación de producto**. Microsoft
introdujo la activación de producto con Windows XP y Office XP en 2001, y más
tarde la usó en Windows Vista, 7, 8.1, 10, 11, la línea Windows Server y
Microsoft Office.

Microsoft ha **suprimido el antiguo sistema de activación telefónica** y lo ha
**sustituido por un sistema de activación por internet**: el **Product
Activation Portal**. A partir del **3 de diciembre de 2025** la automatización
tradicional de activación de producto por teléfono pasó del teléfono a internet.
Si llamas al antiguo número de activación ahora escucharás una grabación que te
remite al portal online. La activación sin conexión sigue siendo compatible:
solo ha cambiado la forma de obtener el *Confirmation ID* (un portal web en
lugar del sistema telefónico automático).

Pasos de la nueva activación por internet:

1. En el equipo que necesita activarse, abre el diálogo de activación de Windows
   y elige **Activar por teléfono** (o ejecuta `SLUI 04`) para mostrar el
   **Installation ID**. El equipo puede permanecer sin conexión: anota el ID.
2. Desde **cualquier otro dispositivo con acceso a internet**, abre el
   **Product Activation Portal**: <https://visualsupport.microsoft.com> (enlace
   corto: `aka.ms/aoh`).
3. Completa el CAPTCHA, selecciona **Proceed to Sign In** e inicia sesión con
   una cuenta compatible (cuenta personal de Microsoft, cuenta de trabajo o
   educativa, Microsoft Entra ID o un inquilino de Azure Government). La cuenta
   solo sirve para acceder de forma segura al portal y **no** está vinculada a
   la licencia del producto.
4. Elige **Activate a Microsoft product** e introduce el **Installation ID** del
   paso 1.
5. El portal devuelve un **Confirmation ID**.
6. Escribe el **Confirmation ID** en el diálogo de activación del equipo sin
   conexión para completar la activación.

Windows 10 Pro for Workstations y Windows 10/11 Pro Education deben activarse
por internet y no admiten el flujo sin conexión. Los clientes de licencias por
volumen pueden usar la Volume Activation Management Tool (VAMT) para la
activación proxy o KMS / activación basada en Active Directory.

## NewShell ("Shell Technology Preview") para Windows NT 3.51

El escritorio retro de Windows NT 3.1/3.5/3.51 es el antiguo shell de Program
Manager/File Manager. En 1995 Microsoft publicó una renovación del shell llamada
**NewShell** (también conocida como **Shell Technology Preview**) que porta el
shell Explorer de Windows 95 —barra de tareas, menú Inicio y escritorio— a
**Windows NT 3.51**. Es una beta cuyo único objetivo era mostrar cómo sería el
futuro Windows NT 4.0, y es un parche muy popular para dar a NT clásico un
escritorio usable.

> **Importante:** NewShell se produjo **solo para Windows NT 3.51**. **No**
> funciona en Windows NT 3.1 ni en el Windows NT 3.5 original (build 807). Sí
> existió una vista previa temprana del "shell de Chicago" con el Windows NT 3.5
> build 854 filtrado, que está archivada por separado (ver abajo).

Descargas:

- **Windows NT 3.51 NewShell / Shell Technology Preview** (las dos versiones
  públicas: 26 de mayo de 1995 y el "Shell Technology Preview Update" del 8 de
  agosto de 1995): <https://winworldpc.com/product/newshell/beta>
- **Windows NT 3.5 build 854 NewShell** (vista previa temprana, `WINSRV.DLL`
  completo): <https://archive.org/details/newshell.3.50.854>
  — descarga directa:
  <https://archive.org/download/newshell.3.50.854/NT_854_newshell.zip>

Instalación del **Shell Technology Preview de Windows NT 3.51**:

1. Instala primero Windows NT 3.51 Workstation (o Server) y, recomendado, aplica
   el último service pack de NT 3.51.
2. Descarga el archivo de NewShell y descomprímelo (contiene los archivos
   actualizados del shell Explorer).
3. Lee el `readme.wri` incluido en el archivo: indica los comandos de copia
   exactos para cada versión. En resumen, la actualización hace copia de
   seguridad del shell original, copia los nuevos archivos del shell Explorer
   (por ejemplo `shell32.dll`, `explorer.exe`, `comctl32.dll`, `shdocvw.dll`)
   sobre `%SystemRoot%\System32`, actualiza el registro y sustituye Program
   Manager / File Manager por el nuevo shell.
4. Haz una instantánea o copia de seguridad del sistema antes de aplicarlo, ya
   que NewShell es una beta sin soporte.
5. Reinicia. Deberías tener la barra de tareas y el menú Inicio estilo
   Windows 95.

Instalación del **NewShell de Windows NT 3.5 build 854**:

1. Copia los directorios `IDW`, `MSTOOLS` y `UI` de la carpeta `NEWSHELL`/`GUI`
   del medio al directorio de Windows (normalmente `\WINNT35`).
2. Abre Panel de control → **Sistema** y añade
   `%SystemRoot%\idw;%SystemRoot%\mstools;%SystemRoot%\ui` a la variable de
   entorno `Path`.
3. Reinicia.

## Windows Update en Windows sin soporte

Descargar los medios es solo la mitad: una vez instalado Windows hay que
actualizarlo. Microsoft ha ido cerrando los servicios de los que dependen las
versiones antiguas, por lo que una instalación nueva puede no encontrar
actualizaciones en absoluto.

- **Windows Vista y anteriores (incluido Windows Server 2008 y anteriores).** El
  servicio clásico de **Windows Update / Microsoft Update** está cerrado de forma
  permanente. Estos sistemas ya no pueden acceder a los servidores de
  actualizaciones de Microsoft por sí solos.
- **Windows 7 / Windows Server 2008 R2.** El **Microsoft Update para "otros
  productos de Microsoft"** (Office, etc.) está cerrado y, además, las propias
  actualizaciones de Windows solo funcionan tras instalar una serie de parches
  requisito. El proyecto comunitario *Legacy Update* restaura ambos.
- **Windows 8.1 / Windows Server 2012 R2.** Windows Update normal todavía
  funciona, pero estas versiones están sin soporte, así que solo las herramientas
  de la comunidad que siguen ofreciendo la lista completa de actualizaciones.

### Proyectos comunitarios de recuperación

Como Microsoft retiró los servicios originales, la comunidad los ha reconstruido:

- **Legacy Update** — <https://legacyupdate.net/> — la opción recomendada para
  **Windows 2000, XP, Vista, 7, 8, 8.1, 10 y 11** y las versiones equivalentes de
  Windows Server (x86, x64, Itanium y ARM64). Redirige el protocolo moderno
  Windows Update v6 a los servidores oficiales de Microsoft e instala
  automáticamente los parches requisito que faltan en instalaciones nuevas
  (compatibilidad con firma de código SHA-2 `KB4474419`/`KB4490628`, el update de
  la pila de servicio y más).
- **Windows Update Restored** — <https://windowsupdaterestored.com/> — el proyecto
  hermano que revive los sitios **originales** de Windows Update y Microsoft
  Update para **Windows 95, NT 4.0, 98, Me, 2000 y XP**. Requiere **Internet
  Explorer 4.0–6.0** (IE 5.5 a 800×600 para el aspecto clásico) y está pensado
  para esas versiones antiguas.

> Ambos proyectos son no oficiales, gestionados por la comunidad y no están
> afiliados a Microsoft. Son la única forma realista de actualizar estos sistemas
> hoy. Úsalos en una máquina que puedas permitirte reinstalar y mantén copias de
> seguridad. Incluso totalmente parcheados, estos sistemas siguen siendo un riesgo
> de seguridad: prioriza un sistema con soporte cuando sea posible.

### Windows 7: habilitar actualizaciones para "otros productos de Microsoft"

En una instalación nueva de Windows 7 suele faltar la opción **"Obtener
actualizaciones para otros productos de Microsoft"** (Microsoft Update), por lo
que Windows Update solo ofrece actualizaciones de Windows. Para restaurar el
Microsoft Update completo:

1. Instala primero los parches requisito. Lo más fácil es ejecutar **Legacy
   Update**, que detecta e instala todo lo que falta. De forma manual necesitas
   `KB4474419` (compatibilidad con firma de código SHA-2) y `KB4490628` (pila de
   servicio), seguidos de un reinicio y del último update de la pila de servicio.
2. Instala **Office 2010** (cualquier edición). Su instalación instala el agente
   **Microsoft Update** más reciente, que vuelve a registrar el origen de
   actualizaciones "otros productos de Microsoft" que necesita el Windows 7
   moderno.
3. Reinicia y, en Internet Explorer, visita <http://update.microsoft.com> y/o
   abre **Windows Update** y haz clic en **Find out more** junto a *"Get updates
   for other Microsoft products"* para aceptar. (Si la opción sigue oculta, abre
   una vez una aplicación de Office como Word y acepta el aviso de
   "actualizaciones recomendadas").
4. Ve a **Windows Update → Cambiar configuración** y confirma que ha vuelto la
   sección *Microsoft Update*.

> Si Office 2010 se instala **antes** de ejecutar Legacy Update, la búsqueda de
> actualizaciones puede quedarse colgada para siempre — es un problema conocido
> de Legacy Update. Ejecuta Legacy Update primero.

### Cómo buscar e instalar actualizaciones, paso a paso

**Windows modernos (8.1 / 10 / 11) que aún sirve Windows Update:**

1. Abre **Configuración → Actualización y seguridad → Windows Update**.
2. Pulsa **Buscar actualizaciones** y deja que descargue e instale.
3. Para actualizaciones opcionales y de controladores, pulsa **Ver actualizaciones
   opcionales** (Windows 10/11) y selecciona lo que necesites.
4. Reinicia y repite hasta que no aparezcan más actualizaciones.

**Windows antiguos (2000 – 8.1) con Legacy Update:**

1. Descarga `LegacyUpdateSetup.exe` de <https://legacyupdate.net/> y ejecútalo en
   la máquina destino (Windows 2000/XP pueden necesitar el workaround documentado
   y el último Internet Explorer primero).
2. Acepta el aviso para instalar los **parches requisito**. Legacy Update detecta
   e instala todo lo que falta y reinicia cuando es necesario.
3. Abre **Inicio → Todos los programas → Legacy Update** (o el enlace **Install
   Updates** del sitio) para cargar la página clásica de Windows Update.
4. Pulsa **Express** para instalar todas las actualizaciones críticas/de seguridad
   automáticamente, o **Custom** para elegir actualizaciones, controladores y
   software opcional.
5. Revisa la lista, pulsa **Install Updates**, acepta las licencias cuando se te
   pida y deja que instale.
6. Reinicia cuando se te pida y **vuelve a buscar hasta que no aparezcan
   actualizaciones nuevas**. La primera búsqueda en Vista/7 puede tardar 30–60
   minutos — ten paciencia.

**Windows muy antiguos (95 / 98 / Me / NT 4.0) con Windows Update Restored:**

1. En la máquina destino abre `windowsupdaterestored.com` en **Internet Explorer
   4.0–6.0**.
2. Sigue el **Prerequisites Installer** del sitio (o los pasos manuales); el sitio
   carga el control ActiveX original de Microsoft que busca actualizaciones.
3. Usa **Windows Update** para actualizaciones del sistema y **Microsoft Update**
   para Office y otros productos de Microsoft.
4. Instala las actualizaciones ofrecidas, reinicia y vuelve a buscar hasta que la
   lista quede vacía.

**Alternativa manual:** casi todas las actualizaciones también se publican en el
**Catálogo de Microsoft Update** (<https://catalog.update.microsoft.com/>). Busca
por número de KB, descarga el `.msu`/`.cab` e instálalo haciendo doble clic (o con
`wusa`/`dism`). Es la forma más fiable de parchear una máquina que no puede
acceder a ningún servicio de actualizaciones.

## Kernels extendidos: ejecutar software más nuevo en Windows antiguos

Un **kernel extendido** (también llamado *paquete de extensión de API*) es un
parche no oficial que **añade APIs de Windows más recientes a una instalación
antigua de Windows**. En lugar de emular Windows, modifica el kernel real y las
DLL del sistema (`kernel32.dll`, `ntdll.dll`, `user32.dll`, `advapi32.dll`, …)
para que los programas escritos para una versión posterior de Windows encuentren
las funciones que esperan y arranquen con normalidad. El resultado es una
instalación de Windows auténtica y nativa que puede ejecutar software de una o
varias generaciones por delante.

### Proyectos principales

| Proyecto | SO objetivo | Añade compatibilidad con | Notas |
|---|---|---|---|
| **KernelEx** | Windows 98 / Me | Aplicaciones de Windows 2000/XP | Código abierto; necesita el runtime `unicows`. |
| **Windows 2000 Extended Kernel** (BlackWingCat) | Windows 2000 | Aplicaciones de Windows XP + software moderno (apps de VS2013, Media Player 11, navegadores modernos) | Funciona en CPU sin SSE2; se instala como un service pack. |
| **One-Core-API** (shorthorn-project) | Windows XP SP3, XP x64 SP2, Server 2003 SP2 | APIs de Vista/7/8/10 — Chromium/Firefox modernos, Steam, VS Code, .NET hasta 4.8, juegos con DirectX 9–11 mediante un wrapper `wined3d`, Office 2013/2016 | Basado en ReactOS; en desarrollo activo. |
| **VxKex / VxKex NEXT** | Windows 7 (+ Server 2008 R2) | Aplicaciones exclusivas de Windows 8/8.1/10/11 (Chromium, Firefox, Blender, Python, VSCode, Spotify, …) | Opt-in por aplicación; parchea la tabla de importaciones de cada app. |

### Ventajas

- **Rendimiento nativo y soporte total de controladores.** La aplicación se
  ejecuta sobre el kernel NT auténtico con controladores de hardware reales, así
  que no hay sobrecarga de emulación de CPU ni capa de traducción de GPU.
- **Efecto en todo el sistema.** Una vez instalado, se beneficia *cualquier*
  programa compatible — sin configuración por aplicación (salvo VxKex, que es por
  aplicación por diseño).
- **Se ejecuta sobre Windows real ya con licencia.** Conservas tu instalación,
  archivos y licencias.
- **A menudo es la única forma de ejecutar una app moderna en hardware antiguo**
  (p. ej. Windows 2000 en un Pentium III sin SSE2).

### Inconvenientes

- **No oficial y sin soporte.** Una actualización defectuosa puede dejar el
  sistema sin arrancar; haz siempre una imagen/copia de seguridad primero (los
  kernels extendidos también pueden entrar en conflicto con Windows Update).
- **Seguridad.** Ejecutas código más nuevo y complejo sobre un SO que ya no
  recibe correcciones de seguridad — no lo uses en una máquina expuesta a la red.
- **Incompleto.** Solo se implementa un subconjunto de APIs; algunas apps siguen
  fallando y ciertas funciones (impresión, DRM, aceleración por hardware) pueden
  faltar o ser inestables.
- **El antivirus/EDR puede marcarlo** y rompe la integridad de los archivos del
  sistema (`sfc`/`dism` se quejarán).
- **Carga de mantenimiento.** Debes seguir las versiones de un proyecto de
  terceros.

### Kernel extendido frente a Wine

| Aspecto | Kernel extendido | Wine |
|---|---|---|
| Qué es | Parche sobre una instalación de Windows **real** | **Capa de compatibilidad en espacio de usuario** que reimplementa la API de Windows en Linux/macOS/BSD |
| SO anfitrión | Windows auténtico (antiguo) | Linux/macOS/BSD (no necesita Windows) |
| Kernel | Modifica el kernel/DLL reales de NT | Se ejecuta como un proceso normal; sin cambios en el kernel |
| Rendimiento | Nativo (casi 100%) | Normalmente bueno, a veces menor; sin controladores reales de kernel |
| Controladores | Funcionan los **controladores reales** | **Sin** controladores de kernel; soporte de hardware limitado/emulado |
| Compatibilidad | Muy alta para la generación de Windows objetivo | Amplia pero irregular; suele necesitar ajustes/`winetricks` |
| Riesgo | Puede romper/corromper el SO; sin soporte | Aislado; eliminarlo es trivial |
| Licencia | Necesita una licencia de Windows | Gratis (Wine es código abierto) |
| Uso típico | Sacar apps modernas de hardware Windows antiguo | Ejecutar juegos/apps de Windows en Linux sin Windows |

En resumen: **Wine** es la opción más segura y portátil si estás en Linux y puedes
convivir con carencias de compatibilidad; un **kernel extendido** es la opción de
mayor rendimiento si apuestas por una instalación real de Windows antiguo y
quieres controladores nativos.

### Cómo instalarlo (ejemplos)

> Haz siempre una imagen completa del disco (o una instantánea de la VM) antes de
> instalar cualquier kernel extendido. Haz estas instalaciones sobre una
> instalación de Windows recién hecha.

**1. KernelEx (Windows 98 / Me)**

1. Instala primero el **Unofficial Service Pack** y el runtime **`unicows`**.
2. Descarga el instalador más reciente de KernelEx del proyecto y ejecútalo.
3. Reinicia. Luego haz clic derecho en cualquier `.exe` → **Propiedades →
   Compatibilidad** para elegir el modo de KernelEx de ese programa.

**2. Windows 2000 Extended Kernel (BlackWingCat)**

1. Instala **Windows 2000 SP4** + Update Rollup 1 y reinicia.
2. Descarga el paquete **Extended Kernel** más reciente (v3.0e o posterior).
3. Ejecuta el instalador como Administrador, acepta los avisos y **reinicia dos
   veces**.
4. Instala el runtime de Visual C++ 2013 que necesita para las apps modernas.

**3. One-Core-API (Windows XP / Server 2003)**

1. Instala **Windows XP SP3** (o XP x64 SP2 / Server 2003 SP2) con todas las
   actualizaciones.
2. Activa **Restaurar sistema** y crea un punto de restauración primero.
3. Descarga la versión más reciente de **One-Core-API** (instalador `ocapi_*`).
4. Haz clic derecho en el instalador → **Ejecutar como administrador**.
5. Reinicia. Para juegos con DirectX 9+, copia las DLL de `wined3d` incluidas en
   la carpeta del juego y ajusta el **modo de compatibilidad** de la app a
   Windows Vista/7 cuando se solicite.

**4. VxKex (Windows 7 / Server 2008 R2)**

1. Instala **Windows 7 SP1** con las actualizaciones SHA-2 y (para apps modernas)
   el Universal C Runtime.
2. Descarga y ejecuta el instalador de **VxKex** (Administrador) y reinicia.
3. Haz clic derecho en el programa objetivo → **Propiedades → pestaña VxKex** →
   marca **Enable VxKex for this program**.
4. Si la app sigue sin arrancar, ajusta su **modo de compatibilidad** a
   Windows 8/10 en la misma ventana de Propiedades (algunas apps también
   necesitan un "spoof" de versión, configurable en **VxKex Global Settings**).

## Base de conocimiento / solución de problemas

- **"Sentinel marked this request as rejected"** — el sistema antiabuso de
  Microsoft bloqueó la petición según la reputación de tu IP. Espera 24–48 horas,
  usa una VPN o descarga manualmente desde la página oficial. **No** es un bug de
  Mido; el autor de Fido documenta el mismo comportamiento. Los argumentos
  `win10x64-esp`, `win10x64-es-mx`, `win11x64-esp` y `win11x64-es-mx` evitan este
  problema porque recurren automáticamente a una copia de archive.org.
- **Respaldo archive.org** — las ISOs en español dedicadas intentan primero la
  descarga oficial de Microsoft y, si Sentinel la rechaza, descargan una copia
  idéntica desde `archive.org` (más lento que la CDN de Microsoft). Mido reintenta
  y reanuda automáticamente.
- **Windows 8.1 (`win81x64`) falla con HTTP 404** — Microsoft retiró la descarga
  automática de Windows 8.1. Usa `win81x64-enterprise-eval`.
- **Windows 7 va lento** — proviene de `web.archive.org`, mucho más lento y menos
  fiable que la CDN de Microsoft. Mido reintenta y reanuda automáticamente.
- **Windows 10 x86 (inglés, español)** — se intenta primero la descarga oficial;
  el respaldo de `archive.org` (compilaciones Windows 10 22H2) puede ser más
  lento que la CDN de Microsoft. Mido reintenta y reanuda automáticamente.
- **Windows 8.1 Enterprise en español** — proviene de `archive.org`, que puede ser
  más lento que la CDN de Microsoft. Mido reintenta y reanuda automáticamente.
- **Windows Server 2008 R2 en español** — proviene de `archive.org`, que puede ser
  más lento que la CDN de Microsoft. Mido reintenta y reanuda automáticamente.
- **Windows Server 2003 / Windows 2000 Server** — provienen de `archive.org`, que
  puede ser más lento que la CDN de Microsoft. Mido reintenta y reanuda
  automáticamente.
- **Windows Vista en español** — proviene de `archive.org`, que puede ser más
  lento que la CDN de Microsoft. Mido reintenta y reanuda automáticamente.
- **Medios retro (`win30`, `win31`, `wfw31`, `win311`/`wfw311`, `win95`,
  `win98`, `winme`, `winnt31`, `winnt35`, `winnt351`, `winnt40`, `backoffice`,
  `winframe`, además de las españolas `win30-espa`, `win31-espa`, `wfw31-espa`,
  `win311-espa`, `wfw311-espa`, `win95-espa`, `win98-espa`, `winme-espa`)** —
  provienen de `archive.org`, que puede ser más lento que la CDN de Microsoft.
  Algunas de las entradas más antiguas vienen como imágenes de disquete en
  ZIP/RAR/7z en lugar de ISOs. Mido reintenta y reanuda automáticamente.
- **Enterprise/Server "no download link"** — Microsoft cambia periódicamente las
  páginas del Evaluation Center. Abre un issue con la versión afectada.

## ¿Quieres ahorrar más tiempo?

Echa un vistazo al script `create-media.sh` de
[Qvm-Create-Windows-Qube](https://github.com/ElliotKillick/qvm-create-windows-qube/tree/master/windows).

## ¿Qué tan seguro es *realmente*?

Mido es software razonablemente seguro. Se aprovecha cada oportunidad para
reducir la superficie de ataque. Los datos no confiables se tratan como tales
con pasos de validación adecuados. Siempre se usa la versión más alta posible de
TLS (hasta TLS 1.3).

- Sin navegador web (Chromium headless ejecutando JavaScript), lo que reduce la
  superficie de ataque en *muchos* órdenes de magnitud.
- Se fuerza TLS 1.2 o TLS 1.3 (esta última cuando los servidores de Microsoft la
  soportan).
- Compatible con POSIX sh y cambia automáticamente a un shell más seguro (Dash)
  si está disponible.
- Se fuerza HTTP/1.1 para evitar los frecuentes [bugs de curl en HTTP/2 y HTTP/3](https://github.com/curl/curl/issues?q=is%3Aissue+label%3Acrash).
- Solo se usan builtins del shell para la funcionalidad más crítica.
- Se verifica el checksum SHA-256 de cada ISO descargada.

## Pruebas

```sh
sh -n Mido.sh          # comprobación de sintaxis
shellcheck -s sh Mido.sh
```

## Licencia

MIT License - Copyright (C) 2024 Elliot Killick <contact@elliotkillick.com>
