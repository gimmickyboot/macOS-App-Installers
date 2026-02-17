#!/bin/sh

appInstallPath="/Applications"
bundleName="FileMaker Pro"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

URL="https://www.filemaker.com/redirects/ss.txt"
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  majVers=$(/usr/bin/curl -s "${URL}" | /usr/bin/grep "PRO..MAC\"" | /usr/bin/tail -n 1 | /usr/bin/sed 's/,$//' | /usr/bin/jq -r .file | /usr/bin/sed 's/[a-zA-Z]//g')
  downloadURL="$(/usr/bin/curl -s "${URL}" | /usr/bin/grep "PRO${majVers}MAC" | /usr/bin/head -n 1 | /usr/bin/sed 's/,$//' | /usr/bin/jq -r .url)"
else
  majVers=$(/usr/bin/curl -s "${URL}" | /usr/bin/grep "PRO..MAC\"" | /usr/bin/tail -n 1 | /usr/bin/sed 's/,$//' | plutil -extract file raw -o - - | /usr/bin/sed 's/[a-zA-Z]//g')
  downloadURL="$(/usr/bin/curl -s "${URL}" | /usr/bin/grep "PRO${majVers}MAC" | /usr/bin/head -n 1 | /usr/bin/sed 's/,$//' | plutil -extract url raw -o - -)"
fi
FILE=${downloadURL##*/}
currentVers="$(/bin/echo "${downloadURL}" | rev | /usr/bin/cut -d "/" -f 1 - | rev | /usr/bin/sed 's/[a-zA-Z_]//g' | /usr/bin/awk -F. '{print $1"."$2"."$3}')"

# compare version numbers
if [ "${installedVers}" ]; then
  /bin/echo "${bundleName} v${installedVers} is installed."
  installedVersNoDots=$(/bin/echo "${installedVers}" | /usr/bin/sed 's/\.//g')
  currentVersNoDots=$(/bin/echo "${currentVers}" | /usr/bin/sed 's/\.//g')

  # pad out currentVersNoDots to match installedVersNoDots
  installedVersNoDotsCount=${#installedVersNoDots}
  currentVersNoDotsCount=${#currentVersNoDots}

  while [ "${currentVersNoDotsCount}" -lt "${installedVersNoDotsCount}" ]; do
    currentVersNoDots="${currentVersNoDots}0"
    currentVersNoDotsCount=$((currentVersNoDotsCount + 1))
  done

  if [ "${installedVersNoDots}" -ge "${currentVersNoDots}" ]; then
    /bin/echo "${bundleName} does not need to be updated"
    exit 0
  else
    /bin/echo "Updating ${bundleName} to v${currentVers}"
  fi
else
  /bin/echo "Installing ${bundleName} v${currentVers}"
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

if /usr/bin/hdiutil verify -quiet /tmp/"${FILE}"; then
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/ditto "${TMPDIR}"/"${bundleName}.app" "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
