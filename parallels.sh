#!/bin/sh

appInstallPath="/Applications"
bundleName="Parallels Desktop"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

i=15
while true; do
  theResult=$(/usr/bin/curl -sLI "https://parallels.com/directdownload/pd${i}/" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/tail -n 1 | /usr/bin/sed 's/\r//')
  if printf '%s' "${theResult}" | /usr/bin/grep -vq '\.dmg*'; then
    majVers=$((i-1))
    break
  else
    i=$((i+1))
  fi
done
xmlData=$(/usr/bin/curl -s "https://update.parallels.com/desktop/v${majVers}/parallels/parallels_updates.xml")
downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '(//Product/Version/Update/FilePath)[1]/text()' -)
currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath "concat(//Major/text(), '.', //Minor/text(), '.', //SubMinor/text())" -)
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
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  "${TMPDIR}"/"${bundleName}.app"/Contents/MacOS/inittool install -t "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
