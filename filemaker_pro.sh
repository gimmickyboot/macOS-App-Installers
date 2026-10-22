#!/bin/sh

appInstallPath="/Applications"
bundleName="FileMaker Pro"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

htmlData=$(/usr/bin/curl -s "https://www.filemaker.com/redirects/ss.txt")
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  majVers=$(printf '%s' "${htmlData}" | /usr/bin/grep "PRO..MAC\"" | /usr/bin/tail -n 1 | /usr/bin/sed 's/,$//' | /usr/bin/jq -r .file | /usr/bin/sed 's/[a-zA-Z]//g')
  downloadURL="$(printf '%s' "${htmlData}" | /usr/bin/grep "PRO${majVers}MAC" | /usr/bin/head -n 1 | /usr/bin/sed 's/,$//' | /usr/bin/jq -r .url)"
else
  majVers=$(printf '%s' "${htmlData}" | /usr/bin/grep "PRO..MAC\"" | /usr/bin/tail -n 1 | /usr/bin/sed 's/,$//' | plutil -extract file raw -o - - | /usr/bin/sed 's/[a-zA-Z]//g')
  downloadURL="$(printf '%s' "${htmlData}" | /usr/bin/grep "PRO${majVers}MAC" | /usr/bin/head -n 1 | /usr/bin/sed 's/,$//' | plutil -extract url raw -o - -)"
fi
FILE=${downloadURL##*/}
currentVers="$(printf '%s' "${downloadURL}" | rev | /usr/bin/cut -d "/" -f 1 - | rev | /usr/bin/sed 's/[a-zA-Z_]//g' | /usr/bin/awk -F. '{print $1"."$2"."$3}')"

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
      *.*)
        v1=${v1#*.}
        ;;
      *)
        v1=
        ;;
    esac

    case "$v2" in
      *.*)
        v2=${v2#*.}
        ;;
      *)
        v2=
        ;;
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

curlParts=5

contentLength=$(/usr/bin/curl -sI "${downloadURL}" | /usr/bin/grep ^Content-Length | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/[^0-9]//g')
partSize=$((contentLength/5))

/usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL -r 0-$partSize -o /tmp/"${FILE}".bin1 "${downloadURL}" &

i=1
while [ $i -le $((curlParts-2)) ]; do
  x=$((i + 1))
  /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL -r $((partSize*i+1))-$((partSize*x)) -o /tmp/"${FILE}".bin$x "${downloadURL}" &
  i=$((i + 1))
done

/usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL -r $((partSize*curlParts-partSize+1))-"${contentLength}" -o /tmp/"${FILE}".bin${curlParts} "${downloadURL}" &

# wait for all background processes to finish
wait

i=1
while [ $i -le $curlParts ]; do
  cat /tmp/"${FILE}".bin${i} >> /tmp/"${FILE}"
  i=$((i + 1))
done

/bin/rm /tmp/"${FILE}".bin*

TMPDIR=$(mktemp -d)
if ! /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"; then
  printf '%s\n' "Failed to mount ${FILE}"
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
  exit 1
fi
if [ ! -d "${TMPDIR}/${bundleName}.app" ]; then
  printf '%s\n' "Could not find ${bundleName}.app in mounted DMG"
  /usr/bin/hdiutil detach "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
  exit 1
fi
/bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
/usr/bin/ditto "${TMPDIR}"/"${bundleName}.app" "${appInstallPath}"/"${bundleName}.app"
/usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
/usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
/bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
/usr/bin/hdiutil eject "${TMPDIR}" -quiet
/bin/rmdir "${TMPDIR}"
/bin/rm /tmp/"${FILE}"
