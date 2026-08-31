#!/bin/sh

appInstallPath="/Applications"
bundleName="logioptionsplus"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

majVers=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F "." '{print$1}')
jSON=$(/usr/bin/curl -s "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-${majVers}.0")
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  # Mac is Sequioa or later
  htmlURL=$(printf '%s' "${jSON}"  | /usr/bin/jq -r 'first(.articles[] | select(.name == "Logi Options+") | .html_url)')
else
  # Mac is Sonoma or older
  count=$(
    printf '%s' "${jSON}" |
    /usr/bin/plutil -extract articles raw -o - -
  )

  i=0
  while [ "$i" -lt "$count" ]; do
      name=$(
          printf '%s' "${jSON}" |
          /usr/bin/plutil -extract "articles.$i.name" raw -o - -
      )
      if [ "${name}" = "Logi Options+" ]; then
          htmlURL=$(
              printf '%s' "${jSON}" |
              /usr/bin/plutil -extract "articles.$i.html_url" raw -o - -
          )
          break
      fi
      i=$((i + 1))
  done
fi

htmlData=$(/usr/bin/curl -s "${htmlURL}")
currentVers=$(printf '%s' "${htmlData}" | /usr/bin/xmllint --html --xpath 'string(//*[@id="vue-article"]/article/section[1]/div[9]/div[1]/div/div/ul/li[1])' - 2>/dev/null | /usr/bin/awk '{print $3}')
downloadURL=$(printf '%s' "${htmlData}" | /usr/bin/xmllint --html --xpath 'string(//*[@id="vue-article"]/article/section[1]/div[9]/div[1]/div/div/ul/div/a/@href)' - 2>/dev/null)
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
  printf '%s\n' "${appName} v${installedVers} is installed."
  installedVersNoDots=$(printf '%s' "${installedVers}" | /usr/bin/sed 's/\.//g')
  currentVersNoDots=$(printf '%s' "${currentVers}" | /usr/bin/sed 's/\.//g')

  # pad out currentVersNoDots to match installedVersNoDots
  installedVersNoDotsCount=${#installedVersNoDots}
  currentVersNoDotsCount=${#currentVersNoDots}

  while [ "${currentVersNoDotsCount}" -lt "${installedVersNoDotsCount}" ]; do
    currentVersNoDots="${currentVersNoDots}0"
    currentVersNoDotsCount=$((currentVersNoDotsCount + 1))
  done

  if [ "${installedVersNoDots}" -ge "${currentVersNoDots}" ]; then
    printf '%s\n' "${appName} does not need to be updated"
    exit 0
  else
    printf '%s\n' "Updating ${appName} to v${currentVers}"
  fi
else
  printf '%s\n' "Installing ${appName} v${currentVers}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  /usr/bin/ditto -xk /tmp/"${FILE}" /tmp/
  /tmp/"${bundleName}"_installer.app/Contents/MacOS/"${bundleName}"_installer --quiet
  /bin/rm -rf /tmp/"${bundleName}"_installer.app
fi
