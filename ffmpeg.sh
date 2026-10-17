#!/bin/sh

# official ffmpeg binaries require rosetta

appInstallPath="/usr/local/bin"
bundleName="ffmpeg"
appName="${bundleName}"
if ! /usr/sbin/pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
  printf 'Rosetta 2 not installed. Can not continue\n'
  exit 1
fi
installedVers=$("${appInstallPath}"/"${bundleName}" -version | awk '{print $3}' | head -n 1 | awk -F "-" '{print $1}')

jsonData=$(/usr/bin/curl -s "https://evermeet.cx/ffmpeg/info/ffmpeg/release")
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 22 ]; then
  currentVers=$(printf '%s' "${jsonData}" | /usr/bin/jq -r .version)
  downloadURL=$(printf '%s' "${jsonData}" | /usr/bin/jq -r .download.zip.url)
else
  currentVers=$(printf '%s' "${jsonData}" | /usr/bin/plutil -extract version raw -o - -)
  downloadURL=$(printf '%s' "${jsonData}" | /usr/bin/plutil -extract download.zip.url raw -o - -)
fi
FILE=${downloadURL##*/}

# compare version numbers
if [ -n "${installedVers}" ]; then
  printf '%s\n' "${appName} v${installedVers} is installed."

  # Sanitise version strings, retaining only numbers and dots
  v1=$(printf '%s' "${installedVers}" | /usr/bin/sed 's/[^0-9.]//g')
  v2=$(printf '%s' "${currentVers}" | /usr/bin/sed 's/[^0-9.]//g')

  while :; do
    # Extract the next version component
    n1=${v1%%.*}
    n2=${v2%%.*}

    # Remove the component just compared
    case "$v1" in
      *.*) v1=${v1#*.} ;;
      *)   v1= ;;
    esac

    case "$v2" in
      *.*) v2=${v2#*.} ;;
      *)   v2= ;;
    esac

    # Treat missing components as zero
    n1=${n1:-0}
    n2=${n2:-0}

    if [ "$n1" -gt "$n2" ]; then
      # Installed version is newer
      break
    elif [ "$n1" -lt "$n2" ]; then
      # Installed version is older
      break
    fi

    # Versions are equal
    [ -z "$v1" ] && [ -z "$v2" ] && break
  done

  if [ "$n1" -ge "$n2" ]; then
    printf '%s\n' "${appName} does not need to be updated"
    exit 0
  else
    printf '%s\n' "Updating ${appName} to v${currentVers}"
  fi
else
  printf '%s\n' "Installing ${appName} v${currentVers}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  /bin/rm -rf "${appInstallPath:?}"/"${bundleName}" >/dev/null 2>&1
  /usr/bin/ditto -xk /tmp/"${FILE}" "${appInstallPath}"/.
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}"
  /bin/rm /tmp/"${FILE}"
fi
