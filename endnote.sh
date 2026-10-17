#!/bin/sh

majVers=$(/usr/bin/curl -s "https://endnote.com/downloads/available-updates/" | /usr/bin/grep macOS | /usr/bin/xmllint --html --xpath '//h2/text()' - | /usr/bin/awk '{print $2}' | colrm 3)
appInstallPath="/Applications/EndNote ${majVers}"
bundleName="EndNote ${majVers}"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)
currentVers=$(/usr/bin/curl -s "http://download.endnote.com/updates/${majVers}.0/EN${majVers}MacUpdates.xml" | /usr/bin/grep updateTo | /usr/bin/tail -n 1 | /usr/bin/xmllint --xpath '//updateTo/text()' -)
downloadURL="https://download.endnote.com/downloads/${majVers}/EndNote${majVers}Installer.dmg"
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
  /usr/bin/find "${TMPDIR}" -name "EndNote.zip" -exec /usr/bin/ditto -xk {} /tmp/. \; 2>/dev/null
  /bin/mv /tmp/EndNote "${appInstallPath}"
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"
  /bin/chmod -R 755 "${appInstallPath}"
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"

  if [ -d "/Applications/Microsoft Word.app" ]; then
    /bin/mkdir -p "/Library/Application Support/Microsoft/Office365/User Content.localized/Startup.localized/Word" >/dev/null 2>&1
    /usr/bin/ditto "${appInstallPath}/Cite While You Write/EndNote CWYW Word 16.bundle" "/Library/Application Support/Microsoft/Office365/User Content.localized/Startup.localized/Word/EndNote CWYW Word 16.bundle"
    /usr/sbin/chown -R root:admin "/Library/Application Support/Microsoft/Office365"
    /bin/chmod 755 "/Library/Application Support/Microsoft/Office365"

  fi
fi
