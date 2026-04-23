#!/bin/sh

###################
# appVers.sh - script to retrieve current versions and download URLs for monitored apps
# Mac Guy https://github.com/gimmickyboot
#
# v1.0 (24/04/2026)
###################

## uncomment the next line to output debugging to stdout
#set -x

###############################################################################
## variable declarations
# shellcheck disable=SC2034
ME=$(basename "$0")
# shellcheck disable=SC2034
BINPATH=$(dirname "$0")
email=""  # add your email here
adminDomain=""  # eg busname-admin.okta.com
ssoURL="${adminDomain}"  # eg sso.busname.domain.com or busname.okta.com

###############################################################################
## function declarations


###############################################################################
## start the script here

# work out what platform, macOS or Linux
case $(uname) in
  Linux)
    platformType="Linux"
    todayDate=$(date "+%F")
    jqBin=$(whereis -b jq| /usr/bin/awk '{print $2}')
    ;;

  Darwin)
    platformType="Darwin"
    todayDate=$(date -j "+%F")
    jqBin=$(whereis -bq jq)
    ;;

  *)
    /bin/echo "Unsupported kernel. Exiting"
    exit 0
    ;;
esac

theFile="/tmp/versions-${todayDate}.txt"

# only run with passed args or all if none
if [ "$#" -gt 0 ]; then
  theList=$(printf '%s ' "$@")
else
  theList="1password adobe_acrobat_reader affinity_designer affinity_photo affinity_publisher alfred altair android_studio api_utility arc artemis atext atom audacity avid_link avid_mediacomposer balenaetcher bbedit blender brave_browser catalyst_browse charles_proxy chatgpt chatgpt_atlas coconut_battery claude codex coderunner cyberduck cycliqplus displaylink_manager dockutil dropbox druva_insync dupeguru elgato_stream_deck endnote evernote fetch figma filemaker_pro firefox firefoxesr freemind fsmonitor gimp github_desktop google_chrome google_earth_pro gpg_suite handbrake handbrakecli imazing_profile_editor insomnia intellij_ultimate isadora itsycal jamf_compliance_editor jamf_connect_configuration jamf_pppc_utility jamf_printer_manager jamf_replicator jamf_sync jamfCheck jamfHelper_constructor joplin jq karabena_elements keepassxc labchart logi_options_plus logi_tune low_profile lulu mafft makemkv managed_app_schema_builder mestrenova microsoft_autoupdater microsoft_companyportal microsoft_edge microsoft_excel microsoft_office_businesspro microsoft_office microsoft_onedrive microsoft_onenote microsoft_outlook microsoft_powerpoint microsoft_quickassist microsoft_remotehelp microsoft_teams2 microsoft_windows_app microsoft_word mist-cli mist mp4joiner mp4splitter mqttexplorer mut mysqlworkbench netbeans nextcloud_desktop nitropdf_pro nudge_suite nvivo obs_studio obsidian okta_verify openvpn_connect opera oracle_java8 orion pacifist parallels pgadmin4 plex_media_player plex_media_server plugdata poll_everywhere postman praat proxyman prune pulsar pycharm pymol pymol_lts python3 qlab r raspberry_pi_imager rstudio sap_privileges sassafras_keyaccess_mac sequelpro sf_symbols shellcheck signal slack snagit story_architect storyboarder subler sublime_merge sublime_text supportapp suspicous_package swiftdialog teamviewer teamviewerqs telegram theunarchiver thunderbird thunderbirdesr touch_designer transmission utm visual_studio_code vlc voodoopad webex whatsapp wireshark xquartz yubico_authenticator zoom zotero"
fi

for theApp in $theList; do
  case $theApp in
    1password)
      downloadURL="https://downloads.1password.com/mac/1Password.pkg"
      currentVers=$(/usr/bin/curl -s "https://releases.1password.com/mac/" | /usr/bin/xmllint --format --html - 2>/dev/null | /usr/bin/grep -B 7 '<h2 class="c-heading c-heading--2 u-mb-2 u-mb-0@md u-mt-4 u-mt-0@md">1Password for Mac</h2>' | /usr/bin/grep "Updated to" | /usr/bin/awk -F ">" '{ print $2 }' | /usr/bin/awk '{print $3}' | /usr/bin/head -n 1)
      ;;

    adobe_acrobat_reader)
      currentVers=$(/usr/bin/curl -s https://armmf.adobe.com/arm-manifests/mac/AcrobatDC/reader/current_version.txt)
      currentVersNoDots=$(printf '%s' "${currentVers}" | /usr/bin/sed 's/\.//g')
      downloadURL="https://ardownload2.adobe.com/pub/adobe/acrobat/mac/AcrobatDC/${currentVersNoDots}/AcroRdrSCADC${currentVersNoDots}_MUI.dmg"
      ;;

    affinity_designer)
      htmlData=$(/usr/bin/curl -s "https://store.serif.com/en-gb/update/macos/designer/2/")
      currentVers=$(printf '%s' "${htmlData}" | /usr/bin/grep -i -o -E "https.*\.dmg" | /usr/bin/sort | /usr/bin/tail -n1 | /usr/bin/tr "-" "\n" | /usr/bin/grep dmg | /usr/bin/sed -E 's/([0-9.]*)\.dmg/\1/g')
      downloadURL=$(printf '%s' "${htmlData}" | /usr/bin/grep -i -o -E "https.*\.dmg.*\"" | /usr/bin/sort | /usr/bin/tail -n1 | /usr/bin/sed -e 's/.$//' -e 's/&amp;/\&/g')
      ;;

    affinity_photo)
      htmlData=$(/usr/bin/curl -s "https://store.serif.com/en-gb/update/macos/photo/2/")
      currentVers=$(printf '%s' "${htmlData}" | /usr/bin/grep -i -o -E "https.*\.dmg" | /usr/bin/sort | /usr/bin/tail -n1 | /usr/bin/tr "-" "\n" | /usr/bin/grep dmg | /usr/bin/sed -E 's/([0-9.]*)\.dmg/\1/g')
      downloadURL=$(printf '%s' "${htmlData}" | /usr/bin/grep -i -o -E "https.*\.dmg.*\"" | /usr/bin/sort | /usr/bin/tail -n1 | /usr/bin/sed -e 's/.$//' -e 's/&amp;/\&/g')
      ;;

    affinity_publisher)
      htmlData=$(/usr/bin/curl -s "https://store.serif.com/en-gb/update/macos/publisher/2/")
      currentVers=$(printf '%s' "${htmlData}" | /usr/bin/grep -i -o -E "https.*\.dmg" | /usr/bin/sort | /usr/bin/tail -n1 | /usr/bin/tr "-" "\n" | /usr/bin/grep dmg | /usr/bin/sed -E 's/([0-9.]*)\.dmg/\1/g')
      downloadURL=$(printf '%s' "${htmlData}" | /usr/bin/grep -i -o -E "https.*\.dmg.*\"" | /usr/bin/sort | /usr/bin/tail -n1 | /usr/bin/sed -e 's/.$//' -e 's/&amp;/\&/g')
      ;;

    alfred)
      xmlData=$(/usr/bin/curl -s "https://www.alfredapp.com/app/update5/general.xml")
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="version"]/following-sibling::*[1])' -)
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="location"]/following-sibling::*[1])' -)
      ;;

    altair)
      gitHubURL="https://github.com/altair-graphql/altair"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case $(uname -m) in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="x64"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/grep "${archType}" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    android_studio)
      if [ "${platformType}" = "Linux" ]; then
        dmgName="mac_arm.dmg"
      else
        case "$(uname -m)" in
          arm64)
            dmgName="mac_arm.dmg"
            ;;

          x86_64)
            dmgName="mac.dmg"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL=$(/usr/bin/curl -s "https://developer.android.com/studio" | /usr/bin/grep android-studio | /usr/bin/grep "${dmgName}" | /usr/bin/grep href | /usr/bin/head -n 1 | /usr/bin/cut -d \" -f 2 -)
      FILE=${downloadURL##*/}
      # shellcheck disable=SC1001
      currentVers=$(printf '%s' "${FILE}" | /usr/bin/cut -d \- -f 3 - | /usr/bin/cut -d . -f 1-2 -)
      ;;

    api_utility)
      gitHubURL="https://github.com/Jamf-Concepts/apiutil"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    arc)
      XML=$(/usr/bin/curl -s "https://releases.arc.net/updates.xml")
      currentVers=$(printf '%s' "${XML}" | /usr/bin/xmllint --xpath '//rss/channel/item[1]/*[name()="sparkle:shortVersionString"]/text()' - | /usr/bin/awk '{print $1}')
      downloadURL=$(printf '%s' "${XML}" | /usr/bin/xmllint --xpath '//rss/channel/item[1]/enclosure/@url' - | /usr/bin/cut -d \" -f 2 -)
      ;;

    artemis)
      gitHubURL="https://github.com/sanger-pathogens/Artemis"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg.gz | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    atext)
      URL="https://www.trankynam.com/atext/"
      htmlData=$(/usr/bin/curl -s "${URL}" | /usr/bin/grep macOS | /usr/bin/xmllint --format --html -)
      currentVers=$(printf '%s' "${htmlData}" | /usr/bin/xmllint --html --xpath '//html/body/p[2]/text()' - | /usr/bin/awk '{print $2}')
      downloadURL="${URL}$(printf '%s' "${htmlData}" | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    atom)
      gitHubURL="https://github.com/atom/atom"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep mac.zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    audacity)
      gitHubURL="https://github.com/audacity/audacity"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep universal.dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    avid_link)
      downloadURL=$(/usr/bin/curl -s "https://www.avid.com/products/avid-link#Downloads" | /usr/bin/grep macOS | xmllint --html --xpath "//script[@id='__NEXT_DATA__']/text()" - 2>/dev/null | /usr/bin/sed -e 's/<!\[CDATA\[//' -e 's/]]>$//' | /usr/bin/grep -oE 'https?://[^"]+\.pkg' | /usr/bin/head -n 1)
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/rev | /usr/bin/cut -d "/" -f 1 - | /usr/bin/cut -c 5- - | /usr/bin/rev | /usr/bin/sed 's/[^0-9.]//g')
      ;;

    avid_mediacomposer)
      currentVers=$(/usr/bin/curl -s "https://kb.avid.com/pkb/articles/en_US/Knowledge/en267087" | /usr/bin/grep -A 2 "Media Composer Version Matrix" | xmllint --html --xpath '//*/tr[2]/td[2]/text()' - 2>/dev/null | /usr/bin/cut -c 3- - | /usr/bin/sed 's/[^0-9.]//g')
      if [ ! "${currentVers}" ] || [ "${currentVers}" = "N/A" ]; then
        currentVers=$(/usr/bin/curl -s "https://kb.avid.com/pkb/articles/en_US/Knowledge/en267087" | /usr/bin/grep -A 2 "Media Composer Version Matrix" | xmllint --html --xpath '//*/tr[2]/td[1]/text()' - 2>/dev/null | /usr/bin/cut -c 3- - | /usr/bin/sed 's/[^0-9.]//g')
        case "${currentVers}" in
          *.0)
            /bin/echo "Version ends in .0. Nothing to do"
            ;;

          *)
            currentVers="${currentVers}.0"
            ;;
        esac
      fi
      downloadURL=""
      ;;

    balenaetcher)
      gitHubURL="https://github.com/balena-io/etcher"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case $(uname -m) in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="x64"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep "${archType}.dmg" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    bbedit)
      downloadURL=$(/usr/bin/curl -s "https://www.barebones.com/products/bbedit/" | /usr/bin/grep dmg | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - 2>/dev/null)
      currentVers=$(basename "${downloadURL}" | /usr/bin/sed -n 's/.*_\([0-9.]*\)\.dmg/\1/p')
      ;;

    blender)
      URL="https://download.blender.org/release"
      currentVersTemp=$(/usr/bin/curl -s "${URL}/" | /usr/bin/grep -Eo 'Blender[0-9]+\.[0-9]+' | /usr/bin/sort -V | /usr/bin/tail -n 1 | /usr/bin/sed 's/[a-zA-Z]//g')
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case $(uname -m) in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="x64"
            ;;

        *)
            /bin/echo "Unknown architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      currentVers=$(/usr/bin/curl -Ls "${URL}/Blender${currentVersTemp}" | /usr/bin/grep "macos-${archType}" | /usr/bin/grep -Eo 'blender-[0-9]+\.[0-9]+(\.[0-9]+)?' | /usr/bin/uniq | /usr/bin/sort -V | /usr/bin/tail -n 1 | /usr/bin/cut -d "-" -f 2- -)
      downloadURL="${URL}/Blender${currentVersTemp}/blender-${currentVers}-macos-${archType}.dmg"
      ;;

    brave_browser)
      if [ "${platformType}" = "Linux" ]; then
        URLpath="stable-arm64"
      else
        case "$(uname -m)" in
          arm64)
            URLpath="stable-arm64"
            ;;

          x86_64)
            URLpath="stable"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      BBXML=$(/usr/bin/curl -s "https://updates.bravesoftware.com/sparkle/Brave-Browser/${URLpath}/appcast.xml")
      currentVers=$(printf '%s' "${BBXML}" | /usr/bin/sed 's/sparkle://g' | /usr/bin/xmllint --xpath '/rss/channel/item[last()]/enclosure/@version' - | /usr/bin/awk -F\" '{print $2}')
      downloadURL=$(printf '%s' "${BBXML}" | /usr/bin/xmllint --xpath '//rss/channel/item[last()]/enclosure/@url' - | /usr/bin/awk -F\" '{print $2}')
      ;;

    catalyst_browse)
      currentVers=$(/usr/bin/curl -s "https://cs.d-imaging.sony.co.jp/coay5hz6MI/2Aext1Frsi?product=CatalystBrowse&lang=en" | "${jqBin}" -r .lastVersion)
      downloadURL="https://di.update.sony.net/NEX/ch4055c566/Catalyst_Browse.dmg"
      ;;

    charles_proxy)
      currentVers=$(/usr/bin/curl -s "https://www.charlesproxy.com/download/latest-release/" | /usr/bin/grep "Download a free trial" | /usr/bin/grep -o "Version.*" | /usr/bin/awk '{print $2}' | /usr/bin/cut -d"<" -f -1 -)
      downloadURL="https://www.charlesproxy.com/assets/release/${currentVers}/charles-proxy-${currentVers}.dmg"
      ;;

    chatgpt_atlas)
      XML=$(/usr/bin/curl -s "https://persistent.oaistatic.com/atlas/public/sparkle_public_appcast.xml")
      currentVers=$(printf '%s' "${XML}" | /usr/bin/xmllint --xpath '//rss/channel/item[1]/title/text()' -)
      downloadURL=$(printf '%s' "${XML}" | /usr/bin/xmllint --xpath 'string(//rss/channel/item[1]/enclosure/@url)' -)
      ;;

    chatgpt)
      xmlData=$(/usr/bin/curl -s https://persistent.oaistatic.com/sidekick/public/sparkle_public_appcast.xml)
      currentVers=$(echo "${xmlData}" | xmllint --xpath '//rss/channel/item/title/text()' - | /usr/bin/head -n 1)
      downloadURL=$(echo "${xmlData}" | xmllint --xpath '//rss/channel/item/enclosure/@url' - | /usr/bin/head -n 1 | /usr/bin/cut -d \" -f 2 - -)
      ;;

    citrix_workspace)
      URL="https://www.citrix.com/downloads/workspace-app/mac/workspace-app-for-mac-latest.html"
      currentVers=$(/usr/bin/curl -s "${URL}" -H sec-ch-ua-platform: "macOS" -H user-agent:" Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" | /usr/bin/xmllint --html --xpath 'string(//p[contains(., "Version")])' 2> /dev/null - | /usr/bin/awk '{print $2}')
      tempDownloadURL=$(/usr/bin/curl -s "${URL}#ctx-dl-eula-external" -H sec-ch-ua-platform: "macOS" -H user-agent:" Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" | xmllint --html --xpath "string(//a[contains(@rel, 'downloads.citrix.com')]/@rel)" 2> /dev/null -)
      downloadURL="http:${tempDownloadURL}"
      ;;

    coconut_battery)
      URL="https://www.coconut-flavour.com/coconutbattery/"
      currentVers=$(/usr/bin/curl -s "${URL}" | /usr/bin/xmllint --html --xpath '//*[@id="home"]/div/div/div/div[1]/div/a[1]/text()' - 2>/dev/null | /usr/bin/awk '{print $2}' | /usr/bin/cut -c 2- - | xargs)
      downloadURL=$(/usr/bin/curl -s "${URL}" | /usr/bin/xmllint --html --xpath '//*[@id="home"]/div/div/div/div[1]/div/a[1]/@href' - 2>/dev/null | /usr/bin/cut -d \" -f 2 -)
      ;;

    claude)
      jSON=$(curl -s "https://downloads.claude.ai/releases/darwin/universal/RELEASES.json")
      currentVers=$(printf '%s' "${jSON}" | "${jqBin}" -r '.currentRelease')
      downloadURL=$(printf '%s' "${jSON}" | "${jqBin}" -r '.releases[].updateTo.url')
      ;;

    codex)
      xmlData=$(/usr/bin/curl -s "https://persistent.oaistatic.com/codex-app-prod/appcast.xml")
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//rss/channel/item/title/text()' - | /usr/bin/head -n 1)
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//rss/channel/item/enclosure/@url' - | /usr/bin/head -n 1 | /usr/bin/cut -d \" -f 2 - -)
      ;;

    coderunner)
      currentVers=$(/usr/bin/curl -s curl 'https://coderunnerapp.com/appcast.xml' | /usr/bin/xmllint --xpath '//rss/channel/item[1]/title/text()' - | /usr/bin/awk '{print $2}')
      downloadURL="https://coderunner.nyc3.cdn.digitaloceanspaces.com/CodeRunner-${currentVers}.zip"
      ;;

    cyberduck)
      xmlData=$(/usr/bin/curl -s 'https://version.cyberduck.io/changelog.rss')
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//rss/channel/item/enclosure' - | /usr/bin/sed -n 's/.*sparkle:shortVersionString="\([^"]*\)".*/\1/p')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//rss/channel/item/enclosure' - | /usr/bin/sed -n 's/.*url="\([^"]*\)".*/\1/p' | /usr/bin/sed 's|o//|o/|')
      ;;

    cycliqplus)
      URL="https://legacy.cycliq.com"
      if [ "${platformType}" = "Linux" ]; then
        archType="silicon"
      else
        case $(uname -m) in
          arm64)
            archType="silicon"
            ;;

          x86_64)
            archType="intel"
            ;;

          *)
            /bin/echo "Unknown processor type. Exiting"
            exit 1
        esac
      fi
      downloadURL="${URL}$(/usr/bin/curl -sI "${URL}"/software/cycliqplus/macos-"${archType}"/ | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//')"
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE "CycliqPlus-[0-9]+(\.[0-9]+)*" | /usr/bin/sed 's/[a-zA-Z-]//g')
      ;;

    displaylink_manager)
      URL="https://www.synaptics.com"
      currentVers=$(/usr/bin/curl -sL "${URL}/products/displaylink-graphics/downloads/macos" | /usr/bin/grep "Release" | /usr/bin/head -n 1 | /usr/bin/sed -n 's/.*Release: \([^ ]*\).*/\1/p')
      releaseDate=$(/usr/bin/curl -sL "${URL}/products/displaylink-graphics/downloads/macos" | /usr/bin/grep "Release Notes" | /usr/bin/grep "${currentVers}" | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - | /usr/bin/awk -F "/" '{print $6}')
      downloadURL="${URL}/sites/default/files/exe_files/${releaseDate}/DisplayLink%20Manager%20Graphics%20Connectivity${currentVers}-EXE.pkg"
      ;;

    dockutil)
      gitHubURL="https://github.com/kcrawford/dockutil"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    dropbox)
      if [ "${platformType}" = "Linux" ]; then
        urlAppend="&arch=arm64"
      else
        case $(uname -m) in
          arm64)
            urlAppend="&arch=arm64"
            ;;

          x86_64)
            urlAppend=""
            ;;

          *)
            /bin/echo "Unknown processor type. Exiting"
            exit 1
        esac
      fi
      downloadURL="https://www.dropbox.com/download?plat=mac&full=1${urlAppend}"
      currentVers=$(curl -sI "${downloadURL}" | /usr/bin/grep -i ^Location | /usr/bin/awk '{print $2}' | /usr/bin/sed -E 's/.*%20([0-9.]*)/\1/g' | rev | /usr/bin/cut -d . -f 3- - | rev)
      ;;

    druva_insync)
      jsonData=$(/usr/bin/curl -s "https://downloads.druva.com/insync/js/data.json")
      currentVers=$(printf '%s' "${jsonData}" | "${jqBin}" -r '.[] | select(.title=="macOS").supportedVersions[]' | /usr/bin/sort -V | /usr/bin/tail -n 1)
      downloadURL=$(printf '%s' "${jsonData}" | "${jqBin}"  -r ".[] | select(.title==\"macOS\").installerDetails[] | select(.version==\"${currentVers}\").downloadURL" | /usr/bin/grep -v "Gov")
      ;;

    dupeguru)
      gitHubURL="https://github.com/arsenetar/dupeguru"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}")
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep macOS | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    elgato_stream_deck)
      jsonData=$(/usr/bin/curl -s "https://gc-updates.elgato.com")
      currentVers=$(printf '%s' "${jsonData}"| "${jqBin}" -r '."sd-mac"."version"')
      downloadURL=$(printf '%s' "${jsonData}" | "${jqBin}" -r '."sd-mac"."downloadURL"')
      ;;

    endnote)
      majVers=$(/usr/bin/curl -s "https://endnote.com/downloads/available-updates/" | /usr/bin/grep macOS | /usr/bin/xmllint --html --xpath '//h2/text()' - | /usr/bin/awk '{print $2}' | colrm 3)
      currentVers=$(/usr/bin/curl -s "http://download.endnote.com/updates/${majVers}.0/EN${majVers}MacUpdates.xml" | /usr/bin/grep updateTo | /usr/bin/tail -n 1 | /usr/bin/xmllint --xpath '//updateTo/text()' -)
      downloadURL="https://download.endnote.com/downloads/${majVers}/EndNote${majVers}Installer.dmg"
      ;;

    evernote)
      URL="https://public.evernote.com/ddl-updater/updater/mac/public/latest-mac.yml"
      currentVers=$(/usr/bin/curl -s "${URL}" --header 'x-os-release: 24.5.0' | /usr/bin/grep ^version | /usr/bin/awk '{print $2}')
      downloadURL=$(/usr/bin/curl -s "${URL}" --header 'x-os-release: 24.5.0' | /usr/bin/grep ^url | /usr/bin/awk '{print $2}')
      ;;

    fetch)
      URL="https://fetchsoftworks.com"
      downloadURL="${URL}$(/usr/bin/curl -s "${URL}/fetch/download/" | /usr/bin/grep "Download Fetch" | /usr/bin/head -n 2 | /usr/bin/tail -n 1 | /usr/bin/xmllint --html --xpath '//a/@href' - | /usr/bin/cut -d \" -f 2 -)"
      currentVers=$(basename "${downloadURL}" | /usr/bin/grep -oE '[0-9]+(\.[0-9]+)*')
      ;;

    figma)
      jSON=$(/usr/bin/curl -s "https://desktop.figma.com/mac-arm/RELEASE.json")
      currentVers=$(printf '%s' "${jSON}" | "${jqBin}" -r .version)
      downloadURL=$(printf '%s' "${jSON}" | "${jqBin}" -r .url)
      ;;

    filemaker_pro)
      htmlData=$(/usr/bin/curl -s "https://www.filemaker.com/redirects/ss.txt")
      majVers=$(printf '%s' "${htmlData}" | /usr/bin/grep "PRO..MAC\"" | /usr/bin/tail -n 1 | /usr/bin/sed 's/,$//' | /usr/bin/jq -r .file | /usr/bin/sed 's/[a-zA-Z]//g')
      downloadURL="$(printf '%s' "${htmlData}" | /usr/bin/grep "PRO${majVers}MAC" | /usr/bin/head -n 1 | /usr/bin/sed 's/,$//' | /usr/bin/jq -r .url)"
      currentVers="$(printf '%s' "${downloadURL}" | rev | /usr/bin/cut -d "/" -f 1 - | rev | /usr/bin/sed 's/[a-zA-Z_]//g' | /usr/bin/awk -F. '{print $1"."$2"."$3}')"
      ;;

    firefox)
      htmlData=$(/usr/bin/curl -fs "https://product-details.mozilla.org/1.0/firefox_versions.json")
      currentVers=$(printf '%s' "${htmlData}" | "${jqBin}" -r .LATEST_FIREFOX_VERSION)
      downloadURL="https://download-installer.cdn.mozilla.net/pub/firefox/releases/${currentVers}/mac/en-US/Firefox%20${currentVers}.dmg"
      ;;

    firefoxesr)
      htmlData=$(/usr/bin/curl -fs "https://product-details.mozilla.org/1.0/firefox_versions.json")
      currentVers=$(/usr/bin/curl -fs "https://product-details.mozilla.org/1.0/firefox_versions.json" | "${jqBin}" -r .FIREFOX_ESR)
      downloadURL="https://download-installer.cdn.mozilla.net/pub/firefox/releases/${currentVers}/mac/en-US/Firefox%20${currentVers}.dmg"
      ;;

    freemind)
      currentVers=$(/usr/bin/curl -s "https://freemind.sourceforge.io/wiki/index.php/Download" | /usr/bin/grep "stable release" | /usr/bin/xmllint --html --xpath '//p/text()' - | /usr/bin/awk '{print $8}' | /usr/bin/sed 's/.$//')
      downloadURL="http://prdownloads.sourceforge.net/freemind/FreeMind_${currentVers}.dmg?download"
      ;;

    fsmonitor)
      downloadURL=$(/usr/bin/curl -s "https://fsmonitor.com" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath '//a/@href' - | /usr/bin/cut -d \" -f 2 -)
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE 'FSMonitor_[0-9]+(\.[0-9]+)*' | /usr/bin/sed 's/FSMonitor_//')
      ;;

    gimp)
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case $(uname -m) in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="x86_64"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      xmlData=$(/usr/bin/curl -sL "https://gimp.org/downloads" | /usr/bin/xmllint --html --xpath "//*[@id=\"mac-${archType}-buttons\"]/span[1]/a" - 2>/dev/null)
      downloadURL="https:$(printf '%s' "${xmlData}" | /usr/bin/xmllint --html --xpath 'string(//*/a/@href)' -)"
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE 'gimp-[0-9]+(\.[0-9]+)*' | /usr/bin/sed 's/gimp-//')
      ;;

    github_desktop)
      downloadURL=$(/usr/bin/curl -sI "https://central.github.com/deployments/desktop/desktop/latest/darwin" | /usr/bin/grep -i "^location" | /usr/bin/awk '{print $2}' | /usr/bin/tr -d '\r')
      currentVers=$(printf '%s' "${downloadURL}" | rev | /usr/bin/cut -d "/" -f 2 - | rev | /usr/bin/awk -F- '{print $1}')
      ;;

    google_chrome)
      currentVers=$(/usr/bin/curl -sL "https://versionhistory.googleapis.com/v1/chrome/platforms/mac/channels/stable/versions/all/releases?filter=fraction%3E0.01,endtime=none&order_by=version%20desc" | "${jqBin}" -r '.releases[0].version')
      downloadURL="https://dl.google.com/chrome/mac/stable/accept_tos%3Dhttps%253A%252F%252Fwww.google.com%252Fintl%252Fen_ph%252Fchrome%252Fterms%252F%26_and_accept_tos%3Dhttps%253A%252F%252Fpolicies.google.com%252Fterms/googlechrome.pkg"
      ;;

    google_earth_pro)
      currentVers=$(/usr/bin/curl -s "https://support.google.com/earth/answer/168344?sjid=18200233394791621691-AP" | /usr/bin/grep googleearthpromac | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath '//a/text()' - | /usr/bin/sed 's/[^0-9.]//g')
      downloadURL="https://dl.google.com/earth/client/advanced/current/GoogleEarthProMac-Intel.dmg"
      ;;

    gpg_suite)
      downloadURL=$(/usr/bin/curl -Ls "https://gpgtools.org" | /usr/bin/grep dmg | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - 2>/dev/null)
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/cut -d "/" -f 4- - | /usr/bin/grep -oE 'GPG_Suite-[0-9]+(\.[0-9]+)*' | /usr/bin/sed 's/GPG_Suite-//')
      ;;

    handbrake)
      gitHubURL="https://github.com/handbrake/handbrake"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    handbrakecli)
      gitHubURL="https://github.com/handbrake/handbrake"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep CLI | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    imazing_profile_editor)
      currentVers=$(/usr/bin/curl -s "https://downloads.imazing.com/com.DigiDNA.iMazingProfileEditorMac.xml" | /usr/bin/xmllint --xpath "(//rss/channel/item)[1]/title/text()" - | /usr/bin/awk '{print $2}')
      downloadURL="https://downloads.imazing.com/mac/iMazing-Profile-Editor/iMazingProfileEditorMac.dmg"
      ;;

    insomnia)
      gitHubURL="https://github.com/Kong/insomnia"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/cut -d "@" -f 2 -)
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    intellij_ultimate)
      if [ "${platformType}" = "Linux" ]; then
        dstType="macM1"
      else
        case $(uname -m) in
          arm64)
            dstType="macM1"
            ;;

          x86_64)
            dstType="mac"
            ;;

          *)
            /bin/echo "Unknown processor type. Exiting"
            exit 1
        esac
      fi
      downloadURL=$(/usr/bin/curl -sIL "https://download.jetbrains.com/product?code=II&latest&distribution=${dstType}" | /usr/bin/grep -i ^location | /usr/bin/tail -1 | /usr/bin/awk '{print $2}'| /usr/bin/sed 's/\r//g')

      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/sed -E 's/.*\/[a-zA-Z-]*-([0-9.]*).*[-.].*dmg/\1/g')
      ;;

    isadora)
      currentVers=$(/usr/bin/curl -s "https://support.troikatronix.com/support/solutions/folders/5000277523" | /usr/bin/grep "Read the Isadora 4 Manual" | tr '[:space:]' '\n' | /usr/bin/grep '^[0-9]' | /usr/bin/sort | /usr/bin/tail -n 1)
      URL="https://troikatronix.com"
      downloadURLTMP=$(/usr/bin/curl -s "${URL}/get-it/" | /usr/bin/grep isadoramac | /usr/bin/xmllint --html --xpath 'string(//a[contains(@href, "std.dmg")]/@href)' - | /usr/bin/cut -c 2- -)
      downloadURL="${URL}${downloadURLTMP}"
      ;;

    itsycal)
      xmlData=$(/usr/bin/curl -s https://s3.amazonaws.com/itsycal/itsycal.xml)
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//rss/channel/item/title/text()' - | /usr/bin/awk '{print $2}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//rss/channel/item/enclosure/@url' - | /usr/bin/cut -d \" -f 2 -)
      ;;

    jamf_compliance_editor)
      gitHubURL="https://github.com/Jamf-Concepts/jamf-compliance-editor"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    jamf_connect_configuration)
      downloadURL="https://files.jamfconnect.com/JamfConnect.dmg"
      currentVers=$(/usr/bin/curl -sI "${downloadURL}" | /usr/bin/grep -i ^x-amz-meta-version | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//')
      ;;

    jamf_pppc_utility)
      gitHubURL="https://github.com/jamf/PPPC-Utility"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}")
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    jamf_printer_manager)
      gitHubURL="https://github.com/jamf/jamf-printer-manager"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    jamf_replicator)
      gitHubURL="https://github.com/jamf/Replicator"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    jamf_sync)
      gitHubURL="https://github.com/jamf/JamfSync"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}")
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    jamfCheck)
      gitHubURL="https://github.com/txhaflaire/JamfCheck"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    jamfHelper_constructor) 
      gitHubURL="https://github.com/BIG-RAT/jhc"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    joplin)
      gitHubURL="https://github.com/laurent22/joplin"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/cut -c 2- -)
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case "$(uname -m)" in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="mac"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep "${archType}".zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    jq)
      gitHubURL="https://github.com/jqlang/jq"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      # shellcheck disable=SC1001
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/cut -d \- -f 2- -)
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case "$(uname -m)" in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="amd64"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep "macos-${archType}" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    karabena_elements)
      gitHubURL="https://github.com/pqrs-org/Karabiner-Elements"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    keepassxc)
      gitHubURL="https://github.com/keepassxreboot/keepassxc"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}")
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case $(uname -m) in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="x86_64"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi

      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep "${archType}.dmg" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    labchart)
      downloadURL=$(/usr/bin/curl -s "https://www.adinstruments.com/support/downloads/mac/labchart" -A 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15' | /usr/bin/grep "pkg" | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/rev | /usr/bin/cut -d "/" -f 1 - | /usr/bin/cut -c 5- - | /usr/bin/rev | /usr/bin/sed 's/[^0-9.]//g')
      ;;

    logi_options_plus)
      currentVers=$(/usr/bin/curl -s "https://support.logi.com/hc/en-au/articles/1500005516462-Logi-Options-Release-Notes" | /usr/bin/grep "Version Release Date" | /usr/bin/grep -o 'content="[^"]*' | /usr/bin/head -n 1 | /usr/bin/awk '{print $4}')
      downloadURL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip"
      ;;

    logi_tune)
      downloadURL="https://software.vc.logitech.com/downloads/tune/LogiTuneInstaller.dmg"
      pageURL=$(/usr/bin/curl -s "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-11.0" | "${jqBin}" -r '.articles | map(select(.name == "Logi Tune")) | .[0] | .html_url')
      currentVers=$(/usr/bin/curl -s "${pageURL}" | /usr/bin/grep "Software Version" | /usr/bin/head -n 1 | /usr/bin/sed 's/[^0-9.]//g')
      ;;

    low_profile)
      gitHubURL="https://github.com/ninxsoft/LowProfile"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    lulu)
      gitHubURL="https://github.com/objective-see/LuLu"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    mafft)
      URL="https://mafft.cbrc.jp/alignment/software"
      FILE=$(/usr/bin/curl -s "${URL}/macstandard.html" | /usr/bin/grep signed | /usr/bin/xmllint --html --xpath '//a/text()' - | /usr/bin/sort | /usr/bin/tail -n 1 | /usr/bin/sed 's/\?.*//')
      currentVers="$(printf '%s' "${FILE}" | /usr/bin/cut -d "-" -f 2 -)"
      downloadURL="${URL}/${FILE}"
      ;;

    makemkv)
      URL="https://www.makemkv.com"
      xmlData=$(/usr/bin/curl -s "${URL}/download/")
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/grep "Mac OS X" | /usr/bin/head -n 2 | /usr/bin/xmllint --html --xpath '//*/a/text()' - | /usr/bin/awk '{print $2}')
      downloadURL="${URL}$(printf '%s' "${xmlData}" | /usr/bin/grep "Mac OS X" | /usr/bin/head -n 2 | /usr/bin/xmllint --html --xpath '//*/a/@href' - | /usr/bin/cut -d \" -f 2 -)"
      ;;

    managed_app_schema_builder)
      gitHubURL="https://github.com/BIG-RAT/Managed-App-Schema-Builder"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    mestrenova)
      URL="https://mestrelab.com"
      downloadURL="${URL}$(/usr/bin/curl -s "${URL}/download" | /usr/bin/grep "latest version" | /usr/bin/grep dmg | /usr/bin/xmllint --html --xpath '//li/a[contains(@href, "dmg")]/@href' - 2>/dev/null | /usr/bin/cut -d \" -f 2 -)"
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/cut -d "-" -f 2 -)
      ;;

    microsoft_autoupdater)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSau04.xml')
      currentVers=$(printf '%s' "${xmlData}"  | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $3}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Location"]/following-sibling::string[1])' -)
      ;;

    microsoft_companyportal)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409IMCP01.xml')
      currentVers=$(printf '%s' "${xmlData}"  | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $4}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Location"]/following-sibling::string[1])' -)
      ;;

    microsoft_edge)
      jSON=$(/usr/bin/curl -s "https://edgeupdates.microsoft.com/api/products/stable")
      currentVers=$(printf '%s' "${jSON}" | "${jqBin}" -r '.[]|.Releases[] | select(.Platform == "MacOS").ProductVersion')
      downloadURL=$(printf '%s' "${jSON}" | "${jqBin}" -r '.[]|.Releases[] | select(.Platform == "MacOS").Artifacts[0].Location')
      ;;

    microsoft_excel)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409XCEL2019.xml')
      currentVers=$(printf '%s' "${xmlData}"  | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $4}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="FullUpdaterLocation"]/following-sibling::string[1])' -)
      ;;

    microsoft_office_businesspro)
      currentVers=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSWD2019.xml' | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $4}')
      downloadURL=$(/usr/bin/curl -sI "https://go.microsoft.com/fwlink/?linkid=2009112" | /usr/bin/grep -i "^Location"| /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      ;;

    microsoft_office)
      currentVers=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSWD2019.xml' | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $4}')
      downloadURL=$(/usr/bin/curl -sI "https://go.microsoft.com/fwlink/?linkid=525133" | /usr/bin/grep -i "^Location"| /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      ;;

    microsoft_onedrive)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409ONDR18.xml')
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $3}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Location"]/following-sibling::string[1])' -)
    ;;

    microsoft_onenote)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409ONMC2019.xml')
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $4}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="FullUpdaterLocation"]/following-sibling::string[1])' -)
      ;;

    microsoft_outlook)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409OPIM2019.xml')
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $4}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="FullUpdaterLocation"]/following-sibling::string[1])' -)
      ;;

    microsoft_powerpoint)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409PPT32019.xml')
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $4}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="FullUpdaterLocation"]/following-sibling::string[1])' -)
      ;;

    microsoft_quickassist)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSQA01.xml')
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Update Version"]/following-sibling::string[1])' -)
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Location"]/following-sibling::string[1])' -)
      ;;

    microsoft_remotehelp)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSRH01.xml')
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Update Version"]/following-sibling::string[1])' -)
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Location"]/following-sibling::string[1])' -)
      ;;

    microsoft_teams2)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409TEAMS21.xml')
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $3}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Location"]/following-sibling::string[1])' -)
      ;;

    microsoft_windows_app)
      downloadURL=$(/usr/bin/curl -s "https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSRD10.xml" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/sed -e 's/<[^>]*>//g' | xargs)
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE '[0-9]+(\.[0-9]+)+')
      ;;

    microsoft_word)
      xmlData=$(/usr/bin/curl -s 'https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSWD2019.xml')
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="Title"]/following-sibling::string[1])' - | /usr/bin/awk '{print $4}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="FullUpdaterLocation"]/following-sibling::string[1])' -)
      ;;

    mist-cli)
      gitHubURL="https://github.com/ninxsoft/mist-cli"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    mist)
      gitHubURL="https://github.com/ninxsoft/Mist"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    mp4joiner)
      currentVers=$(/usr/bin/curl -s "https://www.mp4joiner.org/en/" | /usr/bin/tr '>' '\n' | /usr/bin/grep dmg | /usr/bin/grep -oE 'MP4Tools-[0-9]+(\.[0-9]+)*' | /usr/bin/sed 's/MP4Tools-//')
      downloadURL="https://ixpeering.dl.sourceforge.net/project/mp4joiner/MP4Tools/${currentVers}/MP4Tools-${currentVers}-MacOSX.dmg"
      ;;

    mp4splitter)
      currentVers=$(/usr/bin/curl -s "https://www.mp4joiner.org/en/" | /usr/bin/tr '>' '\n' | /usr/bin/grep dmg | /usr/bin/grep -oE 'MP4Tools-[0-9]+(\.[0-9]+)*' | /usr/bin/sed 's/MP4Tools-//')
      downloadURL="https://ixpeering.dl.sourceforge.net/project/mp4joiner/MP4Tools/${currentVers}/MP4Tools-${currentVers}-MacOSX.dmg"
      ;;

    mqttexplorer)
      gitHubURL="https://github.com/thomasnordquist/MQTT-Explorer"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/cut -c 2- -)
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep mac.zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    mut)
      gitHubURL="https://github.com/jamf/mut"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    mysqlworkbench)
      currentVers=$(/usr/bin/curl -fsL "https://dev.mysql.com/downloads/workbench/?os=33" | /usr/bin/grep -A1 "DMG Archive" | /usr/bin/tail -n 1 | /usr/bin/awk -F'[<>]' '{print $3}')
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case $(uname -m) in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="x86_64"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL="https://cdn.mysql.com//Downloads/MySQLGUITools/$(/usr/bin/curl -fsL "https://dev.mysql.com/downloads/workbench/?os=33" | /usr/bin/grep -o "mysql-workbench-community-.*-macos-${archType}.dmg" | /usr/bin/head -n1)"
      ;;

    netbeans)
      gitHubURL="https://github.com/Friends-of-Apache-NetBeans/netbeans-installers"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/[^0-9]//g')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep "pkg" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    nextcloud_desktop)
      gitHubURL="https://github.com/nextcloud-releases/desktop"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/cut -c 2- -)
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    nitropdf_pro)
      xmlDATA=$(/usr/bin/curl -s "https://downloads.gonitro.com/macos/pro.rss")
      appTitle=$(printf '%s' "${xmlDATA}" | /usr/bin/xmllint --xpath '//rss/channel/item/title/text()' - | /usr/bin/head -n 1)
      currentVers=$(printf '%s' "${xmlDATA}" | /usr/bin/xmllint --xpath "//rss/channel/item[title=\"${appTitle}\"]/*[name()=\"sparkle:shortVersionString\"]/text()" -)
      downloadURL=$(printf '%s' "${xmlDATA}" | /usr/bin/xmllint --xpath "string(/rss/channel/item[title=\"${appTitle}\"]/enclosure/@url)" -)
      ;;

    nudge_suite)
      gitHubURL="https://github.com/macadmins/nudge"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/cut -c 2- -)
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep Nudge_Suite | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    nvivo)
      majVers=$(/usr/bin/curl -s "https://techcenter.qsrinternational.com/Content/welcome/toc_welcome.htm" | /usr/bin/grep Mac | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//span/@class)' - | /usr/bin/sed 's/[^0-9]//g')
      downloadURL="https://download.qsrinternational.com/Software/NVivo${majVers}forMac/NVivo.dmg"
      currentVers="$(/usr/bin/curl -sIL "${downloadURL}" | /usr/bin/grep ^location | /usr/bin/awk '{print $2}' | rev | /usr/bin/cut -d "/" -f 2 - | rev | /usr/bin/cut -d . -f 1-3 -)"
      ;;

    obs_studio)
      gitHubURL="https://github.com/obsproject/obs-studio"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      if [ "${platformType}" = "Linux" ]; then
        archType="Apple"
      else
        case "$(uname -m)" in
          arm64)
            archType="Apple"
            ;;

          x86_64)
            archType="Intel"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep "${archType}.dmg" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;; 

    obsidian)
      gitHubURL="https://github.com/obsidianmd/obsidian-releases"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/rev | /usr/bin/awk -F v '{print $1}' | /usr/bin/rev)
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    okta_verify)
      if [ "${adminDomain}" ] &&  [ "${ssoURL}" ]; then
        jSON=$(/usr/bin/curl -s "https://${adminDomain}/api/v1/artifacts/OKTA_VERIFY_MACOS/latest?releaseChannel=GA")
        currentVers=$(printf '%s' "${jSON}" | /usr/bin/jq -r .version)
        downloadURL="https://${ssoURL}$(printf '%s' "${jSON}" | "${jqBin}" -r '.files[].href')"
      fi
      ;;

    openvpn_connect)
      downloadURL=$(/usr/bin/curl -sI "https://openvpn.net/downloads/openvpn-connect-v3-macos.dmg" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//')
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE "openvpn-connect-[0-9]+(\.[0-9]+)*" | /usr/bin/cut -d - -f 3- - | rev | /usr/bin/cut -d . -f 2- - | rev)
      ;;

    opera)
      linkOne=$(/usr/bin/curl -sI "https://download.opera.com/download/get/?partner=www&opsys=MacOS" | /usr/bin/grep -i "^location" | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//')
      linkTwo=$(/usr/bin/curl -sL "${linkOne}" | /usr/bin/grep "thanks-download-link" | /usr/bin/xmllint --html --xpath 'string(//html/body/p/a/@href)' - 2>/dev/null | /usr/bin/sed 's/\&amp;/\&/g')
      downloadURL=$(/usr/bin/curl -sI "${linkTwo}" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//')
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE 'desktop/[0-9]+(\.[0-9]+)*' | /usr/bin/sed 's/desktop\///g')
      ;;

    oracle_java8)
    if [ "${platformType}" = "Linux" ]; then
        URL="https://javadl-esd-secure.oracle.com/update/mac/map-mac-aarch64-1.8.0.xml"
      else
        case $(uname -m) in
          arm64)
            URL="https://javadl-esd-secure.oracle.com/update/mac/map-mac-aarch64-1.8.0.xml"
            ;;

          x86_64)
            URL="https://javadl-esd-secure.oracle.com/update/mac/map-mac-1.8.0.xml"
            ;;

          *)
            /bin/echo "Unknow architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      TMPURL=$(/usr/bin/curl -s "${URL}" | /usr/bin/xmllint --xpath 'string(//url[1]/text())' -)
      downloadURL=$(/usr/bin/curl -s "${TMPURL}" | /usr/bin/xmllint --xpath 'string(//rss/channel/item/enclosure/@url)' -)
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/cut -d "/" -f 7 - | /usr/bin/awk -F "-" '{print $1}' | /usr/bin/sed 's/_/./')
      ;;

    orion)
      majVers="26"
      xmlData=$(/usr/bin/curl -Ls "https://browser.kagi.com/updates/${majVers}_0/appcast.xml")
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//item/title/text()' - | /usr/bin/tail -n 1)
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath "string(//item[title=\"${currentVers}\"]/enclosure/@url)" -)
      ;;


    pacifist)
      currentVers=$(/usr/bin/curl -s "https://www.charlessoft.com/cgi-bin/pacifist_relnotes.cgi" | /usr/bin/xmllint --html --xpath '//*/h1/text()' - | /usr/bin/head -n 1 | /usr/bin/awk '{print $2}')
      downloadURL="https://www.charlessoft.com/pacifist_download/Pacifist_${currentVers}.zip"
      ;;

    parallels)
      i=15
      while true; do
        theResult=$(curl -sLI "https://parallels.com/directdownload/pd${i}/" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/tail -n 1 | /usr/bin/sed 's/\r//')
          if printf '%s' "${theResult}" | grep -vq '\.dmg*'; then
            majVers=$((i-1))
            break
          else
            i=$((i+1))
          fi
      done
      xmlData=$(/usr/bin/curl -s "https://update.parallels.com/desktop/v${majVers}/parallels/parallels_updates.xml")
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '(//Product/Version/Update/FilePath)[1]/text()' -)
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath "concat(//Major/text(), '.', //Minor/text(), '.', //SubMinor/text())" -)
      ;;

    pgadmin4)
      currentVers=$(/usr/bin/curl -s "https://pgadmin-archive.postgresql.org/pgadmin4/index.html" | /usr/bin/grep 'href="v'  | /usr/bin/tail -n 1 | /usr/bin/xmllint --xpath '//li/a/text()' - | /usr/bin/cut -c 2- -)
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case $(uname -m) in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="x64"
            ;;

        *)
            /bin/echo "Unknow architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL="https://pgadmin-archive.postgresql.org/pgadmin4/v${currentVers}/macos/pgadmin4-${currentVers}-${archType}.dmg"
      ;;

    plex_media_player)
      jsonData=$(/usr/bin/curl -s "https://plex.tv/api/downloads/3.json")
      currentVers=$(printf '%s' "${jsonData}" | "${jqBin}" -r .computer.Mac.version)
      downloadURL=$(printf '%s' "${jsonData}" | "${jqBin}" -r '.computer.Mac.releases[].url')
      ;;

    plex_media_server)
      jsonData=$(/usr/bin/curl -s "https://plex.tv/api/downloads/5.json")
      currentVers=$(printf '%s' "${jsonData}" | /usr/bin/jq -r .computer.MacOS.version | /usr/bin/cut -d "-" -f 1 -)
      downloadURL=$(printf '%s' "${jsonData}" | /usr/bin/jq -r '.computer.MacOS.releases[].url')
      ;;

    plugdata)
      gitHubURL="https://github.com/plugdata-team/plugdata"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep "Universal.pkg" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    poll_everywhere)
      xmlData=$(/usr/bin/curl -s "https://polleverywhere-app.s3.amazonaws.com/mac-stable/appcast.xml")
      currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//channel/item/title/text()' - | /usr/bin/awk '{print $2}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//channel/item/enclosure/@url' - | /usr/bin/cut -d \" -f 2 -)
      ;;

    postman)
      postmanJson=$(/usr/bin/curl -s "https://www.postman.com/mkapi/release.json")
      currentMajVers=$(printf '%s' "${postmanJson}" | "${jqBin}" -r .latestVersion)
      currentVers=$(printf '%s' "${postmanJson}" | "${jqBin}" -r ".${currentMajVers}[0].version")
      if [ "${platformType}" = "Linux" ]; then
        urlAppend="osx_arm64"
      else
        case "$(uname -m)" in
          arm64)
            urlAppend="osx_arm64"
            ;;

          x86_64)
            urlAppend="osx_64"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL="https://dl.pstmn.io/download/latest/${urlAppend}"
      ;;

    praat)
      gitHubURL="https://github.com/praat/praat.github.io"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    proxyman)
      gitHubURL="https://github.com/ProxymanApp/Proxyman"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}")
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    prune)
      gitHubURL="https://github.com/BIG-RAT/Prune"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/v//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    pulsar)
      gitHubURL="https://github.com/pulsar-edit/pulsar"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      if [ "${platformType}" = "Linux" ]; then
        archType="Silicon"
      else
        case $(uname -m) in
          arm64)
            archType="Silicon"
            ;;

          x86_64)
            archType="Intel"
            ;;

          *)
            /bin/echo "Unknown processor type. Exiting"
            exit 1
        esac
      fi
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep -E "${archType}.*\.dmg" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    pycharm)
      jSON=$(/usr/bin/curl -s 'https://data.services.jetbrains.com/products?code=PCP&release.type=release&_=1767045118843')
      currentVers=$(printf '%s' "${jSON}" | "${jqBin}" -r "first(.[].releases[].version)")
      if [ "${platformType}" = "Linux" ]; then
        archType="macM1"
      else
        case $(uname -m) in
          arm64)
            archType="macM1"
            ;;

          x86_64)
            archType="mac"
            ;;

          *)
            /bin/echo "Unknown processor type. Exiting"
            exit 1
        esac
      fi
      downloadURL=$(printf '%s' "${jSON}" | "${jqBin}" -r "first(.[].releases[].downloads.${archType}).link")
      ;;

    pymol)
      downloadURL=$(/usr/bin/curl -s "https://www.pymol.org/" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//*/a/@href)' - 2>/dev/null)
      FILE=${downloadURL##*/}
      currentVers=$(printf '%s' "${FILE}" | /usr/bin/grep -Eo '[0-9]+(\.[0-9]+)+')
      ;;

    pymol_lts)
      downloadURL=$(curl -s "https://www.pymol.org/" | grep dmg | tail -n 2 | xmllint --html --xpath 'string(//*/a/@href)' - 2>/dev/null)
      FILE=${downloadURL##*/}
      currentVers=$(printf '%s' "${FILE}" | /usr/bin/grep -Eo '[0-9]+(\.[0-9]+)+')
      ;;

    python3)
      URL="https://www.python.org/downloads/"
      downloadURL=$(/usr/bin/curl -s --compressed "${URL}" | /usr/bin/awk '/macos/ && /ftp/ {print;}' | /usr/bin/cut -d \" -f 4 -)
      FILE=${downloadURL##*/}
      currentVers=$(printf '%s' "${FILE}" | /usr/bin/awk -F- '{print $2}')
      ;;

    qlab)
      currentVers=$(/usr/bin/curl -s "https://qlab.app/page-data/download/page-data.json" | "${jqBin}" -r '.result.data.allQlabVersionsYaml.edges[0].node.version')
      downloadURL="https://qlab.app/downloads/QLab.dmg"
      ;;

    r)
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case $(uname -m) in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="x86_64"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      FILE=$(/usr/bin/curl -s "https://cran.rstudio.com/bin/macosx/" | /usr/bin/sed 's/<[^>]*>//g' | /usr/bin/grep "${archType}.pkg" | /usr/bin/tail -n 1 | /usr/bin/sed 's/ //g')
      currentVers=$(printf '%s' "${FILE}" | /usr/bin/awk -F - '{print $2}')
      downloadURL="https://cran.rstudio.com/bin/macosx/big-sur-arm64/base/${FILE}"
      ;;

    raspberry_pi_imager)
      downloadURL=$(/usr/bin/curl -sI "https://downloads.raspberrypi.org/imager/imager_latest.dmg" | /usr/bin/grep -i ^Location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${downloadURL}" | /usr/bin/sed -e 's/imager_//' -e 's/.dmg//')
      ;;

    rstudio)
      FILE=$(/usr/bin/curl -s "https://posit.co/download/rstudio-desktop/" | /usr/bin/sed 's/<[^>]*>//g' | /usr/bin/grep dmg | /usr/bin/sed 's/ //g')
      currentVers=$(printf '%s' "${FILE}" | /usr/bin/sed -e 's/RStudio-//' -e 's/.dmg//')
      downloadURL="https://download1.rstudio.org/electron/macos/${FILE}"
      ;;

    sap_privileges)
      gitHubURL="https://github.com/SAP/macOS-enterprise-privileges"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}")
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    sassafras_keyaccess_mac)
      htmlData=$(/usr/bin/curl -s "https://solutions.teamdynamix.com/TDClient/1965/Portal/KB/ArticleDet?ID=169236")
      currentVers=$(printf '%s' "${htmlData}" | /usr/bin/tr '>' '\n' | /usr/bin/grep -A1 "Minor Version" | /usr/bin/tail -n 1 | /usr/bin/sed 's/<\/p//' | /usr/bin/xargs)
      downloadURL=$(printf '%s' "${htmlData}" | /usr/bin/tr '>' '\n' | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - 2>/dev/null)
      ;;

    sequelpro)
      gitHubURL="https://github.com/sequelpro/sequelpro"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g') 
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/sed 's/release-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    sf_symbols)
      downloadURL=$(/usr/bin/curl -fs "https://developer.apple.com/sf-symbols/" | /usr/bin/grep dmg | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - | /usr/bin/sed 's/?2//')
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE 'SF-Symbols-[0-9]' | /usr/bin/sed 's/SF-Symbols-//')
      ;;

    shellcheck)
      gitHubURL="https://github.com/koalaman/shellcheck"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      if [ "${platformType}" = "Linux" ]; then
        archType="aarch64"
      else
        case $(uname -m) in
          arm64)
            archType="aarch64"
            ;;

          x86_64)
            archType="x86_64"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep "darwin.${archType}.tar.xz" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    signal)
      YAML=$(/usr/bin/curl -s 'https://updates.signal.org/desktop/latest-mac.yml')
      currentVers=$(printf '%s' "${YAML}" | /usr/bin/head -n 1 | /usr/bin/awk '{print $2}')
      downloadURL="https://updates.signal.org/desktop/$(printf '%s' "${YAML}" | /usr/bin/grep -A2 signal-desktop-mac-universal | /usr/bin/head -n 1 | /usr/bin/awk '{print $3}')"
      ;;

    slack)
      downloadURL=$(/usr/bin/curl -sI "https://slack.com/ssb/download-osx-universal" | /usr/bin/grep -i ^Location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE '[0-9]+(\.[0-9]+)+' | /usr/bin/head -n 1)
      ;;

    snagit)
      currentVers=$(/usr/bin/curl -s "https://support.techsmith.com/hc/en-us/articles/37938520706957-Snagit-Mac-2025-Version-History" | /usr/bin/xmllint --html --xpath '//*/head/meta[2]/@content' - 2>/dev/null | /usr/bin/cut -d \" -f 2- - | /usr/bin/grep -oE 'in[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+' | /usr/bin/awk '{print $2}')
      # versionYear=$(printf '%s' "${currentVers}" | /usr/bin/cut -c 1-4 -)
      # downloadURL=$(/usr/bin/curl -s "https://sparkle.cloud.techsmith.com/api/v1/AppcastManifest/?version=${currentVers}&utm_source=product&utm_medium=snagit&utm_campaign=sm${versionYear}&ipc_item_name=snagit&ipc_platform=macos" | /usr/bin/xmllint --xpath '//rss/channel/item/enclosure/@url' - | /usr/bin/cut -d \" -f 2 -)
      downloadURL="https://download.techsmith.com/snagitmac/releases/$(printf '%s' "${currentVers}" | /usr/bin/cut -c 3- - | /usr/bin/sed 's/\.//g')/snagit.dmg"
      ;;

    story_architect)
      gitHubURL="https://github.com/story-apps/starc"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    storyboarder)
      gitHubURL="https://github.com/wonderunit/storyboarder"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/cut -c 2- -)
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    subler)
      gitHubURL="https://github.com/SublerApp/Subler"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}")
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep zip | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    sublime_merge)
      currentVers=$(/usr/bin/curl -s "https://www.sublimemerge.com/download" | /usr/bin/grep Build | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath '//p[@class="latest"]/text()' - | /usr/bin/awk '{print $2}')
      downloadURL="https://download.sublimetext.com/sublime_merge_build_${currentVers}_mac.zip"
      ;;

    sublime_text)
      currentVers=$(/usr/bin/curl -s "https://www.sublimetext.com/" | /usr/bin/grep Build | /usr/bin/xmllint --xpath '//*/i/text()' - | /usr/bin/sed 's/[^0-9]//g')
      downloadURL="https://download.sublimetext.com/sublime_text_build_${currentVers}_mac.zip"
      ;;

    supportapp)
      gitHubURL="https://github.com/root3nl/SupportApp"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    suspicous_package)
      URL="https://www.mothersruin.com/software"
      currentVers=$(/usr/bin/curl -s "${URL}/SuspiciousPackage/update.html" | /usr/bin/grep Version | /usr/bin/tail -n 1 | /usr/bin/xmllint --html --xpath '//h4/text()' - | /usr/bin/sed 's/[^0-9.]//g')
      downloadURL="${URL}/downloads/SuspiciousPackage.dmg"
      ;;

    swiftdialog)
      gitHubURL="https://github.com/swiftDialog/swiftDialog"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    teamviewer)
     downloadURL=$(/usr/bin/curl -s "https://download.teamviewer.com/download/update/macupdates.xml?version=15.1.1&os=macos&osversion=15.5" | /usr/bin/xmllint --xpath '//rss/channel/item/enclosure/@url' - | /usr/bin/grep -v Host | /usr/bin/cut -d \" -f 2 - | /usr/bin/head -n 1)
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -v Host | /usr/bin/cut -d \" -f 2 - | /usr/bin/rev | /usr/bin/cut -d "/" -f 2 - | /usr/bin/rev)
      ;;

    teamviewerqs)
      currentVers=$(/usr/bin/curl -s "https://community.teamviewer.com/English/categories/change-logs-en" | /usr/bin/grep macOS | /usr/bin/xmllint --html --xpath "(//a)[1]/text()" - | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/[a-zA-Z]//g')
      downloadURL="https://download.teamviewer.com/download/TeamViewerQS.dmg"
      ;;

    telegram)
      currentVers=$(/usr/bin/curl -s "https://macos.telegram.org/" | /usr/bin/grep -A2 Version | /usr/bin/tail -n 1 | /usr/bin/xmllint --html --xpath '//*/h3/text()' - | /usr/bin/xargs)
      downloadURL="https://osx.telegram.org/updates/Telegram.dmg"
      ;;

    theunarchiver)
      URL="https://theunarchiver.com"
      currentVers=$(/usr/bin/curl -s "${URL}" | /usr/bin/grep "Latest version" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//div[@class="latest-version"]/small/strong/following-sibling::text())' - | /usr/bin/awk '{print $1}')
      downloadURL=$(/usr/bin/curl -s "${URL}" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)
      ;;

    thunderbird)
      currentVers=$(/usr/bin/curl -fs "https://product-details.mozilla.org/1.0/thunderbird_versions.json" | /usr/bin/jq -r .LATEST_THUNDERBIRD_VERSION)
      downloadURL="https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/${currentVers}/mac/en-US/Thunderbird%20${currentVers}.dmg"
      ;;

    thunderbirdesr)
      currentVers=$(/usr/bin/curl -fs "https://product-details.mozilla.org/1.0/thunderbird_versions.json" | /usr/bin/jq -r .THUNDERBIRD_ESR)
      downloadURL="https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/${currentVers}/mac/en-US/Thunderbird%20${currentVers}.dmg"
      ;;

    touch_designer)
      currentVers=$(/usr/bin/curl -s "https://derivative.ca/download" -A 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15' | /usr/bin/grep -A 2 MACOS | /usr/bin/tail -n 1 | /usr/bin/awk '{print $1}')
      if [ "${platformType}" = "Linux" ]; then
        archType="arm64"
      else
        case $(arch) in
          arm64)
            archType="arm64"
            ;;

          x86_64)
            archType="intel"
            ;;

          *)
            /bin/echo "Unknown architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL="https://download.derivative.ca/TouchDesigner.${currentVers}.${archType}.dmg"
      ;;

    transmission)
      gitHubURL="https://github.com/transmission/transmission"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}")
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    utm)
      gitHubURL="https://github.com/utmapp/UTM"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep dmg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    visual_studio_code)
      jsonData=$(/usr/bin/curl -s "https://update.code.visualstudio.com/api/update/darwin-universal/stable/dc96b837cf6bb4af9cd736aa3af08cf8279f7685")
      currentVers=$(printf '%s' "${jsonData}" | "${jqBin}" -r .productVersion)
      downloadURL=$(printf '%s' "${jsonData}" | "${jqBin}" -r .url)
      ;;

    vlc)
      currentVers=$(/usr/bin/curl -s "https://www.videolan.org/vlc/download-macosx.html" | /usr/bin/grep -o "get.videolan.org/vlc/.*/macosx/vlc-.*-universal.dmg" | /usr/bin/cut -d "/" -f -4 - | /usr/bin/awk -F"/" '{print $3}')
      downloadURL="http://get.videolan.org/vlc/${currentVers}/macosx/vlc-${currentVers}-universal.dmg"
      ;;

    vnc_server)
      jSON=$(/usr/bin/curl -Ls "https://www.realvnc.com/en/connect/download/vnc" -H user-agent:" Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" | /usr/bin/tr '>' '\n' | /usr/bin/grep pkg | /usr/bin/tail -n 1 | /usr/bin/sed 's/<\/script//')
      currentVers=$(printf '%s\n' "${jSON}" | "${jqBin}" -r '.index.connect.products.vnc.platforms.macos.versions | to_entries | .[0].value.number')
      downloadURL="https://downloads.realvnc.com/download/file/vnc.files/$(printf '%s\n' "${jSON}" | "${jqBin}" -r '.index.connect.products.vnc.platforms.macos.versions | to_entries | .[0].value.files[].file')"
      ;;

    vnc_viewer)
      jSON=$(curl -Ls "https://www.realvnc.com/en/connect/download/viewer" -H user-agent:" Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" | /usr/bin/tr '>' '\n' | /usr/bin/grep dmg | /usr/bin/tail -n 1 | /usr/bin/sed 's/<\/script//')
      currentVers=$(printf '%s\n' "${jSON}" | "${jqBin}" -r '.index.connect.products.viewer.platforms.macos.versions | to_entries | .[0].value.number')
      downloadURL="https://downloads.realvnc.com/download/file/viewer.files/$(printf '%s\n' "${jSON}" | "${jqBin}" -r '.index.connect.products.viewer.platforms.macos.versions | to_entries | .[0].value.files[].file')"
      ;;

    voodoopad)
      currentVers=$(/usr/bin/curl -s "https://www.voodoopad.com/" -A 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15' | /usr/bin/grep Version | /usr/bin/xmllint --xpath '//p/text()' - | /usr/bin/awk '{print $2}')
      downloadURL="https://voodoopad.s3.amazonaws.com/VoodooPad-${currentVers}.zip"
      ;;

    webex)
      currentVers=$(/usr/bin/curl -s "https://help.webex.com/en-us/article/mqkve8/Webex-App-%7C-Release-notes" | /usr/bin/sed 's/<[^>]*>//g' | /usr/bin/grep -E '^\s*Mac—' | /usr/bin/head -n 1 | /usr/bin/sed -e 's/ //g' -e 's/Mac—//')
      if [ "${platformType}" = "Linux" ]; then
        archType="macOS (Apple M1 chip)"
      else
        case $(uname -m) in
          arm64)
            archType="macOS (Apple M1 chip)"
            ;;

          x86_64)
            archType="macOS (Intel chip)"
            ;;

          *)
            /bin/echo "Unknown processor architecture. Exiting"
            exit 1
            ;;
        esac
      fi
      downloadURL=$(/usr/bin/curl -s "https://www.webex.com/downloads.html" | /usr/bin/grep "${archType}" | /usr/bin/head -n 1 | /usr/bin/grep -o 'uri="[^"]*' | /usr/bin/sed 's/uri="//')
      ;;

    whatsapp)
      downloadURL=$(/usr/bin/curl -sI "https://web.whatsapp.com/desktop/mac_native/release/?configuration=Release" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//')
      currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE "WhatsApp-[0-9]+(\.[0-9]+)*" | /usr/bin/sed 's/WhatsApp-2.//')
      ;;

    wireshark)
      xmlData=$(/usr/bin/curl -s "https://www.wireshark.org/update/0/Wireshark/3.6.3/macOS/x86-64/en-US/stable.xml")
      currentVers=$(printf '%s' "${xmlData}"| /usr/bin/xmllint --xpath '//rss/channel/item[1]/title/text()' - | /usr/bin/awk '{print $2}')
      downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath 'string(//rss/channel/item[1]/enclosure/@url)' -)
      ;;

    xquartz)
      gitHubURL="https://github.com/xquartz/xquartz"
      latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
      currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
      downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
      ;;

    yubico_authenticator)
      downloadURL="https://developers.yubico.com/yubioath-flutter/Releases/yubico-authenticator-latest-mac.dmg"
      currentVers=$(/usr/bin/curl -sI "${downloadURL}" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/grep -oE 'yubico-authenticator-[0-9]+(\.[0-9]+)*' | /usr/bin/sed 's/yubico-authenticator-//')
      ;;

    zoom)
      currentVers=$(/usr/bin/curl -s "https://zoom.us/rest/download?os=mac" | /usr/bin/jq -r .result.downloadVO.zoom.displayVersion | /usr/bin/cut -d " " -f 1 -)
      downloadURL="https://zoom.us/client/latest/ZoomInstallerIT.pkg"
      ;;

    zotero)
      currentVers=$(/usr/bin/curl -s "https://www.zotero.org/download/" | /usr/bin/grep mac | /usr/bin/awk '{print $2}' | /usr/bin/sed -e 's/,"Windows$//' -e 's/$/}}/' | /usr/bin/tail -n 1 | /usr/bin/jq -r .standaloneVersions.mac)
      downloadURL="https://download.zotero.org/client/release/${currentVers}/Zotero-${currentVers}.dmg"
      ;;
  esac

  if ! expr "${currentVers}" : '.*[0-9]' > /dev/null && ! expr "${currentVers}" : '.*\.' > /dev/null; then
    currentVers="ERROR"
  fi

  case $(/usr/bin/curl -s -o /dev/null -w "%{http_code}" -LI "${downloadURL}" 2>/dev/null) in
    200|302)
      downloadResult="${downloadURL}"
      ;;

    *)
      downloadResult="FAIL"
      ;;
  esac

  if [ -t 1 ] ; then
    /bin/echo "${theApp},${currentVers},${downloadResult}"
    /bin/echo ""
  else
    /bin/echo "${theApp},${currentVers},${downloadResult}" >> "${theFile}"
    /bin/echo "" >> "${theFile}"
  fi
done

if [ ! -t 1 ] ; then
  if [ "${platformType}" = "Darwin" ]; then
    mailArgs="-v -s"
  else
    mailArgs="-s"
  fi
  /usr/bin/mail "${mailArgs}" "App Versions for $(date -I)" "${email}" < "${theFile}"
  /bin/rm "${theFile}"
fi
