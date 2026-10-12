#!/bin/sh

# Copyright (C) 2024 Elliot Killick <contact@elliotkillick.com>
# Licensed under the MIT License. See LICENSE file for details.

[ "$DEBUG" ] && set -x

# Prefer Dash shell for greater security if available
if [ "$BASH" ] && command -v dash > /dev/null; then
    exec dash "$0" "$@"
fi

# Test for 4-bit color (16 colors)
# Operand "colors" is undefined by POSIX
# If the operand doesn't exist, the terminal probably doesn't support color and the program will continue normally without it
if [ "0$(tput colors 2> /dev/null)" -ge 16 ]; then
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    NC='\033[0m'
fi

# Avoid printing messages as potential terminal escape sequences
echo_ok() { printf "%b%s%b" "${GREEN}[+]${NC} " "$1" "\n" >&2; }
echo_info() { printf "%b%s%b" "${BLUE}[i]${NC} " "$1" "\n" >&2; }
echo_err() { printf "%b%s%b" "${RED}[!]${NC} " "$1" "\n" >&2; }

# https://pubs.opengroup.org/onlinepubs/9699919799/utilities/fold.html
format() { fold -s; }

word_count() { echo $#; }

# Download language/locale.
# Microsoft's consumer download API exposes each language as a separate SKU.
# TODO: extend this table if more languages are desired.
MIDO_LANG="${MIDO_LANG:-en-US}"
case "$MIDO_LANG" in
    en-US | es-ES | es-MX) ;;
    *)
        echo_err "Unsupported language specified: $MIDO_LANG (supported: en-US, es-ES, es-MX)"
        exit 1
        ;;
esac

# Map a BCP-47 locale to the language name used by Microsoft's download API
locale_to_api_language() {
    case "$1" in
        es-ES) echo "Spanish" ;;
        es-MX) echo "Spanish (Mexico)" ;;
        *) echo "English" ;;
    esac
}

# archive.org fallback URL for the consumer Windows ISOs.
# Microsoft's gated consumer download API is protected by the Sentinel anti-abuse
# system, which frequently rejects automated requests based on IP reputation.
# When that happens we transparently fall back to the same official ISO mirrored
# on archive.org. These point to the exact Microsoft file names (22H2 for
# Windows 10, 23H2 for Windows 11).
# Arguments: windows version (7/8/10/11), locale (en-US/es-ES/es-MX), architecture (x64/x86)
archive_fallback_url() {
    case "$1-$2-$3" in
        7-en-US-x64) printf '%s' "https://archive.org/download/en_windows_7_ultimate_with_sp1_dvd/en_windows_7_ultimate_with_sp1_x64_dvd_u_677332.iso" ;;
        7-es-ES-x64) printf '%s' "https://archive.org/download/es_windows_7_ultimate_with_sp1_dvd/es_windows_7_ultimate_with_sp1_x64_dvd_u_677350.iso" ;;
        7-en-US-x86) printf '%s' "https://archive.org/download/en_windows_7_ultimate_with_sp1_dvd/en_windows_7_ultimate_with_sp1_x86_dvd_u_677460.iso" ;;
        7-es-ES-x86) printf '%s' "https://archive.org/download/es_windows_7_ultimate_with_sp1_dvd/es_windows_7_ultimate_with_sp1_x86_dvd_u_677462.iso" ;;
        8-en-US-x64) printf '%s' "https://archive.org/download/en_windows_8.1_x64_dvd_2707217/en_windows_8.1_x64_dvd_2707217.iso" ;;
        8-es-ES-x64) printf '%s' "https://archive.org/download/Win81CoreProESP/es_windows_8_1_x64_dvd_2707379.iso" ;;
        8-en-US-x86) printf '%s' "https://archive.org/download/windows-8.1-x-86-en-us/Windows8.1_x86_en-US.iso" ;;
        8-es-ES-x86) printf '%s' "https://archive.org/download/Win81CoreProESP/es_windows_8_1_x86_dvd_2707521.iso" ;;
        10-en-US-x64) printf '%s' "https://archive.org/download/Win10_22H2_English_x64v1/Win10_22H2_English_x64v1.iso" ;;
        10-en-US-x86) printf '%s' "https://archive.org/download/Win10_22H2_English_x32v1/Win10_22H2_English_x32v1.iso" ;;
        10-es-ES-x64) printf '%s' "https://archive.org/download/win10_22h2_spanish_x64v1.iso-20250331/Win10_22H2_Spanish_x64v1.iso" ;;
        10-es-MX-x64) printf '%s' "https://archive.org/download/win10_22h2_spanish_mexico_x64v1.iso-20250331/Win10_22H2_Spanish_Mexico_x64v1.iso" ;;
        10-es-ES-x86) printf '%s' "https://archive.org/download/win10_22h2_spanish_x32v1.iso-20250331/Win10_22H2_Spanish_x32v1.iso" ;;
        10-es-MX-x86) printf '%s' "https://archive.org/download/win10_22h2_spanish_mexico_x32v1.iso-20250331/Win10_22H2_Spanish_Mexico_x32v1.iso" ;;
        11-en-US-x64) printf '%s' "https://archive.org/download/Win11_23H2_English_x64/Win11_23H2_English_x64.iso" ;;
        11-es-ES-x64) printf '%s' "https://archive.org/download/Win11_23H2_Spanish_x64/Win11_23H2_Spanish_x64.iso" ;;
        11-es-MX-x64) printf '%s' "https://archive.org/download/win-11-23-h-2-spanish-mexico-x-64/Win11_23H2_Spanish_Mexico_x64.iso" ;;
    esac
}

# Append the locale to the output filename for non-default languages so that
# downloads in different languages never overwrite each other
localized_media() {
    case "$MIDO_LANG" in
        en-US) printf '%s' "$1" ;;
        *) printf '%s' "${1%.iso}.${MIDO_LANG}.iso" ;;
    esac
}

# Remove duplicate space-separated words while preserving order
dedupe_list() {
    dedupe_out=""
    for dedupe_item in $1; do
        case " $dedupe_out " in
            *" $dedupe_item "*) ;;
            *) dedupe_out="$dedupe_out $dedupe_item" ;;
        esac
    done
    printf '%s' "$dedupe_out"
}

# Microsoft anti-abuse (Sentinel) endpoint parameters (from the Fido project)
ORG_ID="y6jn8c31"
PROFILE_ID="606624d44113"
INSTANCE_ID="560dc9f3-1aa5-4a2f-b63c-9e18f8d0e175"
API_BASE="https://www.microsoft.com/software-download-connector/api"

usage() {
    echo "Mido - The Secure Microsoft Windows Downloader"
    echo ""
    echo "Usage: $0 <windows_media>..."
    echo ""
    echo "Environment:"
    echo "  MIDO_LANG  Download language: en-US (default), es-ES, es-MX"
    echo ""
    echo "Download specified list of Windows media."
    echo ""
    echo "Specify \"all\", or one or more of the following Windows media:"
    echo "  vista-x64-sp2"
    echo "  vista-x86-sp2"
    echo "  vista-es-x64-sp2"
    echo "  vista-es-x86-sp2"
    echo "  vista-x64-sp2-n (Vista N all-in-one: Home Basic N + Business N, English)"
    echo "  vista-x64-sp2-business-n (Vista Business N, English)"
    echo "  vista-x86-sp2-business-n (Vista Business N 32-bit, English)"
    echo "  win7x64-ultimate"
    echo "  win7x64-ultimate-esp (Spanish, official first then archive.org)"
    echo "  win81x64"
    echo "  win81x64-ent-32-espa (Spanish, archive.org)"
    echo "  win81x64-ent-64-esp (Spanish, archive.org)"
    echo "  win10x64 (official first then archive.org)"
    echo "  win10x64-esp (Spanish, official first then archive.org)"
    echo "  win10x64-es-mx (Mexican Spanish, official first then archive.org)"
    echo "  win10x86 (32-bit English, official first then archive.org)"
    echo "  win10x86-esp (32-bit Spanish, official first then archive.org)"
    echo "  win10x86-es-mx (32-bit Mexican Spanish, official first then archive.org)"
    echo "  win11x64 (official first then archive.org)"
    echo "  win11x64-esp (Spanish, official first then archive.org)"
    echo "  win11x64-es-mx (Mexican Spanish, official first then archive.org)"
    echo "  win81x64-enterprise-eval"
    echo "  win10x64-enterprise-eval"
    echo "  win10x86-enterprise-eval (32-bit)"
    echo "  win11x64-enterprise-eval"
    echo "  win10x64-enterprise-ltsc-eval (most secure)"
    echo "  win11x64-enterprise-ltsc-eval (most secure)"
    echo "  win11x64-iot-enterprise-ltsc-eval"
    echo "  win11x64-iot-enterprise-26h2 (archive.org)"
    echo "  win11x64-iot-enterprise-ltsc-2024 (archive.org)"
    echo "  win10x64-iot-enterprise-22h2 (archive.org)"
    echo "  win10x64-iot-enterprise-ltsc-2021 (archive.org)"
    echo "  win10x64-iot-enterprise-ltsc-2019 (archive.org)"
    echo "  win10x86-iot-enterprise-ltsc-2019 (32-bit, archive.org)"
    echo "  win11x64-enterprise-ltsc-2024 (archive.org)"
    echo "  win11x64-enterprise-ltsc-2024-esp (Spanish, archive.org)"
    echo "  win11x64-enterprise-ltsc-2024-es-mx (Mexican Spanish, archive.org)"
    echo "  win10x64-enterprise-ltsc-2021 (archive.org)"
    echo "  win10x64-enterprise-ltsc-2021-esp (Spanish, archive.org)"
    echo "  win10x64-enterprise-ltsc-2021-es-mx (Mexican Spanish, archive.org)"
    echo "  win10x86-enterprise-ltsc-2021 (32-bit, archive.org)"
    echo "  win10x86-enterprise-ltsc-2021-esp (32-bit Spanish, archive.org)"
    echo "  win10x86-enterprise-ltsc-2021-es-mx (32-bit Mexican Spanish, archive.org)"
    echo "  win10x64-enterprise-ltsb-2016 (archive.org)"
    echo "  win10x64-enterprise-ltsb-2016-esp (Spanish, archive.org)"
    echo "  win10x86-enterprise-ltsb-2016 (32-bit, archive.org)"
    echo "  win10x86-enterprise-ltsb-2016-esp (32-bit Spanish, archive.org)"
    echo "  win10x64-enterprise-ltsb-2015 (archive.org)"
    echo "  win10x64-enterprise-ltsb-2015-esp (Spanish, archive.org)"
    echo "  win10x86-enterprise-ltsb-2015 (32-bit, archive.org)"
    echo "  win10x86-enterprise-ltsb-2015-esp (32-bit Spanish, archive.org)"
    echo "  win2008r2"
    echo "  win81x64 (Windows 8.1 x64, archive.org)"
    echo "  win81x86 (Windows 8.1 x86 32-bit, archive.org)"
    echo "  win81x64-enterprise-eval (Windows 8.1 Enterprise Evaluation)"
    echo "  win81x64-enterprise-n-eval (Windows 8.1 Enterprise N x64, archive.org)"
    echo "  win81x64-industry-enterprise-eval (Windows Embedded 8.1 Industry Enterprise x64, archive.org)"
    echo "  win81x64-industry-pro-eval (Windows Embedded 8.1 Industry Pro x64, archive.org)"
    echo "  win81x86-enterprise-eval (Windows 8.1 Enterprise Evaluation 32-bit)"
    echo "  win81x86-enterprise-n-eval (Windows 8.1 Enterprise N x86, archive.org)"
    echo "  win81x86-industry-enterprise-eval (Windows Embedded 8.1 Industry Enterprise x86, archive.org)"
    echo "  win81x86-industry-pro-eval (Windows Embedded 8.1 Industry Pro x86, archive.org)"
    echo "  win2008r2-espa (Spanish, archive.org)"
    echo "  win2008-server-x64 (SP2, archive.org)"
    echo "  win2008-server-x64-espa (SP2 Spanish, archive.org)"
    echo "  win2008-server-x86 (SP2, archive.org)"
    echo "  win2008-server-x86-espa (SP2 Spanish, archive.org)"
    echo "  win2003-server (archive.org)"
    echo "  win2003-server-espa (Spanish, archive.org)"
    echo "  win2003-server-x64 (R2 Enterprise x64, archive.org)"
    echo "  win2003-server-x64-espa (R2 Enterprise x64 Spanish, archive.org)"
    echo "  win2000-server (archive.org)"
    echo "  win2000-advanced-server (English, archive.org)"
    echo "  win2000-server-espa (Spanish, archive.org)"
    echo "  win2000-advanced-server-espa (Spanish, archive.org)"
    echo "  win2000-datacenter (RTM OEM with SP1, archive.org)"
    echo "  win2000-datacenter-sp4 (SP4, archive.org)"
    echo "  win2000-pro (SP4 retail, archive.org)"
    echo "  win2000-pro-oem (SP3 OEM, archive.org)"
    echo "  win2000-pro-retail (SP4 retail, archive.org)"
    echo "  win2000-pro-espa (SP4 Spanish, archive.org)"
    echo "  win2000-pro-oem-espa (SP1 OEM Spanish, archive.org)"
    echo "  win2000-pro-retail-espa (RTM retail Spanish, archive.org)"
    echo "  win-xp-pro (Professional SP3, archive.org)"
    echo "  win-xp-pro-espa (Professional SP3 Spanish, archive.org)"
    echo "  win-xp-pro-32 (Professional x86, archive.org)"
    echo "  win-xp-pro-32-espa (Professional x86 SP3 Spanish, archive.org)"
    echo "  win-xp-pro-64 (Professional x64 SP2, archive.org)"
    echo "  win-xp-home (Home Edition SP3, archive.org)"
    echo "  win-xp-home-espa (Home Edition SP3 Spanish, archive.org)"
    echo "  win-xp-home-oem (Home Edition RTM OEM, archive.org)"
    echo "  win-xp-home-retail (Home Edition SP3 retail, archive.org)"
    echo "  win-xp-home-oem-espa (Home Edition SP2 OEM Spanish, archive.org)"
    echo "  win-xp-home-retail-espa (Home Edition SP3 retail Spanish, archive.org)"
    echo "  win-xp-pro-oem (Professional SP2 OEM, archive.org)"
    echo "  win-xp-pro-retail (Professional SP3 retail, archive.org)"
    echo "  win-xp-pro-oem-espa (Professional SP2 OEM Spanish, archive.org)"
    echo "  win-xp-pro-retail-espa (Professional SP1 retail Spanish, archive.org)"
    echo "  win2012r2-eval"
    echo "  win2016-eval"
    echo "  win2019-eval"
    echo "  win2022-eval"
    echo "  win2025-eval"
    echo "  win2012r2-essentials-eval"
    echo "  win2016-essentials-eval"
    echo "  win2019-essentials-eval"
    echo "  hyperv2012-eval"
    echo "  hyperv2012r2-eval"
    echo "  hyperv2016-eval"
    echo "  hyperv2019-eval"
    echo "  win30 (Windows 3.0, archive.org)"
    echo "  win30-espa (Windows 3.0a Spanish, archive.org)"
    echo "  win31 (Windows 3.1, archive.org)"
    echo "  win31-espa (Windows 3.1 Spanish, archive.org)"
    echo "  wfw31 (Windows for Workgroups 3.1, archive.org)"
    echo "  wfw31-espa (Windows for Workgroups 3.1 Spanish, archive.org)"
    echo "  win311 (Windows 3.11 / Windows for Workgroups 3.11, archive.org)"
    echo "  win311-espa (Windows 3.11 Spanish, archive.org)"
    echo "  wfw311 (Windows for Workgroups 3.11, archive.org)"
    echo "  wfw311-espa (Windows for Workgroups 3.11 Spanish, archive.org)"
    echo "  win95 (Windows 95, archive.org)"
    echo "  win95-espa (Windows 95 Spanish, archive.org)"
    echo "  win98 (Windows 98 Second Edition, archive.org)"
    echo "  win98-espa (Windows 98 Second Edition Spanish, archive.org)"
    echo "  winme (Windows Millennium Edition, archive.org)"
    echo "  winme-espa (Windows Millennium Edition Spanish, archive.org)"
    echo "  winnt31 (Windows NT 3.1 Workstation, archive.org)"
    echo "  winnt35 (Windows NT 3.5 Workstation, archive.org)"
    echo "  winnt351 (Windows NT 3.51 Workstation, archive.org)"
    echo "  winnt40 (Windows NT 4.0 Workstation, archive.org)"
    echo "  backoffice (Microsoft BackOffice Small Business Server 4.0 x86, archive.org)"
    echo "  winframe (Citrix WinFrame 1.6, Windows NT 3.51 Terminal Server, archive.org)"
    echo ""
    echo "Each ISO download takes between 3 - 7 GiBs (average: 5 GiBs)."
    echo ""
    echo "Updates"
    echo "-------"
    echo "All the downloads provided here are the most up-to-date releases that Microsoft provides. This is ensured by programmatically checking Microsoft's official download pages to get the latest download link. In other cases, the Windows version in question is no longer supported by Microsoft meaning a direct download link (stored in Mido) will always point to the most up-to-date release." | format
    echo ""
    echo "Remember to update Windows to the latest patch level after installation."
    echo ""
    echo "Overuse"
    echo "-------"
    echo "Newer consumer versions of Windows including win81x64, win10x64, and win11x64 are downloaded through Microsoft's gated download web interface. Do not overuse this interface. Microsoft may be quick to do ~24 hour IP address bans after only a few download requests (especially if they are done in quick succession). Being temporarily banned from one of these downloads (e.g. win11x64) doesn't cause you to be banned from any of the other downloads provided through this interface." | format
    echo ""
    echo "Privacy Preserving Technologies"
    echo "-------------------------------"
    echo "The aforementioned Microsoft gated download web interface is currently blocking Tor (and similar technologies). They say this is to prevent people in restricted regions from downloading certain Windows media they shouldn't have access to. This is fine by most standards because Tor is too slow for large downloads anyway and we have checksum verification for security." | format
    echo ""
    echo "Language"
    echo "--------"
    echo "By default all downloads are English (United States). Windows 10 and Windows 11 are also available in Spanish (es-ES) and Mexican Spanish (es-MX) through the MIDO_LANG environment variable. For example: MIDO_LANG=es-MX $0 win11x64. Non-English ISOs are saved with a locale suffix (e.g. win11x64.es-MX.iso). Dedicated arguments also exist: win10x64-esp, win10x64-es-mx, win10x86-esp, win10x86-es-mx, win11x64-esp and win11x64-es-mx. All Windows 10 and Windows 11 consumer downloads (including English) try Microsoft's official download first and, if the request is blocked (for example by the Sentinel anti-abuse system), fall back to an identical archive.org copy." | format
    echo ""
    echo "Architecture"
    echo "------------"
    echo "Most downloads provided here are for x86-64 (x64). Some legacy media (Vista, Server 2003, Server 2000 and the retro releases down to Windows 3.11) are 32-bit (x86) or offer both architectures. x64 is the only architecture Microsoft ships modern Windows Server in.$([ -d /run/qubes ] && echo ' Also, the only architecture Qubes OS supports.')" | format
}

# Media naming scheme info:
# Windows Server has no architecture because Microsoft only supports amd64 for this version of Windows (the last version to support x86 was Windows Server 2008 without the R2)
# "eval" is short for "evaluation", it's simply the license type included with the Windows installation (only exists on enterprise/server) and must be specified in the associated answer file
# "win7x64" has the "ultimate" edition appended to it because it isn't "multi-edition" like the other Windows ISOs (for multi-edition ISOs the edition is specified in the associated answer file)

readonly win7x64_ultimate="win7x64-ultimate.iso"
readonly win7x64_ultimate_esp="win7x64-ultimate-espanol.iso"
readonly win7x86_ultimate="win7x86-ultimate.iso"
readonly win7x86_ultimate_esp="win7x86-ultimate-espanol.iso"
readonly vista_x64_sp1="vista-x64-sp1.iso"
readonly vista_x86_sp1="vista-x86-sp1.iso"
readonly vista_es_x64_sp1="vista-es-x64-sp1.iso"
readonly vista_es_x86_sp1="vista-es-x86-sp1.iso"
readonly vista_x64_sp2="vista-x64-sp2.iso"
readonly vista_x86_sp2="vista-x86-sp2.iso"
readonly vista_es_x64_sp2="vista-es-x64-sp2.iso"
readonly vista_es_x86_sp2="vista-es-x86-sp2.iso"
readonly vista_x64_sp2_n="vista-x64-sp2-n.iso"
readonly vista_x64_sp2_business_n="vista-x64-sp2-business-n.iso"
readonly vista_x86_sp2_business_n="vista-x86-sp2-business-n.iso"
readonly win81x64="win81x64.iso"
readonly win81x64_ent_32_esp="win81x64-ent-32-espa.iso"
readonly win81x64_ent_64_esp="win81x64-ent-64-esp.iso"
readonly win10x64="win10x64.iso"
readonly win10x86="win10x86.iso"
readonly win10x86_esp="win10x86-espanol.iso"
readonly win10x86_es_mx="win10x86-es-mexico.iso"
readonly win10x64_esp="win10x64-espanol.iso"
readonly win10x64_es_mx="win10x64-es-mexico.iso"
readonly win11x64="win11x64.iso"
readonly win11x64_esp="win11x64-espanol.iso"
readonly win11x64_es_mx="win11x64-es-mexico.iso"
readonly win81x64_enterprise_eval="win81x64-enterprise-eval.iso"
readonly win10x64_enterprise_eval="win10x64-enterprise-eval.iso"
readonly win10x86_enterprise_eval="win10x86-enterprise-eval.iso"
readonly win11x64_enterprise_eval="win11x64-enterprise-eval.iso"
readonly win10x64_enterprise_ltsc_eval="win10x64-enterprise-ltsc-eval.iso"
readonly win11x64_enterprise_ltsc_eval="win11x64-enterprise-ltsc-eval.iso"
readonly win11x64_iot_enterprise_ltsc_eval="win11x64-iot-enterprise-ltsc-eval.iso"
readonly win11x64_iot_enterprise_26h2="win11x64-iot-enterprise-26h2.iso"
readonly win11x64_iot_enterprise_ltsc_2024="win11x64-iot-enterprise-ltsc-2024.iso"
readonly win10x64_iot_enterprise_22h2="win10x64-iot-enterprise-22h2.iso"
readonly win10x64_iot_enterprise_ltsc_2021="win10x64-iot-enterprise-ltsc-2021.iso"
readonly win10x64_iot_enterprise_ltsc_2019="win10x64-iot-enterprise-ltsc-2019.iso"
readonly win10x86_iot_enterprise_ltsc_2019="win10x86-iot-enterprise-ltsc-2019.iso"
readonly win11x64_enterprise_ltsc_2024="win11x64-enterprise-ltsc-2024.iso"
readonly win11x64_enterprise_ltsc_2024_esp="win11x64-enterprise-ltsc-2024-espanol.iso"
readonly win11x64_enterprise_ltsc_2024_es_mx="win11x64-enterprise-ltsc-2024-es-mexico.iso"
readonly win10x64_enterprise_ltsc_2021="win10x64-enterprise-ltsc-2021.iso"
readonly win10x64_enterprise_ltsc_2021_esp="win10x64-enterprise-ltsc-2021-espanol.iso"
readonly win10x64_enterprise_ltsc_2021_es_mx="win10x64-enterprise-ltsc-2021-es-mexico.iso"
readonly win10x86_enterprise_ltsc_2021="win10x86-enterprise-ltsc-2021.iso"
readonly win10x86_enterprise_ltsc_2021_esp="win10x86-enterprise-ltsc-2021-espanol.iso"
readonly win10x86_enterprise_ltsc_2021_es_mx="win10x86-enterprise-ltsc-2021-es-mexico.iso"
readonly win10x64_enterprise_ltsb_2016="win10x64-enterprise-ltsb-2016.iso"
readonly win10x64_enterprise_ltsb_2016_esp="win10x64-enterprise-ltsb-2016-espanol.iso"
readonly win10x86_enterprise_ltsb_2016="win10x86-enterprise-ltsb-2016.iso"
readonly win10x86_enterprise_ltsb_2016_esp="win10x86-enterprise-ltsb-2016-espanol.iso"
readonly win10x64_enterprise_ltsb_2015="win10x64-enterprise-ltsb-2015.iso"
readonly win10x64_enterprise_ltsb_2015_esp="win10x64-enterprise-ltsb-2015-espanol.iso"
readonly win10x86_enterprise_ltsb_2015="win10x86-enterprise-ltsb-2015.iso"
readonly win10x86_enterprise_ltsb_2015_esp="win10x86-enterprise-ltsb-2015-espanol.iso"
readonly win2008r2="win2008r2.iso"
readonly win81x86="win81x86.iso"
readonly win81x64_enterprise_n_eval="win81x64-enterprise-n-eval.iso"
readonly win81x64_industry_enterprise_eval="win81x64-industry-enterprise-eval.iso"
readonly win81x64_industry_pro_eval="win81x64-industry-pro-eval.iso"
readonly win81x86_enterprise_eval="win81x86-enterprise-eval.iso"
readonly win81x86_enterprise_n_eval="win81x86-enterprise-n-eval.iso"
readonly win81x86_industry_enterprise_eval="win81x86-industry-enterprise-eval.iso"
readonly win81x86_industry_pro_eval="win81x86-industry-pro-eval.iso"
readonly win2008r2_espa="win2008r2-espa.iso"
readonly win2008_server_x64="win2008-server-x64.iso"
readonly win2008_server_x64_espa="win2008-server-x64-espa.iso"
readonly win2008_server_x86="win2008-server-x86.iso"
readonly win2008_server_x86_espa="win2008-server-x86-espa.iso"
readonly win2003_server="win2003-server.iso"
readonly win2003_server_espa="win2003-server-espa.iso"
readonly win2003_server_x64="win2003-server-x64.iso"
readonly win2003_server_x64_espa="win2003-server-x64-espa.iso"
readonly win2000_server="win2000-server.iso"
readonly win2000_server_espa="win2000-server-espa.iso"
readonly win2000_advanced_server="win2000-advanced-server.iso"
readonly win2000_advanced_server_espa="win2000-advanced-server-espa.iso"
readonly win2000_datacenter="win2000-datacenter.iso"
readonly win2000_datacenter_sp4="win2000-datacenter-sp4.iso"
readonly win2000_pro="win2000-pro.iso"
readonly win2000_pro_espa="win2000-pro-espa.iso"
readonly win2000_pro_oem="win2000-pro-oem.iso"
readonly win2000_pro_retail="win2000-pro-retail.iso"
readonly win2000_pro_oem_espa="win2000-pro-oem-espa.iso"
readonly win2000_pro_retail_espa="win2000-pro-retail-espa.iso"
readonly win_xp_pro="winxp-pro.iso"
readonly win_xp_pro_espa="winxp-pro-espa.iso"
readonly win_xp_pro_32="winxp-pro-x86.iso"
readonly win_xp_pro_32_espa="winxp-pro-x86-espa.iso"
readonly win_xp_pro_64="winxp-pro-x64.iso"
readonly win_xp_home="winxp-home.iso"
readonly win_xp_home_espa="winxp-home-espa.iso"
readonly win_xp_home_oem="winxp-home-oem.iso"
readonly win_xp_home_retail="winxp-home-retail.iso"
readonly win_xp_home_oem_espa="winxp-home-oem-espa.iso"
readonly win_xp_home_retail_espa="winxp-home-retail-espa.iso"
readonly win_xp_pro_oem="winxp-pro-oem.iso"
readonly win_xp_pro_retail="winxp-pro-retail.iso"
readonly win_xp_pro_oem_espa="winxp-pro-oem-espa.iso"
readonly win_xp_pro_retail_espa="winxp-pro-retail-espa.iso"
readonly win7x64_pro="win7x64-pro.iso"
readonly win7x64_pro_esp="win7x64-pro-espanol.iso"
readonly win7x86_pro="win7x86-pro.iso"
readonly win7x86_pro_esp="win7x86-pro-espanol.iso"
readonly win7x64_homepremium="win7x64-homepremium.iso"
readonly win7x64_homepremium_esp="win7x64-homepremium-espanol.iso"
readonly win7x86_homepremium="win7x86-homepremium.iso"
readonly win7x86_homepremium_esp="win7x86-homepremium-espanol.iso"
readonly win7x64_enterprise="win7x64-enterprise.iso"
readonly win7x64_enterprise_esp="win7x64-enterprise-espanol.iso"
readonly win7x86_enterprise="win7x86-enterprise.iso"
readonly win7x86_enterprise_esp="win7x86-enterprise-espanol.iso"
readonly win7x64_sp1="win7x64-sp1.iso"
readonly win7x86_sp1="win7x86-sp1.iso"
readonly win81x64_pro="win81x64-pro.iso"
readonly win81x64_pro_esp="win81x64-pro-espanol.iso"
readonly win81x86_pro="win81x86-pro.iso"
readonly win81x86_pro_esp="win81x86-pro-espanol.iso"
readonly win2012r2_eval="win2012r2-eval.iso"
readonly win2016_eval="win2016-eval.iso"
readonly win2019_eval="win2019-eval.iso"
readonly win2022_eval="win2022-eval.iso"
readonly win2025_eval="win2025-eval.iso"
readonly win2012r2_essentials_eval="win2012r2-essentials-eval.iso"
readonly win2016_essentials_eval="win2016-essentials-eval.iso"
readonly win2019_essentials_eval="win2019-essentials-eval.iso"
readonly hyperv2012_eval="hyperv2012-eval.iso"
readonly hyperv2012r2_eval="hyperv2012r2-eval.iso"
readonly hyperv2016_eval="hyperv2016-eval.iso"
readonly hyperv2019_eval="hyperv2019-eval.iso"
readonly win30="win30.zip"
readonly win30_espa="win30-espa.zip"
readonly win31="win31.iso"
readonly win31_espa="win31-espa.iso"
readonly wfw31="wfw31.rar"
readonly wfw31_espa="wfw31-espa.7z"
readonly win311="win311.iso"
readonly win311_espa="win311-espa.iso"
readonly wfw311="wfw311.iso"
readonly wfw311_espa="wfw311-espa.iso"
readonly win95="win95.iso"
readonly win95_espa="win95-espa.iso"
readonly win98="win98.iso"
readonly win98_espa="win98-espa.iso"
readonly winme="winme.iso"
readonly winme_espa="winme-espa.iso"
readonly winnt31="winnt31.iso"
readonly winnt35="winnt35.iso"
readonly winnt351="winnt351.iso"
readonly winnt40="winnt40.iso"
readonly backoffice="backoffice-sbs-4.0.iso"
readonly winframe="winframe-1.6.iso"

parse_args() {
    for arg in "$@"; do
        if [ "$arg" = "-h" ] ||  [ "$arg" = "--help" ]; then
            usage
            exit
        fi
    done

    if [ $# -lt 1 ]; then
        usage >&2
        exit 1
    fi

    # Append to media_list so media is downloaded in the order they're passed in
    for arg in "$@"; do
        case "$arg" in
            win7x64-ultimate)
                media_list="$media_list $win7x64_ultimate"
                ;;
            win7x64-ultimate-esp)
                media_list="$media_list $win7x64_ultimate_esp"
                ;;
            win7x86-ultimate)
                media_list="$media_list $win7x86_ultimate"
                ;;
            win7x86-ultimate-esp)
                media_list="$media_list $win7x86_ultimate_esp"
                ;;
            vista-x64-sp2)
                media_list="$media_list $vista_x64_sp2"
                ;;
            vista-x86-sp2)
                media_list="$media_list $vista_x86_sp2"
                ;;
            vista-es-x64-sp2)
                media_list="$media_list $vista_es_x64_sp2"
                ;;
            vista-es-x86-sp2)
                media_list="$media_list $vista_es_x86_sp2"
                ;;
            vista-x64-sp1)
                media_list="$media_list $vista_x64_sp1"
                ;;
            vista-x86-sp1)
                media_list="$media_list $vista_x86_sp1"
                ;;
            vista-es-x64-sp1)
                media_list="$media_list $vista_es_x64_sp1"
                ;;
            vista-es-x86-sp1)
                media_list="$media_list $vista_es_x86_sp1"
                ;;
            vista-x64-sp2-n)
                media_list="$media_list $vista_x64_sp2_n"
                ;;
            vista-x64-sp2-business-n)
                media_list="$media_list $vista_x64_sp2_business_n"
                ;;
            vista-x86-sp2-business-n)
                media_list="$media_list $vista_x86_sp2_business_n"
                ;;
            win81x64-ent-32-espa)
                media_list="$media_list $win81x64_ent_32_esp"
                ;;
            win81x64-ent-64-esp)
                media_list="$media_list $win81x64_ent_64_esp"
                ;;
            win10x64)
                media_list="$media_list $win10x64"
                ;;
            win10x86 | win10x86-en-us)
                media_list="$media_list $win10x86"
                ;;
            win10x86-esp | win10x86_esp)
                media_list="$media_list $win10x86_esp"
                ;;
            win10x86-es-mx | win10x86_es_mx)
                media_list="$media_list $win10x86_es_mx"
                ;;
            win10x64-esp)
                media_list="$media_list $win10x64_esp"
                ;;
            win10x64-es-mx)
                media_list="$media_list $win10x64_es_mx"
                ;;
            win11x64)
                media_list="$media_list $win11x64"
                ;;
            win11x64-esp)
                media_list="$media_list $win11x64_esp"
                ;;
            win11x64-es-mx)
                media_list="$media_list $win11x64_es_mx"
                ;;
            win10x64-enterprise-eval)
                media_list="$media_list $win10x64_enterprise_eval"
                ;;
            win10x86-enterprise-eval)
                media_list="$media_list $win10x86_enterprise_eval"
                ;;
            win11x64-enterprise-eval)
                media_list="$media_list $win11x64_enterprise_eval"
                ;;
            win10x64-enterprise-ltsc-eval)
                media_list="$media_list $win10x64_enterprise_ltsc_eval"
                ;;
            win11x64-enterprise-ltsc-eval)
                media_list="$media_list $win11x64_enterprise_ltsc_eval"
                ;;
            win11x64-iot-enterprise-ltsc-eval)
                media_list="$media_list $win11x64_iot_enterprise_ltsc_eval"
                ;;
            win11x64-iot-enterprise-26h2)
                media_list="$media_list $win11x64_iot_enterprise_26h2"
                ;;
            win11x64-iot-enterprise-ltsc-2024)
                media_list="$media_list $win11x64_iot_enterprise_ltsc_2024"
                ;;
            win10x64-iot-enterprise-22h2)
                media_list="$media_list $win10x64_iot_enterprise_22h2"
                ;;
            win10x64-iot-enterprise-ltsc-2021)
                media_list="$media_list $win10x64_iot_enterprise_ltsc_2021"
                ;;
            win10x64-iot-enterprise-ltsc-2019)
                media_list="$media_list $win10x64_iot_enterprise_ltsc_2019"
                ;;
            win10x86-iot-enterprise-ltsc-2019)
                media_list="$media_list $win10x86_iot_enterprise_ltsc_2019"
                ;;
            win11x64-enterprise-ltsc-2024)
                media_list="$media_list $win11x64_enterprise_ltsc_2024"
                ;;
            win11x64-enterprise-ltsc-2024-esp)
                media_list="$media_list $win11x64_enterprise_ltsc_2024_esp"
                ;;
            win11x64-enterprise-ltsc-2024-es-mx)
                media_list="$media_list $win11x64_enterprise_ltsc_2024_es_mx"
                ;;
            win10x64-enterprise-ltsc-2021)
                media_list="$media_list $win10x64_enterprise_ltsc_2021"
                ;;
            win10x64-enterprise-ltsc-2021-esp)
                media_list="$media_list $win10x64_enterprise_ltsc_2021_esp"
                ;;
            win10x64-enterprise-ltsc-2021-es-mx)
                media_list="$media_list $win10x64_enterprise_ltsc_2021_es_mx"
                ;;
            win10x86-enterprise-ltsc-2021)
                media_list="$media_list $win10x86_enterprise_ltsc_2021"
                ;;
            win10x86-enterprise-ltsc-2021-esp)
                media_list="$media_list $win10x86_enterprise_ltsc_2021_esp"
                ;;
            win10x86-enterprise-ltsc-2021-es-mx)
                media_list="$media_list $win10x86_enterprise_ltsc_2021_es_mx"
                ;;
            win10x64-enterprise-ltsb-2016)
                media_list="$media_list $win10x64_enterprise_ltsb_2016"
                ;;
            win10x64-enterprise-ltsb-2016-esp)
                media_list="$media_list $win10x64_enterprise_ltsb_2016_esp"
                ;;
            win10x86-enterprise-ltsb-2016)
                media_list="$media_list $win10x86_enterprise_ltsb_2016"
                ;;
            win10x86-enterprise-ltsb-2016-esp)
                media_list="$media_list $win10x86_enterprise_ltsb_2016_esp"
                ;;
            win10x64-enterprise-ltsb-2015)
                media_list="$media_list $win10x64_enterprise_ltsb_2015"
                ;;
            win10x64-enterprise-ltsb-2015-esp)
                media_list="$media_list $win10x64_enterprise_ltsb_2015_esp"
                ;;
            win10x86-enterprise-ltsb-2015)
                media_list="$media_list $win10x86_enterprise_ltsb_2015"
                ;;
            win10x86-enterprise-ltsb-2015-esp)
                media_list="$media_list $win10x86_enterprise_ltsb_2015_esp"
                ;;
            win2008r2)
                media_list="$media_list $win2008r2"
                ;;
            win2008r2-espa)
                media_list="$media_list $win2008r2_espa";;

            win81x64)
                media_list="$media_list $win81x64"
                ;;
            win81x86)
                media_list="$media_list $win81x86"
                ;;
            win81x64-enterprise-eval)
                media_list="$media_list $win81x64_enterprise_eval"
                ;;
            win81x64-enterprise-n-eval)
                media_list="$media_list $win81x64_enterprise_n_eval"
                ;;
            win81x64-industry-enterprise-eval)
                media_list="$media_list $win81x64_industry_enterprise_eval"
                ;;
            win81x64-industry-pro-eval)
                media_list="$media_list $win81x64_industry_pro_eval"
                ;;
            win81x86-enterprise-eval)
                media_list="$media_list $win81x86_enterprise_eval"
                ;;
            win81x86-enterprise-n-eval)
                media_list="$media_list $win81x86_enterprise_n_eval"
                ;;
            win81x86-industry-enterprise-eval)
                media_list="$media_list $win81x86_industry_enterprise_eval"
                ;;
            win81x86-industry-pro-eval)
                media_list="$media_list $win81x86_industry_pro_eval"
                ;;
            win2008-server-x64)
                media_list="$media_list $win2008_server_x64"
                ;;
            win2008-server-x64-espa)
                media_list="$media_list $win2008_server_x64_espa"
                ;;
            win2008-server-x86)
                media_list="$media_list $win2008_server_x86"
                ;;
            win2008-server-x86-espa)
                media_list="$media_list $win2008_server_x86_espa"
                ;;
            win2003-server)
                media_list="$media_list $win2003_server"
                ;;
            win2003-server-espa)
                media_list="$media_list $win2003_server_espa"
                ;;
            win2003-server-x64)
                media_list="$media_list $win2003_server_x64"
                ;;
            win2003-server-x64-espa)
                media_list="$media_list $win2003_server_x64_espa"
                ;;
            win2000-server)
                media_list="$media_list $win2000_server"
                ;;
            win2000-advanced-server)
                media_list="$media_list $win2000_advanced_server"
                ;;
            win2000-advanced-server-espa)
                media_list="$media_list $win2000_advanced_server_espa"
                ;;
            win2000-server-espa)
                media_list="$media_list $win2000_server_espa"
                ;;
            win2000-datacenter)
                media_list="$media_list $win2000_datacenter"
                ;;
            win2000-datacenter-sp4)
                media_list="$media_list $win2000_datacenter_sp4"
                ;;
            win2000-pro)
                media_list="$media_list $win2000_pro"
                ;;
            win2000-pro-espa)
                media_list="$media_list $win2000_pro_espa"
                ;;
            win2000-pro-oem)
                media_list="$media_list $win2000_pro_oem"
                ;;
            win2000-pro-retail)
                media_list="$media_list $win2000_pro_retail"
                ;;
            win2000-pro-oem-espa)
                media_list="$media_list $win2000_pro_oem_espa"
                ;;
            win2000-pro-retail-espa)
                media_list="$media_list $win2000_pro_retail_espa"
                ;;
            win-xp-pro)
                media_list="$media_list $win_xp_pro"
                ;;
            win-xp-pro-espa)
                media_list="$media_list $win_xp_pro_espa"
                ;;
            win-xp-pro-32)
                media_list="$media_list $win_xp_pro_32"
                ;;
            win-xp-pro-32-espa)
                media_list="$media_list $win_xp_pro_32_espa"
                ;;
            win-xp-pro-64)
                media_list="$media_list $win_xp_pro_64"
                ;;
            win-xp-home)
                media_list="$media_list $win_xp_home"
                ;;
            win-xp-home-espa)
                media_list="$media_list $win_xp_home_espa"
                ;;
            win-xp-home-oem)
                media_list="$media_list $win_xp_home_oem"
                ;;
            win-xp-home-retail)
                media_list="$media_list $win_xp_home_retail"
                ;;
            win-xp-home-oem-espa)
                media_list="$media_list $win_xp_home_oem_espa"
                ;;
            win-xp-home-retail-espa)
                media_list="$media_list $win_xp_home_retail_espa"
                ;;
            win-xp-pro-oem)
                media_list="$media_list $win_xp_pro_oem"
                ;;
            win-xp-pro-retail)
                media_list="$media_list $win_xp_pro_retail"
                ;;
            win-xp-pro-oem-espa)
                media_list="$media_list $win_xp_pro_oem_espa"
                ;;
            win-xp-pro-retail-espa)
                media_list="$media_list $win_xp_pro_retail_espa"
                ;;
            win7x64-pro)
                media_list="$media_list $win7x64_pro"
                ;;
            win7x64-pro-esp)
                media_list="$media_list $win7x64_pro_esp"
                ;;
            win7x86-pro)
                media_list="$media_list $win7x86_pro"
                ;;
            win7x86-pro-esp)
                media_list="$media_list $win7x86_pro_esp"
                ;;
            win7x64-homepremium)
                media_list="$media_list $win7x64_homepremium"
                ;;
            win7x64-homepremium-esp)
                media_list="$media_list $win7x64_homepremium_esp"
                ;;
            win7x86-homepremium)
                media_list="$media_list $win7x86_homepremium"
                ;;
            win7x86-homepremium-esp)
                media_list="$media_list $win7x86_homepremium_esp"
                ;;
            win7x64-enterprise)
                media_list="$media_list $win7x64_enterprise"
                ;;
            win7x64-enterprise-esp)
                media_list="$media_list $win7x64_enterprise_esp"
                ;;
            win7x86-enterprise)
                media_list="$media_list $win7x86_enterprise"
                ;;
            win7x86-enterprise-esp)
                media_list="$media_list $win7x86_enterprise_esp"
                ;;
            win7x64-sp1)
                media_list="$media_list $win7x64_sp1"
                ;;
            win7x86-sp1)
                media_list="$media_list $win7x86_sp1"
                ;;
            win81x64-pro)
                media_list="$media_list $win81x64_pro"
                ;;
            win81x64-pro-esp)
                media_list="$media_list $win81x64_pro_esp"
                ;;
            win81x86-pro)
                media_list="$media_list $win81x86_pro"
                ;;
            win81x86-pro-esp)
                media_list="$media_list $win81x86_pro_esp"
                ;;
            win2012r2-eval)
                media_list="$media_list $win2012r2_eval"
                ;;
            win2016-eval)
                media_list="$media_list $win2016_eval"
                ;;
            win2019-eval)
                media_list="$media_list $win2019_eval"
                ;;
            win2022-eval)
                media_list="$media_list $win2022_eval"
                ;;
            win2025-eval)
                media_list="$media_list $win2025_eval"
                ;;
            win2012r2-essentials-eval)
                media_list="$media_list $win2012r2_essentials_eval"
                ;;
            win2016-essentials-eval)
                media_list="$media_list $win2016_essentials_eval"
                ;;
            win2019-essentials-eval)
                media_list="$media_list $win2019_essentials_eval"
                ;;
            hyperv2012-eval)
                media_list="$media_list $hyperv2012_eval"
                ;;
            hyperv2012r2-eval)
                media_list="$media_list $hyperv2012r2_eval"
                ;;
            hyperv2016-eval)
                media_list="$media_list $hyperv2016_eval"
                ;;
            hyperv2019-eval)
                media_list="$media_list $hyperv2019_eval"
                ;;
            win30)
                media_list="$media_list $win30"
                ;;
            win30-espa)
                media_list="$media_list $win30_espa"
                ;;
            win31)
                media_list="$media_list $win31"
                ;;
            win31-espa)
                media_list="$media_list $win31_espa"
                ;;
            wfw31)
                media_list="$media_list $wfw31"
                ;;
            wfw31-espa)
                media_list="$media_list $wfw31_espa"
                ;;
            win311)
                media_list="$media_list $win311"
                ;;
            win311-espa)
                media_list="$media_list $win311_espa"
                ;;
            wfw311)
                media_list="$media_list $wfw311"
                ;;
            wfw311-espa)
                media_list="$media_list $wfw311_espa"
                ;;
            win95)
                media_list="$media_list $win95"
                ;;
            win95-espa)
                media_list="$media_list $win95_espa"
                ;;
            win98)
                media_list="$media_list $win98"
                ;;
            win98-espa)
                media_list="$media_list $win98_espa"
                ;;
            winme)
                media_list="$media_list $winme"
                ;;
            winme-espa)
                media_list="$media_list $winme_espa"
                ;;
            winnt35)
                media_list="$media_list $winnt35"
                ;;
            winnt40)
                media_list="$media_list $winnt40"
                ;;
            winnt31)
                media_list="$media_list $winnt31"
                ;;
            winnt351)
                media_list="$media_list $winnt351"
                ;;
            backoffice)
                media_list="$media_list $backoffice"
                ;;
            winframe)
                media_list="$media_list $winframe"
                ;;
            all)
                media_list="$media_list $win7x64_ultimate $win7x64_ultimate_esp $win7x86_ultimate $win7x86_ultimate_esp $win7x64_homepremium $win7x64_homepremium_esp $win7x86_homepremium $win7x86_homepremium_esp $win7x64_enterprise $win7x64_enterprise_esp $win7x86_enterprise $win7x86_enterprise_esp $win7x64_sp1 $win7x86_sp1 $vista_x64_sp2 $vista_x86_sp2 $vista_es_x64_sp2 $vista_es_x86_sp2 $vista_x64_sp2_n $vista_x64_sp2_business_n $vista_x86_sp2_business_n $vista_x64_sp1 $vista_x86_sp1 $vista_es_x64_sp1 $vista_es_x86_sp1 $win81x64 $win10x64 $win10x86 $win11x64 $win81x64_enterprise_eval $win10x64_enterprise_eval $win10x86_enterprise_eval $win11x64_enterprise_eval $win10x64_enterprise_ltsc_eval $win11x64_enterprise_ltsc_eval $win11x64_iot_enterprise_ltsc_eval $win11x64_iot_enterprise_26h2 $win11x64_iot_enterprise_ltsc_2024 $win10x64_iot_enterprise_22h2 $win10x64_iot_enterprise_ltsc_2021 $win10x64_iot_enterprise_ltsc_2019 $win10x86_iot_enterprise_ltsc_2019 $win11x64_enterprise_ltsc_2024 $win11x64_enterprise_ltsc_2024_esp $win11x64_enterprise_ltsc_2024_es_mx $win10x64_enterprise_ltsc_2021 $win10x64_enterprise_ltsc_2021_esp $win10x64_enterprise_ltsc_2021_es_mx $win10x86_enterprise_ltsc_2021 $win10x86_enterprise_ltsc_2021_esp $win10x86_enterprise_ltsc_2021_es_mx $win10x64_enterprise_ltsb_2016 $win10x64_enterprise_ltsb_2016_esp $win10x86_enterprise_ltsb_2016 $win10x86_enterprise_ltsb_2016_esp $win10x64_enterprise_ltsb_2015 $win10x64_enterprise_ltsb_2015_esp $win10x86_enterprise_ltsb_2015 $win10x86_enterprise_ltsb_2015_esp $win2008r2 $win2008r2_espa $win2008_server_x64 $win2008_server_x64_espa $win2008_server_x86 $win2008_server_x86_espa $win2003_server $win2003_server_espa $win2003_server_x64 $win2003_server_x64_espa $win2000_server $win2000_server_espa $win2000_datacenter $win2000_datacenter_sp4 $win2012r2_eval $win2016_eval $win2019_eval $win2022_eval $win2025_eval $win2012r2_essentials_eval $win2016_essentials_eval $win2019_essentials_eval $hyperv2012_eval $hyperv2012r2_eval $hyperv2016_eval $hyperv2019_eval $win81x64_ent_32_esp $win81x64_ent_64_esp $win81x64 $win81x86 $win81x64_enterprise_eval $win81x64_enterprise_n_eval $win81x64_industry_enterprise_eval $win81x64_industry_pro_eval $win81x86_enterprise_eval $win81x86_enterprise_n_eval $win81x86_industry_enterprise_eval $win81x86_industry_pro_eval $win10x86 $win10x86_esp $win10x86_es_mx $win10x64_esp $win10x64_es_mx $win11x64_esp $win11x64_es_mx $win30 $win30_espa $win31 $win31_espa $wfw31 $wfw31_espa $win311 $win311_espa $wfw311 $wfw311_espa $win95 $win98 $winme $winnt31 $winnt35 $winnt351 $winnt40 $backoffice $winframe $win2000_pro_oem $win2000_pro_retail $win2000_pro_oem_espa $win2000_pro_retail_espa $win_xp_home $win_xp_home_espa $win_xp_home_oem $win_xp_home_retail $win_xp_home_oem_espa $win_xp_home_retail_espa $win_xp_pro_oem $win_xp_pro_retail $win_xp_pro_oem_espa $win_xp_pro_retail_espa $win_xp_pro_64 $win95_espa $win98_espa $winme_espa"
                ;;
            *)
                echo_err "Invalid Windows media specified: $arg"
                exit 1
                ;;
        esac
    done

    # Remove duplicate media entries while preserving the order they were passed in
    media_list="$(dedupe_list "$media_list")"
}

handle_curl_error() {
    error_code="$1"

    fatal_error_action=2

    case "$error_code" in
        6)
            echo_err "Failed to resolve Microsoft servers! Is there an Internet connection? Exiting..."
            return "$fatal_error_action"
            ;;
        7)
            echo_err "Failed to contact Microsoft servers! Is there an Internet connection or is the server down?"
            ;;
        8)
            echo_err "Microsoft servers returned a malformed HTTP response!"
            ;;
        22)
            echo_err "Microsoft servers returned a failing HTTP status code!"
            ;;
        23)
            echo_err "Failed at writing Windows media to disk! Out of disk space or permission error? Exiting..."
            return "$fatal_error_action"
            ;;
        26)
            echo_err "Ran out of memory during download! Exiting..."
            return "$fatal_error_action"
            ;;
        28)
            echo_err "Timed out waiting for Microsoft servers (or the archive mirror)!"
            ;;
        36)
            echo_err "Failed to continue earlier download!"
            ;;
        63)
            echo_err "Microsoft servers returned an unexpectedly large response!"
            ;;
        # POSIX defines exit statuses 1-125 as usable by us
        # https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_08_02
        [0-9] | [0-9][0-9] | 1[0-1][0-9] | 12[0-5])
            # Must be some other server or network error (possibly with this specific request/file)
            # This is when accounting for all possible errors in the curl manual assuming a correctly formed curl command and an HTTP(S) request, using only the curl features we're using, and a sane build
            echo_err "Miscellaneous server or network error!"
            ;;
        126 | 127)
            echo_err "Curl command not found! Please install curl and try again. Exiting..."
            return "$fatal_error_action"
            ;;
        # Exit statuses are undefined by POSIX beyond this point
        *)
            case "$(kill -l "$error_code")" in
                # Signals defined to exist by POSIX:
                # https://pubs.opengroup.org/onlinepubs/009695399/basedefs/signal.h.html
                INT)
                    echo_err "Curl was interrupted!"
                    ;;
                # There could be other signals but these are most common
                SEGV | ABRT)
                    echo_err "Curl crashed! Failed exploitation attempt? Please report any core dumps to curl developers. Exiting..."
                    return "$fatal_error_action"
                    ;;
                *)
                    echo_err "Curl terminated due to a fatal signal!"
                    ;;
            esac
    esac

    return 1
}

part_ext=".PART"
unverified_ext=".UNVERIFIED"

scurl_file() {
    out_file="$1"
    tls_version="$2"
    url="$3"

    part_file="${out_file}${part_ext}"

    # --location: Microsoft likes to change which endpoint these downloads are stored on but is usually kind enough to add redirects
    # --fail: Return an error on server errors where the HTTP response code is 400 or greater
    # --retry: Retry transient network/server errors (useful for flaky mirrors such as web.archive.org)
    # --speed-limit/--speed-time: Abort (and resume later) a stalled transfer instead of hanging forever
    curl --progress-bar --location --output "$part_file" --continue-at - --max-filesize 10G --fail --proto =https "--tlsv$tls_version" --http1.1 --retry 5 --retry-delay 5 --retry-connrefused --speed-limit 1024 --speed-time 30 -- "$url" || {
        error_code=$?
        handle_curl_error "$error_code"
        error_action=$?

        # Clean up and make sure a future resume doesn't happen from a bad download resume file
        # NOTE: The partial download is written to $part_file, never to $out_file
        if [ -f "$part_file" ]; then
            # If file is empty, bad HTTP code, or bad download resume file
            if [ ! -s "$part_file" ] || [ "$error_code" = 22 ] || [ "$error_code" = 36 ]; then
                echo_info "Deleting failed download..."
                rm -f "$part_file"
            fi
        fi

        return "$error_action"
    }

    # Full downloaded succeeded, ready for verification check
    mv "$part_file" "${out_file}${unverified_ext}"
}

manual_verification() {
    media_verification_failed_list="$1"
    checksum_verification_failed_list="$2"

    echo_info "Manual verification instructions"
    echo "    1. Get checksum (may already be done for you):" >&2
    echo "    sha256sum <ISO_FILENAME>" >&2
    echo "" >&2
    echo "    2. Verify media:" >&2
    echo "    Web search: https://duckduckgo.com/?q=%22CHECKSUM_HERE%22" >&2
    echo "    Onion search: https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion/?q=%22CHECKSUM_HERE%22" >&2
    echo "    \"No results found\" or unexpected results indicates the media has been modified and should not be used." >&2
    echo "" >&2
    echo "    3. Remove the $unverified_ext extension from the file after performing or deciding to skip verification (not recommended):" >&2
    echo "    mv <ISO_FILENAME>$unverified_ext <ISO_FILENAME>" >&2
    echo "" >&2

    for media in $media_verification_failed_list; do
        # Read current checksum in list and then read remaining checksums back into the list (effectively running "shift" on the variable)
        # POSIX sh doesn't support indexing so do this instead to iterate both lists at once
        # POSIX sh doesn't support here-strings (<<<). We could also use the "cut" program but that's not a builtin
        IFS=' ' read -r checksum checksum_verification_failed_list << EOF
$checksum_verification_failed_list
EOF

        echo "    ${media}${unverified_ext} = $checksum" >&2
        echo "        Web search: https://duckduckgo.com/?q=%22$checksum%22" >&2
        echo "        Onion search: https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion/?q=%22$checksum%22" >&2
        echo "        mv ${media}${unverified_ext} $media" >&2
        echo "" >&2
    done

    echo "    Theses searches can be performed in a web/Tor browser or more securely using" >&2
    echo "    ddgr (Debian/Fedora packages available) terminal search tool if preferred." >&2
    echo "    Once validated, consider updating the checksums in Mido by submitting a pull request on GitHub." >&2

    # If you're looking for a single secondary source to cross-reference checksums then try here: https://files.rg-adguard.net/search
    # This site is recommended by the creator of Rufus in the Fido README and has worked well for me
}

consumer_download() {
    # Copyright (C) 2024 Elliot Killick <contact@elliotkillick.com>
    # Licensed under the MIT License. See LICENSE file for details.
    #
    # This function is from the Mido project:
    # https://github.com/ElliotKillick/Mido

    # Download newer consumer Windows versions from behind the gated Microsoft API
    #
    # Microsoft replaced the old HTML "contentinclude" API with a JSON API:
    #   https://www.microsoft.com/software-download-connector/api/...
    # The final GetProductDownloadLinksBySku request is protected by an anti-abuse
    # service (Microsoft Sentinel) which requires a short handshake against
    # ov-df.microsoft.com. This mirrors what the Fido project does.

    out_file="$1"
    # Either 8, 10, or 11
    windows_version="$2"
    # Optional per-call locale override. Defaults to the global MIDO_LANG so
    # existing callers keep working unchanged.
    locale="${3:-$MIDO_LANG}"
    # Optional per-call architecture override (x64 by default). Windows 10 still
    # ships 32-bit (x86) ISOs while Windows 11 is x64 only.
    arch="${4:-x64}"
    # Language name as expected by Microsoft's API (e.g. "English", "Spanish", "Spanish (Mexico)")
    api_language="$(locale_to_api_language "$locale")"

    url="https://www.microsoft.com/$locale/software-download/windows$windows_version"
    case "$windows_version" in
        8 | 10) url="${url}ISO" ;;
    esac

    user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:100.0) Gecko/20100101 Firefox/100.0"
    # uuidgen: For MacOS (installed by default) and other systems (e.g. with no /proc) that don't have a kernel interface for generating random UUIDs
    session_id="$(cat /proc/sys/kernel/random/uuid 2> /dev/null || uuidgen --random)"

    # Get product edition ID for latest release of given Windows version
    # Product edition ID: This specifies both the Windows release (e.g. 22H2) and edition ("multi-edition" is default, either Home/Pro/Edu/etc., we select "Pro" in the answer files) in one number
    # This is a request we make that Fido doesn't. Fido manually maintains a list of all the Windows release/edition product edition IDs in its script (see: $WindowsVersions array). This is helpful for downloading older releases (e.g. Windows 10 1909, 21H1, etc.) but we always want to get the newest release which is why we get this value dynamically
    # Also, keeping a "$WindowsVersions" array like Fido does would be way too much of a maintenance burden
    # Remove "Accept" header that curl sends by default (match Fido requests)
    iso_download_page_html="$(curl --user-agent "$user_agent" --header "Accept:" --max-filesize 1M --fail --proto =https --tlsv1.2 --http1.1 -- "$url")" || {
        error_code=$?
        if [ "$windows_version" = 8 ] && [ "$error_code" = 22 ]; then
            echo_err "Microsoft has retired the automated Windows 8.1 download. Please use the \"win81x64-enterprise-eval\" media instead."
        else
            handle_curl_error "$error_code"
        fi
        return 1
    }

    # tr: Filter for only numerics to prevent HTTP parameter injection
    # head -c was recently added to POSIX: https://austingroupbugs.net/view.php?id=407
    product_edition_id="$(echo "$iso_download_page_html" | grep -Eo '<option value="[0-9]+">Windows' | cut -d '"' -f 2 | head -n 1 | tr -cd '0-9' | head -c 16)"
    [ "$VERBOSE" ] && echo "Product edition ID: $product_edition_id" >&2

    if ! [ "$product_edition_id" ]; then
        echo_err "Could not determine the product edition ID (Microsoft may have changed their page). Please manually download this ISO in a web browser: $url"
        manual_verification="true"
        return 1
    fi

    # Permit Session ID
    # "org_id" is always the same value
    curl --output /dev/null --user-agent "$user_agent" --header "Accept:" --max-filesize 100K --fail --proto =https --tlsv1.2 --http1.1 -- "https://vlscppe.microsoft.com/tags?org_id=$ORG_ID&session_id=$session_id" || {
        # This should only happen if there's been some change to how this API works
        handle_curl_error $?
        return $?
    }

    # Microsoft Sentinel anti-abuse handshake (without it the download link request is rejected)
    mdt_js="$(curl --user-agent "$user_agent" --max-filesize 10K --fail --proto =https --tlsv1.2 --http1.1 -- "https://ov-df.microsoft.com/mdt.js?instanceId=$INSTANCE_ID&PageId=si&session_id=$session_id" 2> /dev/null)"
    sentinel_w="$(echo "$mdt_js" | grep -oE 'w=[A-F0-9]+' | head -n 1 | cut -d '=' -f 2)"
    sentinel_rticks="$(echo "$mdt_js" | grep -oE 'rticks=[0-9]+' | head -n 1 | cut -d '=' -f 2)"
    if [ "$sentinel_w" ] && [ "$sentinel_rticks" ]; then
        curl --output /dev/null --user-agent "$user_agent" --max-filesize 10K --fail --proto =https --tlsv1.2 --http1.1 -- "https://ov-df.microsoft.com/?session_id=$session_id&CustomerId=$INSTANCE_ID&PageId=si&w=$sentinel_w&mdt=$(date +%s)000&rticks=$sentinel_rticks" || true
    fi

    # Get language -> skuID association table (JSON)
    # SKU ID: This specifies the language of the ISO. The SKU for a given language changes with each Windows release
    language_skuid_table_json="$(curl --user-agent "$user_agent" --header "Accept:" --max-filesize 100K --fail --proto =https --tlsv1.2 --http1.1 -- "$API_BASE/getskuinformationbyproductedition?profile=$PROFILE_ID&productEditionId=$product_edition_id&SKU=undefined&friendlyFileName=undefined&Locale=$locale&sessionID=$session_id")" || {
        handle_curl_error $?
        return $?
    }

    # tr: split the JSON objects onto separate lines so each language entry can be matched independently
    # The trailing comma in the match disambiguates "Spanish" from "Spanish (Mexico)"
    # tr: keep only alphanumerics or "-" to prevent HTTP parameter injection
    sku_id="$(echo "$language_skuid_table_json" | tr '}' '\n' | grep -F "\"Language\":\"$api_language\"," | grep -o '"Id":"[0-9]*"' | head -n 1 | cut -d '"' -f 4 | tr -cd '[:alnum:]-' | head -c 16)"
    [ "$VERBOSE" ] && echo "SKU ID ($api_language): $sku_id" >&2

    if ! [ "$sku_id" ]; then
        echo_err "Could not find a $api_language download for this release. Try another language with MIDO_LANG or manually download this ISO in a web browser: $url"
        manual_verification="true"
        return 1
    fi

    # Get ISO download link
    # If any request is going to be blocked by Microsoft it's always this last one (the previous requests always seem to succeed)
    # --referer: Required by Microsoft servers to allow request
    iso_download_link_json="$(curl --user-agent "$user_agent" --referer "$url" --header "Accept:" --max-filesize 100K --fail --proto =https --tlsv1.2 --http1.1 -- "$API_BASE/GetProductDownloadLinksBySku?profile=$PROFILE_ID&productEditionId=undefined&SKU=$sku_id&friendlyFileName=undefined&Locale=$locale&sessionID=$session_id")" || {
        # This should only happen if there's been some change to how this API works
        handle_curl_error $?
        return $?
    }

    if echo "$iso_download_link_json" | grep -q "SentinelReject"; then
        echo_err "Microsoft's anti-abuse system (Sentinel) rejected the automated request based on your IP reputation. Wait 24-48 hours, use a VPN, or manually download this ISO in a web browser: $url"
        manual_verification="true"
        return 1
    fi

    if echo "$iso_download_link_json" | grep -q "715-123130"; then
        echo_err "Your IP address has been banned by Microsoft (code 715-123130). Wait 24-48 hours, use a VPN, or manually download this ISO in a web browser: $url"
        manual_verification="true"
        return 1
    fi

    # Select the ISO download URL for the requested architecture.
    # Microsoft names the ISO files ..._x32... / ..._x64... but also tags every
    # entry with a DownloadType (0 == 32-bit, 1 == 64-bit), so match on the file
    # name first and fall back to the DownloadType tag.
    case "$arch" in
        x86 | i386 | 32)
            arch_pattern="(_x32|_x86)"
            download_type=0
            ;;
        *)
            arch_pattern="_x64"
            download_type=1
            ;;
    esac

    # tr: split the JSON objects onto separate lines so each can be matched independently
    iso_download_line="$(echo "$iso_download_link_json" | tr '}' '\n' | grep -Ei -- "$arch_pattern" | head -n 1)"
    [ "$iso_download_line" ] || iso_download_line="$(echo "$iso_download_link_json" | tr '}' '\n' | grep -F "\"DownloadType\":$download_type" | head -n 1)"

    # sed: JSON/HTML decode "&" character
    # tr: Filter for only alphanumerics or punctuation
    iso_download_link="$(echo "$iso_download_line" | grep -o '"Uri":"[^"]*"' | head -n 1 | cut -d '"' -f 4 | sed 's/\\u0026/\&/g; s/&amp;/\&/g' | tr -cd '[:alnum:][:punct:]' | head -c 1024)"

    if ! [ "$iso_download_link" ]; then
        # This should only happen if there's been some change to the download endpoint web address
        echo_err "Microsoft servers gave us no download link to our request for an automated download. Please manually download this ISO in a web browser: $url"
        manual_verification="true"
        return 1
    fi

    echo_ok "Got latest ISO ($api_language) download link (valid for 24 hours): $iso_download_link"

    # Download ISO
    scurl_file "$out_file" "1.3" "$iso_download_link"
}

consumer_download_or_archive() {
    # Try Microsoft's official (Sentinel-gated) consumer download first.
    # If it fails (for example because Microsoft's Sentinel anti-abuse system
    # rejects the request based on IP reputation), transparently fall back to an
    # archive.org copy of the same release.
    out_file="$1"
    windows_version="$2"
    locale="$3"
    archive_url="$4"
    arch="${5:-x64}"

    # Preserve any manual-verification request made by earlier media so that a
    # successful fallback does not suppress it
    manual_verification_before="$manual_verification"

    echo_info "Trying Microsoft's official download first ($locale)..."
    if consumer_download "$out_file" "$windows_version" "$locale" "$arch"; then
        return 0
    fi

    echo_err "Microsoft's official download was unavailable (Sentinel block or API change)."
    echo_info "Falling back to an archive.org copy..."

    # The archive.org ISO is a different build than the one Microsoft's API
    # would have served, so never resume a partial download from the official
    # attempt (that would corrupt the file)
    rm -f "${out_file}${part_ext}"

    if scurl_file "$out_file" "1.3" "$archive_url"; then
        manual_verification="$manual_verification_before"
        echo_ok "Downloaded $out_file from the archive.org fallback."
        return 0
    fi

    return 1
}

enterprise_eval_download() {
    # Copyright (C) 2024 Elliot Killick <contact@elliotkillick.com>
    # Licensed under the MIT License. See LICENSE file for details.
    #
    # This function is from the Mido project:
    # https://github.com/ElliotKillick/Mido

    # Download enterprise evaluation Windows versions

    out_file="$1"
    windows_version="$2"
    enterprise_type="$3"

    # NOTE: Microsoft's Evaluation Center only ships Enterprise/Server evaluation
    # media in English, so this path intentionally stays on en-US.
    url="https://www.microsoft.com/en-us/evalcenter/download-$windows_version"

    iso_download_page_html="$(curl --location --max-filesize 1M --fail --proto =https --tlsv1.2 --http1.1 -- "$url")" || {
        handle_curl_error $?
        return $?
    }

    if ! [ "$iso_download_page_html" ]; then
        # This should only happen if there's been some change to where this download page is located
        echo_err "Windows enterprise evaluation download page gave us an empty response"
        return 1
    fi

    # Match both Microsoft's old link format (./fwlink/p/?LinkID=...&country=US)
    # and the current one (./fwlink/?LinkId=...&country=us)
    iso_download_links="$(echo "$iso_download_page_html" | grep -Eo "https://go\.microsoft\.com/fwlink/(p/)?\?[Ll]ink[Ii][Dd]=[0-9]+&clcid=0x[0-9a-z]+&culture=en-us&country=[Uu][Ss]")" || {
        # This should only happen if there's been some change to the download endpoint web address
        echo_err "Windows enterprise evaluation download page gave us no download link"
        return 1
    }

    # Limit untrusted size for input validation
    iso_download_links="$(echo "$iso_download_links" | head -c 1024)"

    case "$enterprise_type" in
        # Select x64 download link
        "enterprise") iso_download_link=$(echo "$iso_download_links" | head -n 2 | tail -n 1) ;;
        # Select x64 LTSC download link
        "ltsc") iso_download_link=$(echo "$iso_download_links" | head -n 4 | tail -n 1) ;;
        # Server: take only the first matching link (never pass a multi-line list to curl)
        *) iso_download_link=$(echo "$iso_download_links" | head -n 1) ;;
    esac

    # Follow redirect so proceeding log message is useful
    # This is a request we make this Fido doesn't
    # We don't need to set "--max-filesize" here because this is a HEAD request and the output is to /dev/null anyway
    iso_download_link="$(curl --location --output /dev/null --silent --write-out "%{url_effective}" --head --fail --proto =https --tlsv1.2 --http1.1 -- "$iso_download_link")" || {
        # This should only happen if the Microsoft servers are down
        handle_curl_error $?
        return $?
    }

    # Limit untrusted size for input validation
    iso_download_link="$(echo "$iso_download_link" | head -c 1024)"

    echo_ok "Got latest ISO download link: $iso_download_link"

    # Use highest TLS version for endpoints that support it
    case "$iso_download_link" in
        "https://download.microsoft.com"*) tls_version="1.2" ;;
        *) tls_version="1.3" ;;
    esac

    # Download ISO
    scurl_file "$out_file" "$tls_version" "$iso_download_link"
}

download_media() {
    echo_info "Downloading Windows media from official Microsoft servers..."

    media_download_failed_list=""

    for media in $media_list; do
        case "$media" in
            "$win7x64_ultimate")
                echo_info "Downloading Windows 7..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$(localized_media "$media")" 7 "$MIDO_LANG" "$(archive_fallback_url 7 "$MIDO_LANG" x64)" x64
                ;;
            "$win7x64_ultimate_esp")
                echo_info "Downloading Windows 7 Ultimate x64 Spanish (Español)..."
                # Windows 7 Ultimate SP1 x64 Spanish, archived on archive.org
                # Source: https://archive.org/details/es_windows_7_ultimate_with_sp1_dvd
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es_windows_7_ultimate_with_sp1_dvd/es_windows_7_ultimate_with_sp1_x64_dvd_u_677350.iso"
                ;;
            "$win7x86_ultimate")
                echo_info "Downloading Windows 7 Ultimate x86..."
                # Windows 7 Ultimate SP1 x86 (English), MSDN, archived on archive.org
                # Source: https://archive.org/details/en_windows_7_ultimate_with_sp1_dvd
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_7_ultimate_with_sp1_dvd/en_windows_7_ultimate_with_sp1_x86_dvd_u_677460.iso"
                ;;
            "$win7x86_ultimate_esp")
                echo_info "Downloading Windows 7 Ultimate x86 Spanish (Español)..."
                # Windows 7 Ultimate SP1 x86 Spanish, archived on archive.org
                # Source: https://archive.org/details/es_windows_7_ultimate_with_sp1_dvd
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es_windows_7_ultimate_with_sp1_dvd/es_windows_7_ultimate_with_sp1_x86_dvd_u_677462.iso"
                ;;
            "$vista_x64_sp2")
                echo_info "Downloading Windows Vista SP2 x64..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-vista-with-sp2-images-en-us/en_windows_vista_enterprise_sp2_x64_dvd_342332.iso"
                ;;
            "$vista_x86_sp2")
                echo_info "Downloading Windows Vista SP2 x86..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-vista-with-sp2-images-en-us/en_windows_vista_enterprise_sp2_x86_dvd_342329.iso"
                ;;
            "$vista_es_x64_sp2")
                echo_info "Downloading Windows Vista SP2 x64 Spanish..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinVistaEnterpriseSP2ESP/es_windows_vista_enterprise_sp2_x64_dvd_342415.iso"
                ;;
            "$vista_es_x86_sp2")
                echo_info "Downloading Windows Vista SP2 x86 Spanish..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinVistaEnterpriseSP2ESP/es_windows_vista_enterprise_sp2_x86_dvd_342413.iso"
                ;;
            "$vista_x64_sp2_n")
                echo_info "Downloading Windows Vista N SP2 x64 (Home Basic N + Business N)..."
                # Windows Vista N media: satisfies the EU ruling, excludes bundled media software
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/Windows_Vista_N_SP2_x64.iso/Windows_Vista_N_SP2_x64.iso"
                ;;
            "$vista_x64_sp2_business_n")
                echo_info "Downloading Windows Vista Business N SP2 x64..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinVistaBusinessNSP2ENG/en_windows_vista_business_n_sp2_x64_dvd_342326.iso"
                ;;
            "$vista_x86_sp2_business_n")
                echo_info "Downloading Windows Vista Business N SP2 x86..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinVistaBusinessNSP2ENG/en_windows_vista_business_n_sp2_x86_dvd_342323.iso"
                ;;
            "$vista_x64_sp1")
                echo_info "Downloading Windows Vista SP1 x64..."
                # Windows Vista SP1 x64 English (all editions), MSDN, archived on archive.org
                # Source: https://archive.org/details/en_windows_vista_with_service_pack_1_x64_dvd_x14-29595_202010
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_vista_with_service_pack_1_x64_dvd_x14-29595_202010/en_windows_vista_with_service_pack_1_x64_dvd_x14-29595.iso"
                ;;
            "$vista_x86_sp1")
                echo_info "Downloading Windows Vista SP1 x86..."
                # Windows Vista SP1 x86 English (all editions), MSDN, archived on archive.org
                # Source: https://archive.org/details/en_windows_vista_with_service_pack_1_x86_dvd_x14-29594_202010
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_vista_with_service_pack_1_x86_dvd_x14-29594_202010/en_windows_vista_with_service_pack_1_x86_dvd_x14-29594.iso"
                ;;
            "$vista_es_x64_sp1")
                echo_info "Downloading Windows Vista SP1 x64 Spanish..."
                # Windows Vista SP1 x64 Spanish (all editions), MSDN, archived on archive.org
                # Source: https://archive.org/details/es_windows_vista_with_service_pack_1_x64_dvd_x14-29756
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es_windows_vista_with_service_pack_1_x64_dvd_x14-29756/es_windows_vista_with_service_pack_1_x64_dvd_x14-29756.iso"
                ;;
            "$vista_es_x86_sp1")
                echo_info "Downloading Windows Vista SP1 x86 Spanish..."
                # Windows Vista SP1 x86 Spanish (all editions), MSDN, archived on archive.org
                # Source: https://archive.org/details/WinVistaAIOSP1ESPx86
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinVistaAIOSP1ESPx86/es_windows_vista_with_service_pack_1_x86_dvd_x14-29626.iso"
                ;;
            "$win7x64_sp1")
                echo_info "Downloading Windows 7 SP1 x64..."
                # Windows 7 SP1 All-in-One x64 English, archived on archive.org
                # Source: https://archive.org/details/win7_english_x64_202605
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win7_english_x64_202605/en_windows_7_aio_with_sp1_x64_dvd.iso"
                ;;
            "$win7x86_sp1")
                echo_info "Downloading Windows 7 SP1 x86..."
                # Windows 7 SP1 All-in-One x86 English, archived on archive.org
                # Source: https://archive.org/details/win7_english_x32_202604
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win7_english_x32_202604/en_windows_7_aio_with_sp1_x86_dvd.iso"
                ;;
            "$win81x64")
                echo_info "Downloading Windows 8.1..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$(localized_media "$media")" 8 "$MIDO_LANG" "$(archive_fallback_url 8 "$MIDO_LANG" x64)"
                ;;
            "$win81x64_ent_32_esp")
                echo_info "Downloading Windows 8.1 Enterprise 32-bit Spanish..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/w-81-ent-32-is-esp/es_windows_8.1_enterprise_with_update_x86_dvd_6050864.iso"
                ;;
            "$win81x64_ent_64_esp")
                echo_info "Downloading Windows 8.1 Enterprise 64-bit Spanish..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win-81-ent-64b-esp/es_windows_8.1_enterprise_with_update_x64_dvd_4048729.iso"
                ;;
            "$win10x64")
                echo_info "Downloading Windows 10..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$(localized_media "$media")" 10 "$MIDO_LANG" "$(archive_fallback_url 10 "$MIDO_LANG" x64)"
                ;;
            "$win10x64_esp")
                echo_info "Downloading Windows 10 Spanish (Spain)..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$media" 10 "es-ES" "$(archive_fallback_url 10 es-ES x64)"
                ;;
            "$win10x64_es_mx")
                echo_info "Downloading Windows 10 Spanish (Mexico)..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$media" 10 "es-MX" "$(archive_fallback_url 10 es-MX x64)"
                ;;
            "$win10x86")
                echo_info "Downloading Windows 10 32-bit..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$(localized_media "$media")" 10 "$MIDO_LANG" "$(archive_fallback_url 10 "$MIDO_LANG" x86)" x86
                ;;
            "$win10x86_esp")
                echo_info "Downloading Windows 10 32-bit Spanish (Spain)..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$media" 10 "es-ES" "$(archive_fallback_url 10 es-ES x86)" x86
                ;;
            "$win10x86_es_mx")
                echo_info "Downloading Windows 10 32-bit Spanish (Mexico)..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$media" 10 "es-MX" "$(archive_fallback_url 10 es-MX x86)" x86
                ;;
            "$win11x64")
                echo_info "Downloading Windows 11..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$(localized_media "$media")" 11 "$MIDO_LANG" "$(archive_fallback_url 11 "$MIDO_LANG" x64)"
                ;;
            "$win11x64_esp")
                echo_info "Downloading Windows 11 Spanish (Spain)..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$media" 11 "es-ES" "$(archive_fallback_url 11 es-ES x64)"
                ;;
            "$win11x64_es_mx")
                echo_info "Downloading Windows 11 Spanish (Mexico)..."
                # Microsoft's official (Sentinel-gated) download first, archive.org fallback
                consumer_download_or_archive "$media" 11 "es-MX" "$(archive_fallback_url 11 es-MX x64)"
                ;;

            "$win81x64_enterprise_eval")
                echo_info "Downloading Windows 8.1 Enterprise Evaluation..."
                # This download link is "Update 1": https://files.rg-adguard.net/file/166cbcab-1647-53d5-1785-6ef9e22a6500
                # A more up-to-date "Update 3" enterprise ISO exists but it was only ever distributed by Microsoft through MSDN which means it's impossible to get a Microsoft download link now: https://files.rg-adguard.net/file/549a58f2-7813-3e77-df6c-50609bc6dd7c
                # win81x64 is "Update 3" but that's isn't an enterprise version (although technically it's possible to modify a few files in the ISO to get any edition)
                # If you want "Update 3" enterprise though (not from Microsoft servers), then you should still be able to get it from here: https://archive.org/details/en_windows_8.1_enterprise_with_update_x64_dvd_6054382_202110
                # "Update 1" enterprise also seems to be the ISO used by other projects
                # Old source, used to be here but Microsoft deleted it: http://technet.microsoft.com/en-us/evalcenter/hh699156.aspx
                # Source: https://gist.github.com/eyecatchup/11527136b23039a0066f
                scurl_file "$(localized_media "$media")" "1.2" "https://download.microsoft.com/download/B/9/9/B999286E-0A47-406D-8B3D-5B5AD7373A4A/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_ENTERPRISE_EVAL_EN-US-IR3_CENA_X64FREE_EN-US_DV9.ISO"
                ;;
            "$win81x86_enterprise_eval")
                echo_info "Downloading Windows 8.1 Enterprise Evaluation 32-bit..."
                # Windows 8.1 Enterprise Evaluation x86, official Microsoft download
                scurl_file "$(localized_media "$media")" "1.2" "https://download.microsoft.com/download/B/9/9/B999286E-0A47-406D-8B3D-5B5AD7373A4A/9600.17050.WINBLUE_REFRESH.140317-1640_X86FRE_ENTERPRISE_EVAL_EN-US-IR3_CENA_X86FREE_EN-US_DV9.ISO"
                ;;
            "$win81x64_enterprise_n_eval")
                echo_info "Downloading Windows 8.1 Enterprise N x64..."
                # Microsoft retired the 8.1 N Evaluation; use the live Windows 8.1 Enterprise N x64 ISO
                # Source: https://archive.org/details/en-gb_windows_8_1_enterprise_n_x64_dvd_2971847
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en-gb_windows_8_1_enterprise_n_x64_dvd_2971847/en-gb_windows_8_1_enterprise_n_x64_dvd_2971847.iso"
                ;;
            "$win81x86_enterprise_n_eval")
                echo_info "Downloading Windows 8.1 Enterprise N x86..."
                # Microsoft retired the 8.1 N Evaluation; use the live Windows 8.1 Enterprise N x86 ISO
                # Source: https://archive.org/details/en-gb_windows_8_1_enterprise_n_x86_dvd_2971852
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en-gb_windows_8_1_enterprise_n_x86_dvd_2971852/en-gb_windows_8_1_enterprise_n_x86_dvd_2971852.iso"
                ;;
            "$win81x64_industry_enterprise_eval")
                echo_info "Downloading Windows 8.1 Industry Enterprise Evaluation..."
                # Microsoft retired the 8.1 Industry Evaluation; use Windows Embedded 8.1 Industry Enterprise x64
                # Source: https://archive.org/details/en_windows_embedded_8.1_industry_enterprise_with_update_x64_dvd_6052160
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_embedded_8.1_industry_enterprise_with_update_x64_dvd_6052160/en_windows_embedded_8.1_industry_enterprise_with_update_x64_dvd_6052160.iso"
                ;;
            "$win81x86_industry_enterprise_eval")
                echo_info "Downloading Windows 8.1 Industry Enterprise Evaluation 32-bit..."
                # Microsoft retired the 8.1 Industry Evaluation; use Windows Embedded 8.1 Industry Enterprise x86
                # Source: https://archive.org/details/en_windows_embedded_8.1_industry_enterprise_with_update_x86_dvd_6052252
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_embedded_8.1_industry_enterprise_with_update_x86_dvd_6052252/en_windows_embedded_8.1_industry_enterprise_with_update_x86_dvd_6052252.iso"
                ;;
            "$win81x64_industry_pro_eval")
                echo_info "Downloading Windows 8.1 Industry Professional Evaluation..."
                # Microsoft retired the 8.1 Industry Evaluation; use Windows Embedded 8.1 Industry Pro x64
                # Source: https://archive.org/details/en_windows_embedded_8.1_industry_pro_with_update_x64_dvd_6052086_202107
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_embedded_8.1_industry_pro_with_update_x64_dvd_6052086_202107/en_windows_embedded_8.1_industry_pro_with_update_x64_dvd_6052086.iso"
                ;;
            "$win81x86_industry_pro_eval")
                echo_info "Downloading Windows 8.1 Industry Professional Evaluation 32-bit..."
                # Microsoft retired the 8.1 Industry Evaluation; use Windows Embedded 8.1 Industry Pro x86
                # Source: https://archive.org/details/en_windows_embedded_8_1_industry_pro_x86_dvd_2707505
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_embedded_8_1_industry_pro_x86_dvd_2707505/en_windows_embedded_8_1_industry_pro_x86_dvd_2707505.iso"
                ;;
            "$win10x64_enterprise_eval")
                echo_info "Downloading Windows 10 Enterprise Evaluation..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-10-21-h-2-enterprise-ltsc/Windows_10_21H2_Enterprise_LTSC.iso"
                ;;
            "$win10x86_enterprise_eval")
                echo_info "Downloading Windows 10 Enterprise 32-bit Evaluation..."
                # Official Microsoft Windows 10 Enterprise LTSC 21H2 x86 (32-bit) evaluation ISO, archived on archive.org
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/Win10-EnterpriseLTSC-21H2/19044.1288.211006-0501.21h2_release_svc_refresh_CLIENT_LTSC_EVAL_x86FRE_en-us.iso"
                ;;
            "$win11x64_enterprise_eval")
                echo_info "Downloading Windows 11 Enterprise Evaluation..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en-us_windows_11_enterprise_ltsc_2024_x64_dvd_965cfb00/en-us_windows_11_enterprise_ltsc_2024_x64_dvd_965cfb00.iso"
                ;;
            "$win10x64_enterprise_ltsc_eval")
                echo_info "Downloading Windows 10 Enterprise LTSC Evaluation..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/Win10-EnterpriseLTSC-21H2/19044.1288.211006-0501.21h2_release_svc_refresh_CLIENT_LTSC_EVAL_x64FRE_en-us.iso"
                ;;
            "$win11x64_enterprise_ltsc_eval")
                echo_info "Downloading Windows 11 Enterprise LTSC Evaluation..."
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en-us_windows_11_enterprise_ltsc_2024_x64_dvd_965cfb00/en-us_windows_11_enterprise_ltsc_2024_x64_dvd_965cfb00.iso"
                ;;
            "$win11x64_iot_enterprise_ltsc_eval")
                echo_info "Downloading Windows 11 IoT Enterprise LTSC Evaluation..."
                scurl_file "$(localized_media "$media")" "1.3" "https://software-static.download.prss.microsoft.com/dbazure/998969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_IOT_LTSC_EVAL_x64FRE_en-us.iso"
                ;;
            "$win11x64_iot_enterprise_26h2")
                echo_info "Downloading Windows 11 IoT Enterprise 26H2..."
                # Annual channel (non-LTSC) 26H2, English only. Microsoft only distributes it to
                # OEM/VLSC, so we use this archive.org build based on the 24H2 installer carrying
                # the 26H2 payload (not the pristine MSDN ISO)
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-11-iot-enterprise-ltsc-2026-26h2/Windows%2011%20IoT%20Enterprise%20LTSC%202026%2026H2%2026300.9278.iso"
                ;;
            "$win11x64_iot_enterprise_ltsc_2024")
                echo_info "Downloading Windows 11 IoT Enterprise LTSC 2024..."
                # Full (non-evaluation) Windows 11 IoT Enterprise LTSC 2024, English x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-11-iot-enterprise-ltsc-2024/en-us_windows_11_iot_enterprise_ltsc_2024_x64_dvd_f6b14814.iso"
                ;;
            "$win10x64_iot_enterprise_22h2")
                echo_info "Downloading Windows 10 IoT Enterprise 22H2..."
                # Full (non-evaluation) Windows 10 IoT Enterprise 22H2 (annual channel), English x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2010/Windows%2010%20IoT%20Enterprise%2022H2/en-us_windows_10_iot_enterprise_version_22h2_x64_dvd_51cc370f.iso"
                ;;
            "$win10x64_iot_enterprise_ltsc_2021")
                echo_info "Downloading Windows 10 IoT Enterprise LTSC 2021..."
                # Full (non-evaluation) Windows 10 IoT Enterprise LTSC 2021, English x64, official ISO
                # (Microsoft never published an x86/32-bit ISO for this edition)
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2010/Windows%2010%20IoT%20Enterprise%20LTSC%202021/en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso"
                ;;
            "$win10x64_iot_enterprise_ltsc_2019")
                echo_info "Downloading Windows 10 IoT Enterprise LTSC 2019..."
                # Full (non-evaluation) Windows 10 IoT Enterprise LTSC 2019, English x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2010/Windows%2010%20IoT%20Enterprise%20LTSC%202019/en_windows_10_iot_enterprise_ltsc_2019_x64_dvd_a1aa819f.iso"
                ;;
            "$win10x86_iot_enterprise_ltsc_2019")
                echo_info "Downloading Windows 10 IoT Enterprise LTSC 2019 32-bit..."
                # Full (non-evaluation) Windows 10 IoT Enterprise LTSC 2019, English x86 (32-bit), official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2010/Windows%2010%20IoT%20Enterprise%20LTSC%202019/en_windows_10_iot_enterprise_ltsc_2019_x86_dvd_2255a237.iso"
                ;;
            "$win11x64_enterprise_ltsc_2024")
                echo_info "Downloading Windows 11 Enterprise LTSC 2024..."
                # Full (non-evaluation) Windows 11 Enterprise LTSC 2024, English x64, official ISO
                # (Windows 11 has no 32-bit build)
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2011/Windows%2011%20Enterprise%20LTSC%202024/en-us_windows_11_enterprise_ltsc_2024_x64_dvd_965cfb00.iso"
                ;;
            "$win11x64_enterprise_ltsc_2024_esp")
                echo_info "Downloading Windows 11 Enterprise LTSC 2024 (Spanish)..."
                # Full (non-evaluation) Windows 11 Enterprise LTSC 2024, Spanish (Spain) x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es-es_windows_11_enterprise_ltsc_2024_x64_dvd_77392d61/es-es_windows_11_enterprise_ltsc_2024_x64_dvd_77392d61.iso"
                ;;
            "$win11x64_enterprise_ltsc_2024_es_mx")
                echo_info "Downloading Windows 11 Enterprise LTSC 2024 (Mexican Spanish)..."
                # Full (non-evaluation) Windows 11 Enterprise LTSC 2024, Spanish (Mexico) x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es-mx_windows_11_enterprise_ltsc_2024_x64_dvd_3310c094/es-mx_windows_11_enterprise_ltsc_2024_x64_dvd_3310c094.iso"
                ;;
            "$win10x64_enterprise_ltsc_2021")
                echo_info "Downloading Windows 10 Enterprise LTSC 2021..."
                # Full (non-evaluation) Windows 10 Enterprise LTSC 2021 (21H2), English x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2010/Windows%2010%20Enterprise%20LTSC%202021/en-us_windows_10_enterprise_ltsc_2021_x64_dvd_d289cf96.iso"
                ;;
            "$win10x64_enterprise_ltsc_2021_esp")
                echo_info "Downloading Windows 10 Enterprise LTSC 2021 (Spanish)..."
                # Full (non-evaluation) Windows 10 Enterprise LTSC 2021 (21H2), Spanish (Spain) x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es-es_windows_10_enterprise_ltsc_2021_x64_dvd_51d721ea/es-es_windows_10_enterprise_ltsc_2021_x64_dvd_51d721ea.iso"
                ;;
            "$win10x64_enterprise_ltsc_2021_es_mx")
                echo_info "Downloading Windows 10 Enterprise LTSC 2021 (Mexican Spanish)..."
                # Full (non-evaluation) Windows 10 Enterprise LTSC 2021 (21H2), Spanish (Mexico) x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es-mx_windows_10_enterprise_ltsc_2021_x64_dvd_f6aaf384/es-mx_windows_10_enterprise_ltsc_2021_x64_dvd_f6aaf384.iso"
                ;;
            "$win10x86_enterprise_ltsc_2021")
                echo_info "Downloading Windows 10 Enterprise LTSC 2021 32-bit..."
                # Full (non-evaluation) Windows 10 Enterprise LTSC 2021 (21H2), English x86 (32-bit), official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2010/Windows%2010%20Enterprise%20LTSC%202021/en-us_windows_10_enterprise_ltsc_2021_x86_dvd_9f4aa95f.iso"
                ;;
            "$win10x86_enterprise_ltsc_2021_esp")
                echo_info "Downloading Windows 10 Enterprise LTSC 2021 32-bit (Spanish)..."
                # Full (non-evaluation) Windows 10 Enterprise LTSC 2021 (21H2), Spanish (Spain) x86 (32-bit), official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es-es_windows_10_enterprise_ltsc_2021_x86_dvd_243c83eb/es-es_windows_10_enterprise_ltsc_2021_x86_dvd_243c83eb.iso"
                ;;
            "$win10x86_enterprise_ltsc_2021_es_mx")
                echo_info "Downloading Windows 10 Enterprise LTSC 2021 32-bit (Mexican Spanish)..."
                # Full (non-evaluation) Windows 10 Enterprise LTSC 2021 (21H2), Spanish (Mexico) x86 (32-bit), official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es-mx_windows_10_enterprise_ltsc_2021_x86_dvd_93a5debe/es-mx_windows_10_enterprise_ltsc_2021_x86_dvd_93a5debe.iso"
                ;;
            "$win10x64_enterprise_ltsb_2016")
                echo_info "Downloading Windows 10 Enterprise LTSB 2016..."
                # Full (non-evaluation) Windows 10 Enterprise LTSB 2016 (1607), English x64, official ISO.
                # Note: this is the same product Microsoft later called "LTSC"; "LTSC 2016" and "LTSB 2016" are identical
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2010/Windows%2010%20Enterprise%20LTSB%202016/en_windows_10_enterprise_2016_ltsb_x64_dvd_9059483.iso"
                ;;
            "$win10x64_enterprise_ltsb_2016_esp")
                echo_info "Downloading Windows 10 Enterprise LTSB 2016 (Spanish)..."
                # Full (non-evaluation) Windows 10 Enterprise LTSB 2016 (1607), Spanish x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es-es_windows_10_enterprise_2016_ltsb/es_windows_10_enterprise_2016_ltsb_x64_dvd_9059485.iso"
                ;;
            "$win10x86_enterprise_ltsb_2016")
                echo_info "Downloading Windows 10 Enterprise LTSB 2016 32-bit..."
                # Full (non-evaluation) Windows 10 Enterprise LTSB 2016 (1607), English x86 (32-bit), official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2010/Windows%2010%20Enterprise%20LTSB%202016/en_windows_10_enterprise_2016_ltsb_x86_dvd_9060010.iso"
                ;;
            "$win10x86_enterprise_ltsb_2016_esp")
                echo_info "Downloading Windows 10 Enterprise LTSB 2016 32-bit (Spanish)..."
                # Full (non-evaluation) Windows 10 Enterprise LTSB 2016 (1607), Spanish x86 (32-bit), official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es-es_windows_10_enterprise_2016_ltsb/es_windows_10_enterprise_2016_ltsb_x86_dvd_9060020.iso"
                ;;
            "$win10x64_enterprise_ltsb_2015")
                echo_info "Downloading Windows 10 Enterprise LTSB 2015..."
                # Full (non-evaluation) Windows 10 Enterprise LTSB 2015 (1507), English x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2010/Windows%2010%20Enterprise%20LTSB%202015/en_windows_10_enterprise_2015_ltsb_x64_dvd_6848446.iso"
                ;;
            "$win10x64_enterprise_ltsb_2015_esp")
                echo_info "Downloading Windows 10 Enterprise LTSB 2015 (Spanish)..."
                # Full (non-evaluation) Windows 10 Enterprise LTSB 2015 (1507), Spanish x64, official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-10-1507-enterprise-ltsb-32-64-bits/es_windows_10_enterprise_2015_ltsb_x64_dvd_6850876.iso"
                ;;
            "$win10x86_enterprise_ltsb_2015")
                echo_info "Downloading Windows 10 Enterprise LTSB 2015 32-bit..."
                # Full (non-evaluation) Windows 10 Enterprise LTSB 2015 (1507), English x86 (32-bit), official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/massgrave.dev-windows-x64-and-x86-archive/Windows/Windows%2010/Windows%2010%20Enterprise%20LTSB%202015/en_windows_10_enterprise_2015_ltsb_x86_dvd_6848454.iso"
                ;;
            "$win10x86_enterprise_ltsb_2015_esp")
                echo_info "Downloading Windows 10 Enterprise LTSB 2015 32-bit (Spanish)..."
                # Full (non-evaluation) Windows 10 Enterprise LTSB 2015 (1507), Spanish x86 (32-bit), official ISO
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-10-1507-enterprise-ltsb-32-64-bits/es_windows_10_enterprise_2015_ltsb_x86_dvd_6850896.iso"
                ;;

            "$win2008r2")
                echo_info "Downloading Windows Server 2008 R2..."
                # Old source, used to be here but Microsoft deleted it: https://www.microsoft.com/en-us/download/details.aspx?id=11093
                # Microsoft took down the original download link provided by that source too but this new one has the same checksum
                # Source: https://github.com/rapid7/metasploitable3/pull/563
                scurl_file "$(localized_media "$media")" "1.2" "https://download.microsoft.com/download/4/1/D/41DEA7E0-B30D-4012-A1E3-F24DC03BA1BB/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso"
                ;;
            "$win2008r2_espa")
                echo_info "Downloading Windows Server 2008 R2 Spanish (Español)..."
                # Official Microsoft Evaluation ISO in Spanish, archived on archive.org
                # Same build as the English direct link above (7601.17514.101119-1850)
                # Source: https://archive.org/details/wserver2008r2
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/wserver2008r2/7601.17514.101119-1850_x64fre_server_eval_es-es-GRMSXEVAL_ES_DVD.iso"
                ;;
            "$win2008_server_x64")
                echo_info "Downloading Windows Server 2008 x64..."
                # Windows Server 2008 (non-R2) with SP2, all editions (x64), archived on archive.org
                # Source: https://archive.org/details/WindowsServer2008withSP2x86
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WindowsServer2008withSP2x86/en_windows_server_2008_with_sp2_x64_dvd_342336.iso"
                ;;
            "$win2008_server_x64_espa")
                echo_info "Downloading Windows Server 2008 x64 Spanish (Español)..."
                # Windows Server 2008 (non-R2) with SP2, all editions (x64) in Spanish, archived on archive.org
                # Source: https://archive.org/details/WinServer2k8SP2ESPx86x64
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinServer2k8SP2ESPx86x64/es_windows_server_2008_with_sp2_x64_dvd_342419.iso"
                ;;
            "$win2008_server_x86")
                echo_info "Downloading Windows Server 2008 x86..."
                # Windows Server 2008 (non-R2) with SP2, all editions (x86), archived on archive.org
                # Source: https://archive.org/details/WindowsServer2008withSP2x86
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WindowsServer2008withSP2x86/en_windows_server_2008_with_sp2_x86_dvd_342333.iso"
                ;;
            "$win2008_server_x86_espa")
                echo_info "Downloading Windows Server 2008 x86 Spanish (Español)..."
                # Windows Server 2008 (non-R2) with SP2, all editions (x86) in Spanish, archived on archive.org
                # Source: https://archive.org/details/WinServer2k8SP2ESPx86x64
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinServer2k8SP2ESPx86x64/es_windows_server_2008_with_sp2_x86_dvd_342416.iso"
                ;;
            "$win2003_server")
                echo_info "Downloading Windows Server 2003 Enterprise..."
                # Windows Server 2003 Enterprise Edition RTM (retail), archived on archive.org
                # Source: https://archive.org/details/microsoft-windows-server-2003-enterprise-edition-retail-license-english-5.2.3790
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/microsoft-windows-server-2003-enterprise-edition-retail-license-english-5.2.3790/en_windows_server_2003_enterprise.iso"
                ;;
            "$win2003_server_espa")
                echo_info "Downloading Windows Server 2003 Enterprise Spanish (Español)..."
                # Windows Server 2003 Enterprise Edition RTM in Spanish, archived on archive.org
                # Source: https://archive.org/details/WinServer2003EnterpriseRTMESP
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinServer2003EnterpriseRTMESP/es_windows_server_2003_enterprise.iso"
                ;;
            "$win2003_server_x64")
                echo_info "Downloading Windows Server 2003 R2 Enterprise x64..."
                # Windows Server 2003 R2 Enterprise x64 Edition with SP2 (VL), archived on archive.org
                # Source: https://archive.org/details/en_win_srv_2003_r2_enterprise_x64_with_sp2_vl
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_win_srv_2003_r2_enterprise_x64_with_sp2_vl/en_win_srv_2003_r2_enterprise_x64_with_sp2_vl_cd1_x13-48614.iso"
                ;;
            "$win2003_server_x64_espa")
                echo_info "Downloading Windows Server 2003 R2 Enterprise x64 Spanish (Español)..."
                # Windows Server 2003 R2 Enterprise x64 with SP2 in Spanish, archived on archive.org
                # Source: https://archive.org/details/es_win_srv_2003_r2_enterprise_x64_with_sp2_vl
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es_win_srv_2003_r2_enterprise_x64_with_sp2_vl/es_win_srv_2003_r2_enterprise_x64_with_sp2_vl_cd1_x13-48642.iso"
                ;;
            "$win81x64")
                echo_info "Downloading Windows 8.1 x64..."
                # Windows 8.1 x64 (ended mainstream support 01-09-2018, extended support 01-01-2023)
                # Archived on archive.org
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_8.1_x64_dvd_2707217/en_windows_8.1_x64_dvd_2707217.iso"
                ;;
            "$win81x86")
                echo_info "Downloading Windows 8.1 x86 32-bit..."
                # Windows 8.1 x86 32-bit - Microsoft official first, archive.org fallback
                consumer_download_or_archive "$(localized_media "$media")" 8 "$MIDO_LANG" "$(archive_fallback_url 8 "$MIDO_LANG" x86)" x86
                ;;
            "$win2000_server")
                echo_info "Downloading Windows 2000 Server SP4..."
                # Windows 2000 Server SP4 (retail), archived on archive.org
                # Source: https://archive.org/details/win_2000_server_sp4_english_202605
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win_2000_server_sp4_english_202605/Windows2000ServerSP4.ISO"
                ;;
            "$win2000_advanced_server")
                echo_info "Downloading Windows 2000 Advanced Server SP4..."
                # Windows 2000 Advanced Server SP4 (retail, English), archived on archive.org
                # Source: https://archive.org/details/windows-2000-advanced-server-sp-4_202508
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-2000-advanced-server-sp-4_202508/Windows%202000%20Advanced%20Server%20SP4.iso"
                ;;
            "$win2000_server_espa")
                echo_info "Downloading Windows 2000 Server SP4 Spanish (Español)..."
                # Windows 2000 Server SP4 in Spanish, archived on archive.org
                # Source: https://archive.org/details/w2k-srv-sp4-esp
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/w2k-srv-sp4-esp/W2K-SRV-SP4-ESP.ISO"
                ;;
            "$win2000_advanced_server_espa")
                echo_info "Downloading Windows 2000 Advanced Server SP4 Spanish (Español)..."
                # Windows 2000 Advanced Server SP4 in Spanish, archived on archive.org
                # Source: https://archive.org/details/w2k-advsrv-sp4-esp
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/w2k-advsrv-sp4-esp/W2K-ASERV-ESP.iso"
                ;;
            "$win2000_datacenter")
                echo_info "Downloading Windows 2000 Datacenter Server RTM OEM (SP1)..."
                # Windows 2000 Datacenter Server RTM (OEM channel, includes SP1), archived on archive.org
                # Source: https://archive.org/details/windows-2000-datacenter-server
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-2000-datacenter-server/en_win2000_dtc_srv_rtm_oem.iso"
                ;;
            "$win2000_datacenter_sp4")
                echo_info "Downloading Windows 2000 Datacenter Server SP4..."
                # Windows 2000 Datacenter Server SP4 (build 2195.6717), archived on archive.org
                # Source: https://archive.org/details/5.00.2195.6717-x-86fre-dtcserver-en-us
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/5.00.2195.6717-x-86fre-dtcserver-en-us/5.00.2195.6717_x86fre_DTCServer_en-us.iso"
                ;;
            "$win2000_pro")
                echo_info "Downloading Windows 2000 Professional SP4..."
                # Windows 2000 Professional SP4, archived on archive.org
                # Source: https://archive.org/details/enwin2000prosp4_202001
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/enwin2000prosp4_202001/EN_WIN2000_PRO_SP4.ISO"
                ;;
            "$win2000_pro_espa")
                echo_info "Downloading Windows 2000 Professional SP4 Spanish (Español)..."
                # Windows 2000 Professional SP4 in Spanish, archived on archive.org
                # Source: https://archive.org/details/Win2000ProSP4ESPSEL
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/Win2000ProSP4ESPSEL/es_win2000_pro_sp4_sel.iso"
                ;;
            "$win2000_pro_oem")
                echo_info "Downloading Windows 2000 Professional SP3 OEM..."
                # Windows 2000 Professional SP3 (OEM channel), archived on archive.org
                # Source: https://archive.org/details/win_2000_professional_sp3_english_202605
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win_2000_professional_sp3_english_202605/Windows2000ProfessionalSP3.iso"
                ;;
            "$win2000_pro_retail")
                echo_info "Downloading Windows 2000 Professional SP4 Retail..."
                # Windows 2000 Professional SP4 (retail channel), archived on archive.org
                # Source: https://archive.org/details/win_2000_professional_sp4_english_202605
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win_2000_professional_sp4_english_202605/Windows2000ProfessionalSP4.ISO"
                ;;
            "$win2000_pro_oem_espa")
                echo_info "Downloading Windows 2000 Professional SP1 OEM Spanish (Español)..."
                # Windows 2000 Professional SP1 (OEM channel) in Spanish, archived on archive.org
                # Source: https://archive.org/details/Win2000ProSP1ESPOEM
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/Win2000ProSP1ESPOEM/SP1POEM_ES.ISO"
                ;;
            "$win2000_pro_retail_espa")
                echo_info "Downloading Windows 2000 Professional RTM Retail Spanish (Español)..."
                # Windows 2000 Professional RTM (FPP retail channel) in Spanish, archived on archive.org
                # Source: https://archive.org/details/windows-2000-rtm-spanish
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-2000-rtm-spanish/es_win2000_pro_rtm_ret.iso"
                ;;
            "$win_xp_pro")
                echo_info "Downloading Windows XP Professional SP3..."
                # Windows XP Professional with Service Pack 3 x86 (English), archived on archive.org
                # Source: https://archive.org/details/en_windows_xp_pro_sp3
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_xp_pro_sp3/en_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-73974.iso"
                ;;
            "$win_xp_pro_espa")
                echo_info "Downloading Windows XP Professional SP3 Spanish (Español)..."
                # Windows XP Professional with Service Pack 3 (Spanish, volume license),
                # archived on archive.org
                # Source: https://archive.org/details/es_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-74009_202104
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-74009_202104/es_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-74009.iso"
                ;;
            "$win_xp_pro_32")
                echo_info "Downloading Windows XP Professional x86..."
                # Windows XP Professional with Service Pack 3 x86 (English), archived on archive.org
                # Source: https://archive.org/details/en_windows_xp_professional_with_service_pack_3_x86_cd_x14-80428_202501
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_xp_professional_with_service_pack_3_x86_cd_x14-80428_202501/en_windows_xp_professional_with_service_pack_3_x86_cd_x14-80428.iso"
                ;;
            "$win_xp_pro_32_espa")
                echo_info "Downloading Windows XP Professional x86 SP3 Spanish (Español)..."
                # Windows XP Professional with Service Pack 3 (Spanish, volume license),
                # archived on archive.org
                # Source: https://archive.org/details/es_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-74009_202104
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/es_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-74009_202104/es_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-74009.iso"
                ;;
            "$win_xp_pro_64")
                echo_info "Downloading Windows XP Professional x64 SP2..."
                # Windows XP Professional x64 Edition with SP2 (English), archived on archive.org
                # Source: https://archive.org/details/en_win_xp_pro_x64_with_sp2_vl
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_win_xp_pro_x64_with_sp2_vl/en_win_xp_pro_x64_with_sp2_vl_x13-41611.iso"
                ;;
            "$win_xp_home")
                echo_info "Downloading Windows XP Home Edition SP3..."
                # Windows XP Home Edition with SP3 (English, retail CD), archived on archive.org
                # Source: https://archive.org/details/xphomesp3
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/xphomesp3/en_windows_xp_home_with_service_pack_3_x86_cd_x14-92413.iso"
                ;;
            "$win_xp_home_espa")
                echo_info "Downloading Windows XP Home Edition SP3 Spanish (Español)..."
                # Windows XP Home Edition with SP3 in Spanish, archived on archive.org
                # Source: https://archive.org/details/xphomesp3
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/xphomesp3/es_windows_xp_home_with_service_pack_3_x86_cd_x14-92427.iso"
                ;;
            "$win_xp_home_oem")
                echo_info "Downloading Windows XP Home Edition RTM OEM..."
                # Windows XP Home Edition RTM (OEM channel, English), archived on archive.org
                # Source: https://archive.org/details/en_winxp_home_oem_iso
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_winxp_home_oem_iso/en_winxp_home_oem_iso.iso"
                ;;
            "$win_xp_home_retail")
                echo_info "Downloading Windows XP Home Edition SP3 Retail..."
                # Windows XP Home Edition with SP3 (retail channel, English), archived on archive.org
                # Source: https://archive.org/details/5.1.2600.5512.xpsp.-080413-2111-x-86fre-client-professional-retail-en-us-grtmpfpp-en
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/5.1.2600.5512.xpsp.-080413-2111-x-86fre-client-professional-retail-en-us-grtmpfpp-en/5.1.2600.5512.xpsp.080413-2111_x86fre_client-home_retail_en-us-GRTMHFPP_EN.iso"
                ;;
            "$win_xp_home_oem_espa")
                echo_info "Downloading Windows XP Home Edition SP2 OEM Spanish (Español)..."
                # Windows XP Home Edition with SP2 (OEM channel) in Spanish, archived on archive.org
                # Source: https://archive.org/details/vx2hoemes
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/vx2hoemes/VX2HOEM_ES.iso"
                ;;
            "$win_xp_home_retail_espa")
                echo_info "Downloading Windows XP Home Edition SP3 Retail Spanish (Español)..."
                # Windows XP Home Edition with SP3 (retail CD) in Spanish, archived on archive.org
                # Source: https://archive.org/details/xphomesp3
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/xphomesp3/es_windows_xp_home_with_service_pack_3_x86_cd_x14-92427.iso"
                ;;
            "$win_xp_pro_oem")
                echo_info "Downloading Windows XP Professional SP2 OEM..."
                # Windows XP Professional with SP2 (OEM channel, English), archived on archive.org
                # Source: https://archive.org/details/windows-xp-professional-with-service-pack-2-2007-oem-english
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-xp-professional-with-service-pack-2-2007-oem-english/VRMPOEM_EN.iso"
                ;;
            "$win_xp_pro_retail")
                echo_info "Downloading Windows XP Professional SP3 Retail..."
                # Windows XP Professional with SP3 (retail channel, English), archived on archive.org
                # Source: https://archive.org/details/en_windows_xp_professional_with_service_pack_3_x86_cd_x14-80428_202010
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_xp_professional_with_service_pack_3_x86_cd_x14-80428_202010/en_windows_xp_professional_with_service_pack_3_x86_cd_x14-80428.iso"
                ;;
            "$win_xp_pro_oem_espa")
                echo_info "Downloading Windows XP Professional SP2 OEM Spanish (Español)..."
                # Windows XP Professional with SP2 (OEM channel) in Spanish, archived on archive.org
                # Source: https://archive.org/details/WinXPProSP2ESPOEM
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinXPProSP2ESPOEM/VRMPOEM_ES.iso"
                ;;
            "$win_xp_pro_retail_espa")
                echo_info "Downloading Windows XP Professional SP1 Retail Spanish (Español)..."
                # Windows XP Professional with SP1 (retail channel) in Spanish, archived on archive.org
                # Source: https://archive.org/details/WinXPProSP1ESP
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinXPProSP1ESP/WinXP_Pro_SP1_Ret.iso"
                ;;
            "$win7x64_pro")
                echo_info "Downloading Windows 7 Professional..."
                # Windows 7 Professional SP1 x64 (English), archived on archive.org
                # Source: https://archive.org/details/en_windows_7_professional_with_sp1_x64_dvd_u_676939_202504
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_7_professional_with_sp1_x64_dvd_u_676939_202504/en_windows_7_professional_with_sp1_x64_dvd_u_676939.iso"
                ;;
            "$win7x64_pro_esp")
                echo_info "Downloading Windows 7 Professional Spanish (Español)..."
                # Windows 7 Professional SP1 x64 Spanish, archived on archive.org
                # Source: https://archive.org/details/windows-7-pro-sp1-spanish
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-7-pro-sp1-spanish/Win7_Pro_SP1_Spanish_x64.iso"
                ;;
            "$win7x86_pro")
                echo_info "Downloading Windows 7 Professional x86..."
                # Windows 7 Professional SP1 x86 (English), archived on archive.org
                # Source: https://archive.org/details/en_windows_7_professional_with_sp1_x64_dvd_u_676939_202504
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_7_professional_with_sp1_x64_dvd_u_676939_202504/en_windows_7_professional_with_sp1_x86_dvd_u_677056.iso"
                ;;
            "$win7x86_pro_esp")
                echo_info "Downloading Windows 7 Professional x86 Spanish (Español)..."
                # Windows 7 Professional SP1 x86 Spanish, archived on archive.org
                # Source: https://archive.org/details/windows-7-pro-sp1-spanish
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-7-pro-sp1-spanish/Win7_Pro_SP1_Spanish_x86.iso"
                ;;
            "$win7x64_homepremium")
                echo_info "Downloading Windows 7 Home Premium..."
                # Windows 7 Home Premium SP1 x64 (English), archived on archive.org
                # Source: https://archive.org/details/en_windows_7_home_premium_with_sp1_x64_dvd_u_676549_202211
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_7_home_premium_with_sp1_x64_dvd_u_676549_202211/en_windows_7_home_premium_with_sp1_x64_dvd_u_676549.iso"
                ;;
            "$win7x64_homepremium_esp")
                echo_info "Downloading Windows 7 Home Premium Spanish (Español)..."
                # Windows 7 Home Premium SP1 x64 Spanish, archived on archive.org
                # Source: https://archive.org/details/win7-home-prem-sp1-spanish
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win7-home-prem-sp1-spanish/Win7_HomePrem_SP1_Spanish_x64.iso"
                ;;
            "$win7x86_homepremium")
                echo_info "Downloading Windows 7 Home Premium x86..."
                # Windows 7 Home Premium SP1 x86 (English), archived on archive.org
                # Source: https://archive.org/details/en_windows_7_home_premium_with_sp1_x86_dvd_u_676701_202006
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_7_home_premium_with_sp1_x86_dvd_u_676701_202006/en_windows_7_home_premium_with_sp1_x86_dvd_u_676701.iso"
                ;;
            "$win7x86_homepremium_esp")
                echo_info "Downloading Windows 7 Home Premium x86 Spanish (Español)..."
                # Windows 7 Home Premium SP1 x86 Spanish, archived on archive.org
                # Source: https://archive.org/details/win7-home-prem-sp1-spanish
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win7-home-prem-sp1-spanish/Win7_HomePrem_SP1_Spanish_x32.iso"
                ;;
            "$win7x64_enterprise")
                echo_info "Downloading Windows 7 Enterprise..."
                # Windows 7 Enterprise SP1 x64 (English), archived on archive.org
                # Source: https://archive.org/details/en_windows_7_enterprise_with_sp1_dvd
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_7_enterprise_with_sp1_dvd/en_windows_7_enterprise_with_sp1_x64_dvd_u_677651.iso"
                ;;
            "$win7x64_enterprise_esp")
                echo_info "Downloading Windows 7 Enterprise Spanish (Español)..."
                # Windows 7 Enterprise SP1 x64 Spanish, archived on archive.org
                # Source: https://archive.org/details/Win7EnterpriseSP1ESP
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/Win7EnterpriseSP1ESP/es_windows_7_enterprise_with_sp1_x64_dvd_u_677652.iso"
                ;;
            "$win7x86_enterprise")
                echo_info "Downloading Windows 7 Enterprise x86..."
                # Windows 7 Enterprise SP1 x86 (English), archived on archive.org
                # Source: https://archive.org/details/en_windows_7_enterprise_with_sp1_dvd
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/en_windows_7_enterprise_with_sp1_dvd/en_windows_7_enterprise_with_sp1_x86_dvd_u_677710.iso"
                ;;
            "$win7x86_enterprise_esp")
                echo_info "Downloading Windows 7 Enterprise x86 Spanish (Español)..."
                # Windows 7 Enterprise SP1 x86 Spanish, archived on archive.org
                # Source: https://archive.org/details/Win7EnterpriseSP1ESP
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/Win7EnterpriseSP1ESP/es_windows_7_enterprise_with_sp1_x86_dvd_u_677714.iso"
                ;;
            "$win81x64_pro")
                echo_info "Downloading Windows 8.1 Pro..."
                # Windows 8.1 Pro - Consumer JSON API first, archive.org fallback
                # Note: Windows 8.1 automation is retired, falls back to archive.org
                consumer_download_or_archive "$(localized_media "$media")" 8 "$MIDO_LANG" "$(archive_fallback_url 8 "$MIDO_LANG" x64)"
                ;;
            "$win81x86_pro")
                echo_info "Downloading Windows 8.1 Pro x86 32-bit..."
                # Windows 8.1 Pro x86 - Consumer JSON API first, archive.org fallback
                # Note: Windows 8.1 automation is retired, falls back to archive.org
                consumer_download_or_archive "$(localized_media "$media")" 8 "$MIDO_LANG" "$(archive_fallback_url 8 "$MIDO_LANG" x86)" x86
                ;;
            "$win81x64_pro_esp")
                echo_info "Downloading Windows 8.1 Pro Spanish (Spain)..."
                # Windows 8.1 Pro Spanish - Microsoft official first, archive.org fallback
                consumer_download_or_archive "$media" 8 "es-ES" "$(archive_fallback_url 8 es-ES x64)"
                ;;
            "$win81x86_pro_esp")
                echo_info "Downloading Windows 8.1 Pro x86 Spanish (Spain)..."
                # Windows 8.1 Pro x86 Spanish - Microsoft official first, archive.org fallback
                consumer_download_or_archive "$media" 8 "es-ES" "$(archive_fallback_url 8 es-ES x86)" x86
                ;;
            "$win2012r2_eval")
                echo_info "Downloading Windows Server 2012 R2 Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" windows-server-2012-r2 server
                ;;
            "$win2016_eval")
                echo_info "Downloading Windows Server 2016 Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" windows-server-2016 server
                ;;
            "$win2019_eval")
                echo_info "Downloading Windows Server 2019 Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" windows-server-2019 server
                ;;
            "$win2022_eval")
                echo_info "Downloading Windows Server 2022 Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" windows-server-2022 server
                ;;
            "$win2025_eval")
                echo_info "Downloading Windows Server 2025 Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" windows-server-2025 server
                ;;
            "$win2012r2_essentials_eval")
                echo_info "Downloading Windows Server 2012 R2 Essentials Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" windows-server-2012-r2-essentials server
                ;;
            "$win2016_essentials_eval")
                echo_info "Downloading Windows Server 2016 Essentials Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" windows-server-2016-essentials server
                ;;
            "$win2019_essentials_eval")
                echo_info "Downloading Windows Server 2019 Essentials Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" windows-server-2019-essentials server
                ;;
            "$hyperv2012_eval")
                echo_info "Downloading Hyper-V Server 2012 Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" hyper-v-server-2012 server
                ;;
            "$hyperv2012r2_eval")
                echo_info "Downloading Hyper-V Server 2012 R2 Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" hyper-v-server-2012-r2 server
                ;;
            "$hyperv2016_eval")
                echo_info "Downloading Hyper-V Server 2016 Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" hyper-v-server-2016 server
                ;;
            "$hyperv2019_eval")
                echo_info "Downloading Hyper-V Server 2019 Evaluation..."
                enterprise_eval_download "$(localized_media "$media")" hyper-v-server-2019 server
                ;;
            "$win30")
                echo_info "Downloading Windows 3.0..."
                # Windows 3.0 (English), archived on archive.org
                # Source: https://archive.org/details/windows-3.0-original-version
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-3.0-original-version/Windows%203.0%20%28Original%20Version%29.zip"
                ;;
            "$win30_espa")
                echo_info "Downloading Windows 3.0a Spanish (Español)..."
                # Windows 3.0a in Spanish, archived on archive.org
                # Source: https://archive.org/details/microsoft-windows-3.0a-spanish-by-huviretro-gt
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/microsoft-windows-3.0a-spanish-by-huviretro-gt/Microsoft%20Windows%203.0a%20%5BSpanish%5D%20-%20By%20HuviretroGT.zip"
                ;;
            "$win31")
                echo_info "Downloading Windows 3.1..."
                # Windows 3.1 (English), archived on archive.org
                # Source: https://archive.org/details/windows-3.1_202403
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-3.1_202403/WINDOWS_3.1.ISO"
                ;;
            "$win31_espa")
                echo_info "Downloading Windows 3.1 Spanish (Español)..."
                # Windows 3.1 in Spanish, from an MS-DOS 6.22 + Windows 3.1/3.11 Spanish CD collection, archived on archive.org
                # Source: https://archive.org/details/ms-dos-6.22-windows-3.13.113.11-trabajo-en-grupo-spanish
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/ms-dos-6.22-windows-3.13.113.11-trabajo-en-grupo-spanish/Microsoft-Windows_3.1.iso"
                ;;
            "$wfw31")
                echo_info "Downloading Windows for Workgroups 3.1..."
                # Windows for Workgroups 3.1 (English, build 014e), archived on archive.org
                # Source: https://archive.org/details/windows-for-workgroups-3.1-build-014e
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-for-workgroups-3.1-build-014e/Windows%20for%20Workgroups%203.1%20build%20014e.rar"
                ;;
            "$wfw31_espa")
                echo_info "Downloading Windows for Workgroups 3.1 Spanish (Español)..."
                # Windows for Workgroups 3.1 (3.10.102) Spanish 5.25" diskette images, archived on archive.org
                # Source: https://archive.org/details/microsoft-windows-for-workgroups-3.1-3.10.102-1992-11-02-spanish-5.25-1.2mb-upgrade
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/microsoft-windows-for-workgroups-3.1-3.10.102-1992-11-02-spanish-5.25-1.2mb-upgrade/media_img.7z"
                ;;
            "$win311")
                echo_info "Downloading Windows 3.11 / Windows for Workgroups 3.11..."
                # Windows 3.11 For Workgroups (English), archived on archive.org
                # Source: https://archive.org/details/windows-for-workgroups-3.11_202304
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-for-workgroups-3.11_202304/WINDOWS%20FOR%20WORKGROUPS%203.11.iso"
                ;;
            "$win311_espa")
                echo_info "Downloading Windows 3.11 Spanish (Español)..."
                # Windows 3.11 in Spanish, from an MS-DOS 6.22 + Windows 3.1/3.11 Spanish CD collection, archived on archive.org
                # Source: https://archive.org/details/ms-dos-6.22-windows-3.13.113.11-trabajo-en-grupo-spanish
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/ms-dos-6.22-windows-3.13.113.11-trabajo-en-grupo-spanish/Microsoft-%20Windows_3.11_Spanish.iso"
                ;;
            "$wfw311")
                echo_info "Downloading Windows for Workgroups 3.11..."
                # Windows for Workgroups 3.11 (English), archived on archive.org (same media as win311)
                # Source: https://archive.org/details/windows-for-workgroups-3.11_202304
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-for-workgroups-3.11_202304/WINDOWS%20FOR%20WORKGROUPS%203.11.iso"
                ;;
            "$wfw311_espa")
                echo_info "Downloading Windows for Workgroups 3.11 Spanish (Español)..."
                # Windows for Workgroups 3.11 in Spanish, from an MS-DOS 6.22 + Windows 3.1/3.11 Spanish CD collection, archived on archive.org
                # Source: https://archive.org/details/ms-dos-6.22-windows-3.13.113.11-trabajo-en-grupo-spanish
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/ms-dos-6.22-windows-3.13.113.11-trabajo-en-grupo-spanish/Microsoft-Windows_3.11_para_trabajo_en_grupo.iso"
                ;;
            "$win95")
                echo_info "Downloading Windows 95..."
                # Windows 95 (English), archived on archive.org
                # Source: https://archive.org/details/win95
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win95/win95.iso"
                ;;
            "$win95_espa")
                echo_info "Downloading Windows 95 Spanish (Español)..."
                # Windows 95 in Spanish, archived on archive.org
                # Source: https://archive.org/details/Win95Spanish
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/Win95Spanish/Win95.iso"
                ;;
            "$win98")
                echo_info "Downloading Windows 98 Second Edition..."
                # Windows 98 Second Edition (English), archived on archive.org
                # Source: https://archive.org/details/win98-2nd
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win98-2nd/Windows%2098SE.iso"
                ;;
            "$win98_espa")
                echo_info "Downloading Windows 98 Second Edition Spanish (Español)..."
                # Windows 98 Second Edition in Spanish, archived on archive.org
                # Source: https://archive.org/details/Win98SESpanish
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/Win98SESpanish/win98se_2222.es.iso"
                ;;
            "$winme")
                echo_info "Downloading Windows Millennium Edition..."
                # Windows Millennium Edition (English), archived on archive.org
                # Source: https://archive.org/details/windowsme_202301
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windowsme_202301/windowsme.iso"
                ;;
            "$winme_espa")
                echo_info "Downloading Windows Millennium Edition Spanish (Español)..."
                # Windows Millennium Edition (OEM) in Spanish, archived on archive.org
                # Source: https://archive.org/details/WinMEESPOEM
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/WinMEESPOEM/Microsoft%20Windows%20Millenium%20%28OEM%29%20%5BSpanish%5D.iso"
                ;;
            "$winnt35")
                echo_info "Downloading Windows NT 3.5 Workstation..."
                # Windows NT 3.5 Workstation (English), archived on archive.org
                # Source: https://archive.org/details/windows-nt-3.5-workstation
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windows-nt-3.5-workstation/Windows%20NT%203.5%20Workstation.iso"
                ;;
            "$winnt40")
                echo_info "Downloading Windows NT 4.0 Workstation..."
                # Windows NT 4.0 Workstation (English), archived on archive.org
                # Source: https://archive.org/details/ntwks-40-a_202511
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/ntwks-40-a_202511/NTWKS40A.iso"
                ;;
            "$winnt31")
                echo_info "Downloading Windows NT 3.1 Workstation..."
                # Windows NT 3.1 Workstation (English), archived on archive.org
                # Source: https://archive.org/details/windowsnt31cd
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/windowsnt31cd/NT_31A.ISO"
                ;;
            "$winnt351")
                echo_info "Downloading Windows NT 3.51 Workstation..."
                # Windows NT 3.51 Workstation (English, non-bootable CD), archived on archive.org
                # Source: https://archive.org/details/wntwrks351_nb
                # (boot floppies: https://archive.org/details/wnt351bflp)
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/wntwrks351_nb/NTWKS351.iso"
                ;;
            "$backoffice")
                echo_info "Downloading Microsoft BackOffice Small Business Server 4.0 (x86)..."
                # Microsoft BackOffice Small Business Server 4.0 (x86), archived on archive.org
                # Source: https://archive.org/details/backoffice-small-business-server-4.0
                # Full BackOffice Server 4.5 MSDN set: https://archive.org/details/microsoft-backoffice-server-4.5-4.0.1381.1
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/backoffice-small-business-server-4.0/DISC1X86.iso"
                ;;
            "$winframe")
                echo_info "Downloading Citrix WinFrame 1.6 (Windows NT 3.51 Terminal Server)..."
                # Citrix WinFrame 1.6 (Windows NT 3.51 Terminal Server Edition), archived on archive.org
                # Source: https://archive.org/details/win-frame-1.6-english
                scurl_file "$(localized_media "$media")" "1.3" "https://archive.org/download/win-frame-1.6-english/WinFrame%201.6%20English.iso"
                ;;
        esac || {
            error_action=$?
            media_download_failed_list="$media_download_failed_list $media"
            # Return immediately on a fatal error action
            if [ "$error_action" = 2 ]; then
                return
            fi
        }
    done
}

verify_media() {
    # SHA256SUMS file
    # Some of these Windows ISOs are EOL (e.g. win81x64) so their checksums will always match
    # For all other Windows ISOs, a new release will make their checksums no longer match
    #
    # IMPORTANT: These checksums are not necessarily subject to being updated
    # Unfortunately, the maintenance burden would be too large and even if I did there would still be some time gap between Microsoft releasing a new ISO and me updating the checksum (also, users would have to update this script)
    # For these reasons, I've opted for a slightly more manual verification where you have to look up the checksum to see if it's a well-known Windows ISO checksum
    # Ultimately, you have to trust Microsoft because they could still include a backdoor in the verified ISO (keeping Windows air gapped could help with this)
    # Community contributions for these checksums are welcome
    #
    # Leading backslash is to avoid prepending a newline while maintaining alignment
    readonly sha256sums="\
dec04cbd352b453e437b2fe9614b67f28f7c0b550d8351827bc1e9ef3f601389  win7x64-ultimate.iso
d8333cf427eb3318ff6ab755eb1dd9d433f0e2ae43745312c1cd23e83ca1ce51  win81x64.iso
# Windows 10 22H2
a6f470ca6d331eb353b815c043e327a347f594f37ff525f17764738fe812852e  win10x64.iso
# Windows 11 23H2 v2
36de5ecb7a0daa58dce68c03b9465a543ed0f5498aa8ae60ab45fb7c8c4ae402  win11x64.iso
2dedd44c45646c74efc5a028f65336027e14a56f76686a4631cf94ffe37c72f2  win81x64-enterprise-eval.iso
ef7312733a9f5d7d51cfa04ac497671995674ca5e1058d5164d6028f0938d668  win10x64-enterprise-eval.iso
ebbc79106715f44f5020f77bd90721b17c5a877cbc15a3535b99155493a1bb3f  win11x64-enterprise-eval.iso
e4ab2e3535be5748252a8d5d57539a6e59be8d6726345ee10e7afd2cb89fefb5  win10x64-enterprise-ltsc-eval.iso
30832ad76ccfa4ce48ccb936edefe02079d42fb1da32201bf9e3a880c8ed6312  win2008r2.iso
6612b5b1f53e845aacdf96e974bb119a3d9b4dcb5b82e65804ab7e534dc7b4d5  win2012r2-eval.iso
1ce702a578a3cb1ac3d14873980838590f06d5b7101c5daaccbac9d73f1fb50f  win2016-eval.iso
6dae072e7f78f4ccab74a45341de0d6e2d45c39be25f1f5920a2ab4f51d7bcbb  win2019-eval.iso
3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325  win2022-eval.iso"

    # Read sha256sums line-by-line to build known checksum and media lists
    # Only use shell builtins for better security and stability
    # Don't use a for loop because IFS cannot temporarily be set using that
    while IFS="$(printf '\n')" read -r line; do
        # Ignore comments and empty lines
        case "$line" in
            "#"* | "") continue ;;
        esac

        # Read first and second words of line
        IFS=' ' read -r known_checksum known_media _ << EOF
$line
EOF

        known_checksum_list="$known_checksum_list $known_checksum"
        known_media_list="$known_media_list $known_media"
    done << EOF
$sha256sums
EOF

    media_verification_failed_list=""
    checksum_verification_failed_list=""

    for media in $media_list; do
        # The on-disk filename may carry a locale suffix (e.g. win11x64.es-MX.iso)
        media_file="$(localized_media "$media")"

        # Scan for unverified media files
        if ! [ -f "${media_file}${unverified_ext}" ]; then
            continue
        fi

        if [ "$verify_media_message_shown" != "true" ]; then
            echo_info "Verifying integrity..."
            verify_media_message_shown="true"
        fi

        checksum_line="$(sha256sum "${media_file}${unverified_ext}")"
        # Get first word of checksum line
        IFS=' ' read -r checksum _ << EOF
$checksum_line
EOF

        # Sanity check: Assert correct size of SHA-256 checksum
        if [ ${#checksum} != 64 ]; then
            echo_err "Failed SHA-256 sanity check! Exiting..."
            exit 2
        fi

        known_checksum_list_iterator="$known_checksum_list"
        known_checksum=""
        known_checksum_found=""

        # Search known media and checksum lists for the current media
        for known_media in $known_media_list; do
            IFS=' ' read -r known_checksum known_checksum_list_iterator << EOF
$known_checksum_list_iterator
EOF

            if [ "$media_file" = "$known_media" ]; then
                known_checksum_found="true"
                break
            fi
        done

        # Verify current media integrity
        if [ "$known_checksum_found" != "true" ]; then
            # No checksum on record (e.g. a language other than en-US). We cannot verify it automatically
            echo "$media_file: NO KNOWN CHECKSUM (skipping verification)"
            mv "${media_file}${unverified_ext}" "$media_file"
        elif [ "$checksum" = "$known_checksum" ]; then
            echo "$media_file: OK"
            mv "${media_file}${unverified_ext}" "$media_file"
        else
            echo "$media_file: UNVERIFIED"
            media_verification_failed_list="$media_verification_failed_list $media"
            checksum_verification_failed_list="$checksum_verification_failed_list $checksum"
        fi

        # Reset known checksum list iterator so we can iterate on it again for the next media
        known_checksum_list_iterator="$known_checksum_list"
    done
}

ending_summary() {
    echo "" >&2

    if [ "$media_download_failed_list" ]; then
        for media in $media_download_failed_list; do
            media_download_failed_argument_list="$media_download_failed_argument_list ${media%%.iso}"
        done

        # shellcheck disable=SC2086
        echo_err "$(word_count $media_download_failed_list) attempted download(s) failed! Please re-run Mido with these arguments to try downloading again (any partial downloads will be resumed):$media_download_failed_argument_list"
    fi

    if [ "$media_verification_failed_list" ]; then
        manual_verification "$media_verification_failed_list" "$checksum_verification_failed_list"
        # shellcheck disable=SC2086
        echo_err "$(word_count $media_verification_failed_list) of the downloaded Windows media did NOT match the expected checksum! This means either that the media is a newer release than our current checksum (stored in Mido), was corrupted during download, or that is has been (potentially maliciously) modified! Please manually verify the Windows media before use:$media_verification_failed_list"
    elif [ "$manual_verification" = "true" ]; then
        manual_verification
    fi

    # Exit codes
    # 0: Success
    # 1: Argument parsing error
    # 2: Runtime error (see error message for more info)
    # 3: One or more downloads failed
    # 4: One or more verifications failed
    # 5: At least one download and one verification failed (when more than one media is specified)

    exit_code=0

    # Determine exit code
    if [ "$media_download_failed_list" ] && [ "$media_verification_failed_list" ]; then
        exit_code=5
    else
        if [ "$media_download_failed_list" ]; then
            exit_code=3
        elif [ "$media_verification_failed_list" ]; then
            exit_code=4
        fi
    fi

    trap -- - EXIT

    if [ "$exit_code" = 0 ]; then
        echo_ok "Successfully downloaded and verified integrity of all Windows media!"
    else
        echo_ok "Finished! Please see the above errors with information"
        exit "$exit_code"
    fi
}

# https://unix.stackexchange.com/questions/752570/why-does-trap-passthough-zero-instead-of-the-signal-the-process-was-killed-wit
handle_exit() {
    exit_code=$?
    signal="$1"

    if [ "$exit_code" != 0 ] || [ "$signal" ]; then
        echo "" >&2
        echo_err "Mido was exited abruptly! PARTially downloaded or UNVERIFIED Windows media may exist. Please re-run this Mido command and do not use the bad media."
    fi

    if [ "$exit_code" != 0 ]; then
        trap -- - EXIT
        exit "$exit_code"
    elif [ "$signal" ]; then
        trap -- - "$signal"
        kill -s "$signal" -- $$
    fi
}

# Enable exiting on error
#
# Disable shell globbing
# This isn't necessary given that all unquoted variables (e.g. for determining word count) are set directly by us but it's just a precaution
set -ef

# IFS defaults to many different kinds of whitespace but we only care about space
# Note: This means that ISO filenames cannot contain spaces but that's a bad idea anyway
IFS=' '

parse_args "$@"

# If script is installed (in the PATH) then remain at PWD
# Otherwise, change directory to location of script
# readlink -f was recently added to POSIX but is still unavailable on macOS/BSD,
# so fall back to a manual resolution when it is missing: https://austingroupbugs.net/view.php?id=1457
script_path="$0"
case "$script_path" in
    */*) ;;
    *) script_path="$(command -v -- "$script_path" 2> /dev/null || printf '%s' "$script_path")" ;;
esac
local_dir="$(dirname -- "$script_path")"
if command -v readlink > /dev/null 2>&1 && readlink -f -- "$script_path" > /dev/null 2>&1; then
    local_dir="$(dirname -- "$(readlink -f -- "$script_path")")"
fi
case ":$PATH:" in
  *":$local_dir:"*) ;;
  *) cd "$local_dir" || exit ;;
esac

# POSIX sh doesn't include signals in its EXIT trap so do it ourselves
signo=1
while true; do
    # "kill" is a shell builtin
    # shellcheck disable=SC2064
    case "$(kill -l "$signo" 2> /dev/null)" in
        # Trap on all catchable terminating signals as defined by POSIX
        # Stop (i.e. suspend) signals (like Ctrl + Z or TSTP) are fine because they can be resumed
        # Most signals result in termination so this way is easiest (Linux signal(7) only adds more terminating signals)
        #
        # https://pubs.opengroup.org/onlinepubs/009695399/basedefs/signal.h.html
        # https://unix.stackexchange.com/a/490816
        # Signal WINCH was recently added to POSIX: https://austingroupbugs.net/view.php?id=249
        CHLD | CONT | URG | WINCH | KILL | STOP | TSTP | TTIN | TTOU) ;;
        *) trap "handle_exit $signo" "$signo" 2> /dev/null || break ;;
    esac

    signo=$((signo + 1))
done
trap handle_exit EXIT

download_media
verify_media
ending_summary
