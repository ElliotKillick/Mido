# Mido 2026 — Documentación técnica

<p align="center">
    <a href="TECHNICAL.md">English</a> · <a href="TECHNICAL.es.md">Español</a> ·
    <a href="../README.es.md">README</a>
</p>

Este documento explica cómo funciona `Mido.sh` internamente: los endpoints de
Microsoft con los que habla, el handshake antiabuso, el motor de descarga, la
verificación de integridad, el soporte de idiomas y las convenciones de shell
utilizadas. Está dirigido a mantenedores y a cualquiera que quiera auditar el
script.

## Índice

1. [Requisitos](#requisitos)
2. [Estructura del repositorio](#estructura-del-repositorio)
3. [Flujo general](#flujo-general)
4. [Fuentes de datos](#fuentes-de-datos)
5. [La API JSON de consumidor](#la-api-json-de-consumidor)
6. [El handshake de Sentinel](#el-handshake-de-sentinel)
7. [Soporte de idiomas](#soporte-de-idiomas)
8. [Motor de descarga (`scurl_file`)](#motor-de-descarga-scurl_file)
9. [Verificación de integridad](#verificación-de-integridad)
10. [Manejo de errores y códigos de salida](#manejo-de-errores-y-códigos-de-salida)
11. [Constantes y configuración](#constantes-y-configuración)
12. [Propiedades de seguridad](#propiedades-de-seguridad)
13. [Solución de problemas](#solución-de-problemas)
14. [Pruebas](#pruebas)
15. [Guía de mantenimiento](#guía-de-mantenimiento)

## Requisitos

- Un shell POSIX (`sh`; en Debian/Ubuntu se prefiere `dash` y el script se
  reejecuta bajo Dash cuando está disponible).
- `curl` (con soporte de TLS 1.3 para la mejor experiencia).
- Coreutils: `grep`, `sed`, `tr`, `cut`, `head`, `tail`, `sha256sum`, `mv`,
  `dirname`, `fold`, `kill`, `date`.
- Opcional: `uuidgen` en sistemas sin `/proc/sys/kernel/random/uuid`.

## Estructura del repositorio

```
.
├── Mido.sh               # todo el programa
├── Mido.bat              # wrapper por lotes de Windows (ejecuta Mido.sh vía WSL)
├── Mido.ps1              # wrapper PowerShell de Windows (ejecuta Mido.sh vía WSL)
├── README.md             # documentación de usuario (inglés)
├── README.es.md          # documentación de usuario (español)
├── docs/
│   ├── TECHNICAL.md      # documentación técnica (inglés)
│   └── TECHNICAL.es.md   # este archivo
├── assets/               # logo, GIF de demo, capturas
└── LICENSE               # MIT
```

## Flujo general

```
parse_args "$@"
   └─ valida nombres de medios, expande "all", elimina duplicados
download_media
   └─ para cada medio: llama a la función de descarga correspondiente
verify_media
   └─ verifica cada archivo *.UNVERIFIED y lo renombra al nombre final
ending_summary
   └─ informa fallos y elige el código de salida del proceso
```

`set -ef` se activa justo antes de `parse_args`, de modo que cualquier fallo de
comando no controlado aborta el script y el trap `EXIT` (`handle_exit`) avisa de
archivos parciales. `IFS` se fija a un solo espacio, por lo que los nombres de
ISO no pueden contener espacios.

## Fuentes de datos

Las distintas familias de medios se obtienen de formas diferentes:

| Familia | Fuente | Autenticación |
|---|---|---|
| `win10x64`, `win11x64` | API JSON de consumidor | Handshake de Sentinel |
| `win10x64-esp`, `win10x64-es-mx`, `win11x64-esp`, `win11x64-es-mx` | API JSON de consumidor primero, respaldo de `archive.org` | Handshake de Sentinel (oficial) |
| `win10x86` (x86 inglés y español), `win10x86-esp`, `win10x86-es-mx` | API JSON de consumidor primero, respaldo de `archive.org` | Handshake de Sentinel (oficial) |
| `win81x64` | API JSON de consumidor | Retirada (HTTP 404) |
| `win81x64-ent-32-espa`, `win81x64-ent-64-esp` | instantáneas de `archive.org` | ninguna |
| `win2008r2-espa` | instantánea de `archive.org` de la ISO de evaluación oficial en español | ninguna |
| `win2008-server-x64`, `win2008-server-x64-espa`, `win2008-server-x86`, `win2008-server-x86-espa` | instantáneas de `archive.org` (ISOs oficiales SP2 AIO) | ninguna |
| `win2003-server`, `win2003-server-espa`, `win2003-server-x64`, `win2003-server-x64-espa`, `win2000-server`, `win2000-server-espa` | instantáneas de `archive.org` (ISOs heredadas retail/eval) | ninguna |
| `win2000-datacenter`, `win2000-datacenter-sp4` | instantáneas de `archive.org` (Windows 2000 Datacenter Server, RTM OEM con SP1 y SP4) | ninguna |
| `win2000-pro`, `win2000-pro-espa` | instantáneas de `archive.org` (Windows 2000 Professional) | ninguna |
| `win2000-pro-oem`, `win2000-pro-retail`, `win2000-pro-oem-espa`, `win2000-pro-retail-espa` | instantáneas de `archive.org` (Windows 2000 Professional, canales OEM/Retail, inglés y español) | ninguna |
| `win-xp-pro`, `win-xp-pro-espa`, `win-xp-pro-32-espa` | instantáneas de `archive.org` (Windows XP Professional, inglés y español) | ninguna |
| `win-xp-home`, `win-xp-home-espa`, `win-xp-home-oem`, `win-xp-home-retail`, `win-xp-home-oem-espa`, `win-xp-home-retail-espa`, `win-xp-pro-oem`, `win-xp-pro-retail`, `win-xp-pro-oem-espa`, `win-xp-pro-retail-espa` | instantáneas de `archive.org` (Windows XP Home/Professional, canales OEM/Retail, inglés y español) | ninguna |
| `win10x64-enterprise-eval`, `win10x86-enterprise-eval`, `win11x64-enterprise-eval`, `win10x64-enterprise-ltsc-eval`, `win11x64-enterprise-ltsc-eval` | instantáneas de `archive.org` | ninguna |
| `win11x64-iot-enterprise-ltsc-eval` | URL directa de `software-static.download.prss.microsoft.com` | ninguna |
| `win11x64-iot-enterprise-26h2` | instantánea de `archive.org` (Windows 11 IoT Enterprise, canal anual 26H2, solo inglés) | ninguna |
| `win11x64-iot-enterprise-ltsc-2024` | instantánea de `archive.org` (ISO oficial completa de Windows 11 IoT Enterprise LTSC 2024, inglés x64) | ninguna |
| `win10x64-iot-enterprise-22h2` | instantánea de `archive.org` (Windows 10 IoT Enterprise 22H2, canal anual, inglés x64) | ninguna |
| `win10x64-iot-enterprise-ltsc-2021`, `win10x64-iot-enterprise-ltsc-2019`, `win10x86-iot-enterprise-ltsc-2019` | instantáneas de `archive.org` (ISOs oficiales completas de Windows 10 IoT Enterprise LTSC, inglés; 2021 solo x64, 2019 en x64 y x86) | ninguna |
| `win11x64-enterprise-ltsc-2024`, `win10x64-enterprise-ltsc-2021`, `win10x86-enterprise-ltsc-2021`, `win10x64-enterprise-ltsb-2016`, `win10x86-enterprise-ltsb-2016`, `win10x64-enterprise-ltsb-2015`, `win10x86-enterprise-ltsb-2015` | instantáneas de `archive.org` vía el item `massgrave.dev-windows-x64-and-x86-archive` (ISOs oficiales completas de Windows 11/10 Enterprise LTSC y LTSB, inglés; x64 y x86 donde Microsoft las distribuyó) | ninguna |
| `win11x64-enterprise-ltsc-2024-esp`, `win11x64-enterprise-ltsc-2024-es-mx`, `win10x64-enterprise-ltsc-2021-esp`, `win10x64-enterprise-ltsc-2021-es-mx`, `win10x86-enterprise-ltsc-2021-esp`, `win10x86-enterprise-ltsc-2021-es-mx` | instantáneas de `archive.org` (ISOs oficiales completas Enterprise LTSC en español; Win11 LTSC 2024 como es-ES y es-MX, Win10 LTSC 2021 como es-ES y es-MX, en x64 y x86) | ninguna |
| `win10x64-enterprise-ltsb-2016-esp`, `win10x86-enterprise-ltsb-2016-esp`, `win10x64-enterprise-ltsb-2015-esp`, `win10x86-enterprise-ltsb-2015-esp` | instantáneas de `archive.org` (ISOs oficiales completas de Windows 10 Enterprise LTSB 2015/2016 en español; Microsoft solo distribuyó una versión en español para estas, de ahí que solo sea es-ES) | ninguna |
| `win2012r2-eval` … `win2025-eval`, `win2012r2-essentials-eval`, `win2016-essentials-eval`, `win2019-essentials-eval`, `hyperv2012-eval`, `hyperv2012r2-eval`, `hyperv2016-eval`, `hyperv2019-eval` | HTML del Evaluation Center → redirección `go.microsoft.com/fwlink` | ninguna |
| `win81x64-enterprise-eval`, `win2008r2` | URL directa de `download.microsoft.com` | ninguna |
| `win2022-enterprise-64`, `win2022-datacenter-64` | instantáneas de `archive.org` (64-bit solo) | ninguna |
| `win2022-enterprise-64-esp`, `win2022-datacenter-64-esp` | instantáneas de `archive.org` español (64-bit solo) | ninguna |
| `win2025-enterprise-64`, `win2025-datacenter-64` | instantáneas de `archive.org` (64-bit solo) | ninguna |
| `win2025-enterprise-64-esp`, `win2025-datacenter-64-esp` | instantáneas de `archive.org` español (64-bit solo) | ninguna |
| `win7x64-ultimate` | instantánea de `web.archive.org` | ninguna |
| `win7x64-homepremium`, `win7x64-homepremium-esp` | instantáneas de `archive.org` (Windows 7 Home Premium) | ninguna |
| `win7x86-homepremium`, `win7x86-homepremium-esp` | instantáneas de `archive.org` (Windows 7 Home Premium) | ninguna |
| `win7x64-enterprise`, `win7x64-enterprise-esp` | instantáneas de `archive.org` (Windows 7 Enterprise) | ninguna |
| `win7x86-enterprise`, `win7x86-enterprise-esp` | instantáneas de `archive.org` (Windows 7 Enterprise) | ninguna |
| `win7x64-sp1`, `win7x86-sp1` | instantáneas de `archive.org` (Windows 7 SP1) | ninguna |
| `win-xp-pro-64` | instantánea de `archive.org` (Windows XP Professional x64 Edition SP2, inglés; Microsoft distribuyó x64 en inglés/japonés con paquetes MUI) | ninguna |
| `vista_x64_sp2`, `vista_x86_sp2`, `vista_es_x64_sp2`, `vista_es_x86_sp2` | instantáneas de `archive.org` (Windows Vista **Enterprise** SP2) | ninguna |
| `vista_x64_sp2_n`, `vista_x64_sp2_business_n`, `vista_x86_sp2_business_n` | instantáneas de `archive.org` (Windows Vista **N** SP2: N todo en uno x64 = Home Basic N + Business N, y Business N x64/x86; solo en inglés) | ninguna |
| `win30`, `win30-espa`, `win31`, `win31-espa`, `wfw31`, `wfw31-espa` | instantáneas de `archive.org` (ZIP de Windows 3.0, ZIP de Windows 3.0a en español, ISO de Windows 3.1, ISO de Windows 3.1 en español, RAR de Windows for Workgroups 3.1 compilación 014e, imágenes de disquete 7z de Windows for Workgroups 3.1 en español) | ninguna |
| `win311`, `win311-espa`, `wfw311`, `wfw311-espa`, `win95`, `win98`, `winme`, `winnt31`, `winnt35`, `winnt351`, `winnt40`, `win95-espa`, `win98-espa`, `winme-espa`, `backoffice`, `winframe` | instantáneas de `archive.org` (ISOs retro retail/OEM; ISO de Windows 3.11 / WfW 3.11 en inglés y español; 95/98/ME también en español; NT 3.1/3.5/3.51 Workstation, BackOffice SBS 4.0 y Citrix WinFrame 1.6) | ninguna |

> Las evaluaciones Enterprise y LTSC de Windows 10/11 se migraron desde el HTML
> (poco fiable) del Evaluation Center a ISOs archivadas en `archive.org`. La ruta
> `enterprise_eval_download` restante ahora solo la usan las evaluaciones Server,
> Server Essentials y Hyper-V (`win2012r2-eval` … `win2025-eval` y las entradas
> Essentials/Hyper-V).
>
> `win10x86-enterprise-eval` es la contraparte de 32 bits (x86) de
> `win10x64-enterprise-eval`: apunta a la ISO oficial de evaluación x86 de Windows
> 10 Enterprise LTSC 21H2 archivada en archive.org (item `Win10-EnterpriseLTSC-21H2`).
>
> `win11x64-iot-enterprise-26h2` cubre la versión de **canal anual** (build 26300)
> de Windows 11 IoT Enterprise, que Microsoft solo distribuye a OEM/VLSC — no hay
> ISO pública directa ni alternativa en español. La build archivada (item
> `windows-11-iot-enterprise-ltsc-2026-26h2`) es una ISO remezclada: el instalador
> clásico de 24H2 con el contenido de 26H2, no la ISO MSDN original.
> `win11x64-iot-enterprise-ltsc-2024` es la ISO completa (sin evaluación) oficial
> de Windows 11 IoT Enterprise LTSC 2024 (inglés x64, item
> `windows-11-iot-enterprise-ltsc-2024`).
>
> Las ISOs completas de Windows 10 IoT Enterprise (`win10x64-iot-enterprise-22h2`,
> `win10x64-iot-enterprise-ltsc-2021`, `win10x64-iot-enterprise-ltsc-2019` y
> `win10x86-iot-enterprise-ltsc-2019`) provienen del item de `archive.org`
> `massgrave.dev-windows-x64-and-x86-archive`, que refleja los nombres de archivo
> oficiales exactos de Microsoft (subrutas bajo `Windows/Windows 10/…`). Microsoft
> solo publicó una ISO **x86 (32 bits)** para la versión **LTSC 2019**, por lo que
> las entradas 22H2 y LTSC 2021 no tienen contraparte de 32 bits.
>
> Las ISOs **Enterprise** completas (no de evaluación) LTSC/LTSB
> (`win11x64-enterprise-ltsc-2024`, `win10x64-enterprise-ltsc-2021`,
> `win10x86-enterprise-ltsc-2021`, `win10x64-enterprise-ltsb-2016`,
> `win10x86-enterprise-ltsb-2016`, `win10x64-enterprise-ltsb-2015`,
> `win10x86-enterprise-ltsb-2015`) provienen del mismo item
> `massgrave.dev-windows-x64-and-x86-archive` que las ISOs IoT
> (`Windows/Windows 11/Windows 11 Enterprise LTSC 2024/…` y `Windows/Windows
> 10/…`). Las ISOs Enterprise en español provienen de items de `archive.org`
> separados que reflejan los nombres de archivo oficiales en español (es-ES y
> es-MX para Windows 11 Enterprise LTSC 2024 y Windows 10 Enterprise LTSC 2021;
> una única versión es-ES para Windows 10 Enterprise LTSB 2015/2016, por lo que
> estas no tienen contraparte `-es-mx`). Ten en cuenta que **"Windows 10 LTSC
> 2016" y "Windows 10 LTSB 2016" son el mismo producto** — Microsoft renombró
> LTSB a LTSC con la versión de 2019 — por lo que hay un único argumento
> `win10x64-enterprise-ltsb-2016`, no uno separado para LTSC 2016. Windows 11
> (incluida Enterprise LTSC 2024) solo se distribuye como x64/arm64, así que no
> existe una Enterprise LTSC 2024 de 32 bits.

## La API JSON de consumidor

Microsoft retiró el antiguo endpoint HTML
(`/software-download/contentinclude/html`), que ahora devuelve `404`. La API
actual está en:

```
https://www.microsoft.com/software-download-connector/api
```

Se usan dos endpoints:

1. `getskuinformationbyproductedition`
   `?profile=<PROFILE_ID>&productEditionId=<id>&SKU=undefined&friendlyFileName=undefined&Locale=<locale>&sessionID=<sid>`
   Devuelve la lista de SKUs (uno por idioma) de una edición de producto. Ejemplo:

   ```json
   {"Skus":[
     {"Id":"27160","Language":"English"},
     {"Id":"27129","Language":"Spanish"},
     {"Id":"27130","Language":"Spanish (Mexico)"}
   ]}
   ```

2. `GetProductDownloadLinksBySku`
   `?profile=<PROFILE_ID>&productEditionId=undefined&SKU=<sku>&friendlyFileName=undefined&Locale=<locale>&sessionID=<sid>`
   Devuelve URIs de descarga frescas, una por arquitectura:

   ```json
   {"ProductDownloadOptions":[
     {"DownloadType":2,"Uri":"https://...arm64.iso?t=..."},
     {"DownloadType":1,"Uri":"https://...x64.iso?t=..."}
   ]}
   ```

   `DownloadType` `1` es x64 (`2` es arm64). Las URIs vienen codificadas y `&`
   puede aparecer como `\u0026` o `&amp;`, por lo que se decodifican antes de
   usarlas. Los enlaces son válidos **24 horas**.

El `productEditionId` se extrae de la página de descarga visible para el usuario
(`https://www.microsoft.com/<locale>/software-download/windows<N>[ISO]`)
buscando:

```
<option value="[0-9]+">Windows
```

Por eso Mido siempre obtiene la *última* versión sin una tabla fija de releases
(a diferencia de Fido, que mantiene una).

## El handshake de Sentinel

`GetProductDownloadLinksBySku` está protegido por el servicio antiabuso de
Microsoft (*Sentinel*). Sin el handshake, la respuesta contiene:

```json
{"Errors":[{"Key":"ErrorSettings.SentinelReject",
            "Value":"Sentinel marked this request as rejected.","Type":8}]}
```

Mido ejecuta la misma secuencia que el proyecto Fido:

1. Genera un `session_id` aleatorio (`/proc/sys/kernel/random/uuid` o `uuidgen`).
2. `GET https://vlscppe.microsoft.com/tags?org_id=<ORG_ID>&session_id=<sid>`
   para poner en lista blanca la sesión.
3. `GET https://ov-df.microsoft.com/mdt.js?instanceId=<INSTANCE_ID>&PageId=si&session_id=<sid>`
   y extrae los valores `w` y `rticks`.
4. `GET https://ov-df.microsoft.com/?session_id=<sid>&CustomerId=<INSTANCE_ID>&PageId=si&w=<w>&mdt=<epoch_ms>&rticks=<rticks>`.

**Importante:** Sentinel es una comprobación *del lado del servidor basada en la
reputación de la IP*. No es un fallo ni un bug de Mido. Incluso el autor de Fido
documenta que algunos rangos de IP son rechazados y otros no. Por eso Mido
muestra un mensaje útil en lugar de un error crudo. No hay solución del lado del
cliente; las opciones son esperar (24–48 h), usar otra red/VPN o descargar
manualmente.

## Soporte de idiomas

`MIDO_LANG` (por defecto `en-US`) acepta `en-US`, `es-ES` y `es-MX`. Se mapea al
nombre de idioma que usa la API mediante `locale_to_api_language`:

| `MIDO_LANG` | Idioma para la API |
|---|---|
| `en-US` | `English` |
| `es-ES` | `Spanish` |
| `es-MX` | `Spanish (Mexico)` |

La búsqueda del SKU usa la coma final en `"Language":"<nombre>",` para que
`Spanish` no coincida por error con `Spanish (Mexico)`.

Los nombres de archivo de idiomas no por defecto llevan un sufijo de locale vía
`localized_media` (`win11x64.iso` → `win11x64.es-MX.iso`) para que las descargas
en distintos idiomas nunca se sobrescriban. Como Microsoft solo publica checksums
de las ISOs en inglés, los archivos localizados entran en la ruta
`NO KNOWN CHECKSUM (skipping verification)` (ver más abajo).

Además de `MIDO_LANG`, hay argumentos dedicados para Windows 10/11 x64 en
español: `win10x64-esp`, `win10x64-es-mx`, `win11x64-esp` y `win11x64-es-mx`.
Cada uno usa `consumer_download_or_archive`: primero intenta la descarga oficial
de Microsoft (con el locale correspondiente) y, si la petición falla
—habitualmente porque el servicio antiabuso *Sentinel* la rechaza según la
reputación de la IP—, elimina el `.PART` de la descarga oficial para no mezclar
dos compilaciones distintas y descarga una copia idéntica archivada en
`archive.org`. Los respaldos apuntan a compilaciones 22H2 (Windows 10) y 23H2
(Windows 11) en `es-ES`/`es-MX`.

La API JSON de consumidor también expone SKUs de 32 bits (x86), de modo que
`win10x86` intenta primero la descarga oficial x86 de Microsoft y recurre a la
instantánea de archive.org `Win10_22H2_English_x32v1` como respaldo;
`win10x86-esp` y `win10x86-es-mx` hacen lo mismo para España y México. Las ISOs en
español de Windows 8.1 Enterprise también están
archivadas en archive.org (`win81x64-ent-32-espa`, `win81x64-ent-64-esp`). Una
ISO de evaluación en español de Windows Server 2008 R2 SP1 (`win2008r2-espa`)
también está archivada allí, al igual que Windows Server 2008 (sin R2) SP2
(`win2008-server-x64`, `win2008-server-x64-espa`, `win2008-server-x86`,
`win2008-server-x86-espa`), Windows Server 2003 y Windows 2000
Server SP4 en inglés y español. Server 2003 está disponible como Enterprise de
32 bits (`win2003-server`, `win2003-server-espa`) y como R2 Enterprise x64 SP2 de
64 bits (`win2003-server-x64`, `win2003-server-x64-espa`); Windows 2000 Server SP4
es de 32 bits (`win2000-server`, `win2000-server-espa`), y Windows 2000 Datacenter
Server está disponible como la versión RTM OEM con SP1 (`win2000-datacenter`) y
como SP4 (`win2000-datacenter-sp4`). Estas no están cubiertas
por la API de Microsoft y no tienen checksums publicados.


Windows 2000 Professional, Windows XP Professional, Windows XP Home Edition y
Windows 7 Professional ISOs también están archivadas en `archive.org` y no están cubiertas por la API
de Microsoft. Windows 2000 Professional y Windows XP cubren además los canales
de licencia originales **OEM** y **Retail** (FPP) en inglés y español
(`win2000-pro-oem`, `win2000-pro-retail`, `win2000-pro-oem-espa`,
`win2000-pro-retail-espa`, `win-xp-home-oem`, `win-xp-home-retail`,
`win-xp-home-oem-espa`, `win-xp-home-retail-espa`, `win-xp-pro-oem`,
`win-xp-pro-retail`, `win-xp-pro-oem-espa`, `win-xp-pro-retail-espa`); Windows
XP Home Edition y Windows XP Professional están disponibles en inglés y español
(`win-xp-home`, `win-xp-home-espa`, `win-xp-pro`, `win-xp-pro-espa`,
`win-xp-pro-32-espa`).
Estas no tienen checksums publicados.

> **Disponibilidad del español de México (`es-MX`):** Windows hasta Windows 8.1
> (incluida) se distribuyó como una **única versión en español** (`es-ES`) para
> todas las regiones hispanohablantes; Microsoft no publicó una ISO `es-MX` aparte
> para esas versiones. Por tanto, el locale `es-MX` solo se implementa para
> **Windows 10 y Windows 11** (y sus ediciones Enterprise LTSC), para los que
> Microsoft localizó por separado España (`es-ES`) y México (`es-MX`). Los
> antiguos argumentos `win7*-es-mx` y `win81x64-pro-es-mx` se eliminaron porque no
> existen medios es-MX genuinos (los items de archive.org a los que apuntaban
> dejaron de estar disponibles).

> Solo las ediciones de **consumidor** exponen SKUs localizados a través de esta
> API. Los medios Evaluation Enterprise/Server son únicamente en inglés, tal como
> los publica Microsoft, por lo que `enterprise_eval_download` se mantiene a
> propósito en `en-US`.

Las versiones retro (`win30`, `win31`, `wfw31`, `win311`/`wfw311`, `win95`,
`win98`, `winme`, `winnt31`, `winnt35`, `winnt351`, `winnt40`, `backoffice`,
`winframe`) provienen directamente de instantáneas de `archive.org`
(Windows 3.0, Windows 3.1, Windows for Workgroups 3.1, Windows 3.11 para Trabajo
en Grupo, Windows 95, Windows 98 Second Edition, Windows Millennium Edition,
Windows NT 3.1, 3.5 y 3.51 Workstation, Windows NT 4.0 Workstation, además de
Microsoft BackOffice Small Business Server 4.0 y Citrix WinFrame 1.6, la edición
Windows NT 3.51 Terminal Server).
Windows 3.x, Windows 95, Windows 98 Second Edition y Windows Millennium Edition
también tienen instantáneas en español (`win30-espa`, `win31-espa`,
`wfw31-espa`, `win311-espa`, `wfw311-espa`, `win95-espa`, `win98-espa`,
`winme-espa`); el resto de las versiones retro son únicamente en inglés. Algunas
de las entradas más antiguas se distribuyen como archivos ZIP/RAR/7z de los
disquetes originales en lugar de ISOs, por lo que `win30`/`win30-espa` (.zip),
`wfw31` (.rar) y `wfw31-espa` (.7z) no son ISOs. No están cubiertas por la API de
Microsoft y no tienen checksums publicados, por lo que pasan por la ruta
`NO KNOWN CHECKSUM (skipping verification)`.

> **Nota sobre la activación de producto y NewShell:** Ninguno de los medios
> anteriores a XP tiene mecanismo de activación de producto (Microsoft introdujo
> la activación con Windows XP/Office XP en 2001). El sistema de activación
> telefónica se retiró el 3 de diciembre de 2025 y se sustituyó por el Product
> Activation Portal online; consulta el README para los pasos. El parche de
> escritorio *NewShell* / Shell Technology Preview solo aplica a Windows NT 3.51
> (y a la vista previa filtrada del NT 3.5 build 854); se documenta con enlaces
> de descarga en el README.

## Windows Update en Windows sin soporte

Mido solo *descarga* los medios; parchear el sistema instalado es un problema
aparte. Microsoft ha retirado los servicios de actualización de los que dependen
las versiones antiguas de Windows, por lo que el README documenta los proyectos
comunitarios de recuperación y la instalación paso a paso de las actualizaciones.
En resumen:

- **Vista y anteriores (Server 2008 y anteriores):** el servicio clásico de
  Windows Update / Microsoft Update está cerrado de forma permanente.
- **Windows 7 / Server 2008 R2:** el Microsoft Update para "otros productos de
  Microsoft" está cerrado. Instala **Office 2010** para instalar el agente
  Microsoft Update más reciente y reactivar la lista completa de actualizaciones,
  e instala los parches requisito SHA-2 (`KB4474419`, `KB4490628`).
- **Todas las versiones sin soporte:** usa **Legacy Update**
  (<https://legacyupdate.net/>) para Windows 2000–11 y **Windows Update Restored**
  (<https://windowsupdaterestored.com/>, requiere IE 4.0–6.0) para Windows
  95/98/Me/NT 4.0. El Catálogo de Microsoft Update
  (<https://catalog.update.microsoft.com/>) es el respaldo manual.

Consulta la sección del README *"Windows Update en Windows sin soporte"* para las
instrucciones detalladas y listas para copiar.

## Motor de descarga (`scurl_file`)

Todos los medios acaban llamando a `scurl_file <archivo_salida> <versión_tls> <url>`:

- `--progress-bar` — barra de progreso simple.
- `--location` — sigue redirecciones (Microsoft mueve los endpoints a menudo).
- `--output <archivo>.PART` — descarga a un archivo parcial temporal.
- `--continue-at -` — reanuda descargas parciales automáticamente.
- `--max-filesize 10G` — rechaza respuestas absurdas.
- `--fail` — falla ante HTTP ≥ 400.
- `--proto =https` — solo HTTPS.
- `--tlsv<versión>` — fuerza TLS 1.2 o 1.3.
- `--http1.1` — evita bugs conocidos de curl en HTTP/2 y HTTP/3.
- `--retry 5 --retry-delay 5 --retry-connrefused` — recuperación de fallos
  transitorios de red.
- `--speed-limit 1024 --speed-time 30` — aborta una descarga que se queda por
  debajo de 1 KiB/s durante 30 s (útil para la fuente inestable de Wayback).

Si falla, el archivo `.PART` se conserva para reanudar y se llama a
`handle_curl_error`. Las descargas correctas se renombran a `<archivo>.UNVERIFIED`,
a la espera de verificación.

## Verificación de integridad

`verify_media` lee una tabla `sha256sums` incrustada (nombre de medio → SHA-256).
Para cada medio solicitado que haya producido un archivo `.UNVERIFIED`:

1. Calcula el SHA-256 del archivo y comprueba que tenga 64 caracteres
   hexadecimales.
2. Busca el checksum esperado para ese nombre de archivo exacto.
3. Si no hay checksum registrado (normalmente una ISO localizada), imprime
   `NO KNOWN CHECKSUM (skipping verification)` y renombra al nombre final.
4. Si el checksum coincide, imprime `OK` y renombra al nombre final.
5. Si no coincide, deja `<archivo>.UNVERIFIED` y registra un fallo.

Los checksums de las versiones de consumidor **no se actualizan automáticamente**
cuando Microsoft publica una nueva compilación; una discrepancia puede significar
una versión más nueva, corrupción o manipulación. Cuando ocurre, Mido imprime
instrucciones de verificación manual (buscar el hash en DuckDuckGo/onion). Es un
compromiso deliberado para que el script no requiera mantenimiento.

El checksum de Windows 7 es inmutable: esa ISO fue purgada de los servidores de
Microsoft y la copia de Internet Archive se valida contra el checksum previo a
la purga.

## Manejo de errores y códigos de salida

`handle_curl_error` mapea los códigos de salida de `curl` a mensajes legibles y
devuelve una *acción de error fatal* (`2`) para condiciones que deben abortar
toda la ejecución (p. ej. falta de memoria). El patrón numérico por defecto
coincide intencionadamente con el rango POSIX `1–125`:

```sh
[0-9] | [0-9][0-9] | 1[0-1][0-9] | 12[0-5])
```

(Una versión anterior usaba una expansión aritmética dentro del patrón `case`
que solo coincidía con `error_code=1`; esto ya está corregido.)

Códigos de salida del proceso (ver `ending_summary`):

| Código | Significado |
|---|---|
| 0 | Éxito |
| 1 | Error de parseo de argumentos / configuración |
| 2 | Error fatal en tiempo de ejecución |
| 3 | Una o más descargas fallaron |
| 4 | Una o más verificaciones fallaron |
| 5 | Falló al menos una descarga **y** una verificación |

El trap `EXIT` (`handle_exit`) se ejecuta al interrumpir y avisa de que pueden
quedar archivos `.PART` o `.UNVERIFIED`.

## Constantes y configuración

| Variable | Por defecto | Propósito |
|---|---|---|
| `MIDO_LANG` | `en-US` | Idioma de descarga |
| `ORG_ID` | `y6jn8c31` | org id de Sentinel |
| `PROFILE_ID` | `606624d44113` | profile id de la API de consumidor |
| `INSTANCE_ID` | `560dc9f3-1aa5-4a2f-b63c-9e18f8d0e175` | instance id de `ov-df` |
| `API_BASE` | `.../software-download-connector/api` | base de la API de consumidor |
| `DEBUG` | sin definir | traza `set -x` |
| `VERBOSE` | sin definir | Imprime edition/SKU ids |

Estos valores están copiados del proyecto Fido y pueden necesitar actualizarse si
Microsoft los rota.

## Propiedades de seguridad

- Sin navegador ni motor de JavaScript: elimina una enorme superficie de ataque
  frente a manejar un navegador headless.
- Solo HTTPS (`--proto =https`) con la versión de TLS más alta disponible.
- `--http1.1` evita fallos en las implementaciones HTTP/2 y HTTP/3 de curl.
- Solo se usan builtins del shell para la lógica más crítica; los programas de
  apoyo se usan con argumentos fijos y validados.
- Toda salida no confiable del servidor se filtra (`tr -cd '[:alnum:]...'`, con
  límites de longitud vía `head -c`) antes de usarse en URLs o nombres de
  archivo, mitigando la inyección de parámetros HTTP.
- Verificación SHA-256 de cada ISO descargada.
- El argumento `all` puede combinarse con otros sin abortar el bucle, y los
  duplicados se eliminan, de modo que una sola ejecución no puede descargar dos
  veces la misma ISO grande por accidente.

## Solución de problemas

| Síntoma | Causa | Acción |
|---|---|---|
| `Sentinel marked this request as rejected` | Bloqueo por reputación de IP | Espera 24–48 h, usa una VPN o descarga manualmente. Los argumentos en español dedicados (`win10x64-esp`, `win10x64-es-mx`, `win11x64-esp`, `win11x64-es-mx`) recurren automáticamente a archive.org |
| `715-123130` | IP baneada por Microsoft | Igual que arriba (los argumentos en español dedicados recurren a archive.org) |
| `win81x64` → HTTP 404 | Microsoft retiró la automatización de Windows 8.1 | Usa `win81x64-enterprise-eval` |
| Windows 7 muy lento | Límite de velocidad de Wayback Machine | Deja actuar a `--retry`/`--continue-at`; ten paciencia |
| Respaldo archive.org lento (Windows 10/11 en español) | Límite de velocidad de `archive.org` | Deja actuar a `--retry`/`--continue-at`; se reanuda automáticamente |
| Windows 10 x86 (inglés/español) muy lento | Límite de velocidad de `archive.org` | Deja actuar a `--retry`/`--continue-at`; ten paciencia |
| Windows 8.1 Enterprise en español muy lento | Límite de velocidad de `archive.org` | Deja actuar a `--retry`/`--continue-at`; ten paciencia |
| Windows Server 2008 R2 en español muy lento | Límite de velocidad de `archive.org` | Deja actuar a `--retry`/`--continue-at`; ten paciencia |
| Windows Server 2003 / Windows 2000 Server muy lento | Límite de velocidad de `archive.org` | Deja actuar a `--retry`/`--continue-at`; ten paciencia |
| Windows Vista ISOs muy lentas | Límite de velocidad de `archive.org` | Deja actuar a `--retry`/`--continue-at`; ten paciencia |
| `NO KNOWN CHECKSUM` | ISO localizada sin hash publicado | Verifica manualmente si lo deseas |
| Enterprise/Server `no download link` | La página del Evaluation Center cambió | Abre un issue |

## Pruebas

```sh
sh -n Mido.sh                 # comprobación de sintaxis POSIX
shellcheck -s sh Mido.sh      # análisis estático
```

Comprobaciones funcionales que no requieren una descarga correcta:

```sh
./Mido.sh --help
MIDO_LANG=fr-FR ./Mido.sh win11x64    # rechazado con salida 1
./Mido.sh win81x64                    # imprime el mensaje de "retirado", salida 3
VERBOSE=1 MIDO_LANG=es-MX ./Mido.sh win10x64   # muestra edition id + SKU es-MX
```

## Guía de mantenimiento

**Actualizar un checksum.** Edita el heredoc `sha256sums` en `verify_media`
después de verificar el nuevo hash por un canal independiente.

**Añadir un idioma.** Agrega el locale al `case` de validación de `MIDO_LANG` y
una rama a `locale_to_api_language`; `localized_media` funciona automáticamente.

**Añadir un medio.** Agrega una variable `readonly` junto a los demás medios, una
rama en `parse_args` (incluida la lista de `all`), un `case` en `download_media`,
una entrada en `usage()` y, si procede, una línea de checksum.

**Renovar las constantes de Sentinel.** Actualiza
`ORG_ID`/`PROFILE_ID`/`INSTANCE_ID` desde una versión actual de Fido si Microsoft
los rota.

## Licencia

MIT License — Copyright (C) 2024 Elliot Killick <contact@elliotkillick.com>.
