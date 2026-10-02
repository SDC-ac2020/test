#!/bin/bash
# Copyright Planet Enterprises Ltd 2018
# Planet eSign Client installation tool
# Version 1.5
# Supported Linux OS: Ubuntu 16.04+, Raspbian, Debian 8+, CentOS 7, OpenSUSE Tumbleweed, Fedora, Mint
# Version 1.2 - removes the Assistive Technology from the OpenJDK
# Version 1.3 - Disables the screensaver and locks, etc
# Version 1.4 - Adds a change for the Intel Compute sticks to handle audio differences
# Version 1.5 - Disables automatic check for updates, should prevent a popup when out of date.
detect_os() {
        if [ -e /etc/apt/sources.list.d/raspi.list ]; then
                os="raspbian"
        elif [ -e /etc/lsb-release ]; then
                . /etc/lsb-release

                if [ "${ID}" = "raspbian" ]; then
                        os=${ID}
                        dist=$(cut --delimiter='.' -f1 /etc/debian_version)
                else
                        os=${DISTRIB_ID}
                        dist=${DISTRIB_CODENAME}

                        if [ -z "$dist" ]; then
                                dist=${DISTRIB_RELEASE}
                        fi
                fi

        elif [ $(which lsb_release 2>/dev/null) ]; then
                echo "Which lsb_release"
                dist=$(lsb_release -c | cut -f2)
                os=$(lsb_release -i | cut -f2 | awk '{ print tolower($1) }')

        elif [ -e /etc/debian_version ]; then
                # some Debians have jessie/sid in their /etc/debian_version
                # while others have '6.0.7'
                echo "debian_version"
                os=$(cat /etc/issue | head -1 | awk '{ print tolower($1) }')
                if grep -q '/' /etc/debian_version; then
                        dist=$(cut --delimiter='/' -f1 /etc/debian_version)
                else
                        dist=$(cut --delimiter='.' -f1 /etc/debian_version)
                fi

        elif [ -e /etc/centos-release ]; then
                os='centos'

        elif [ -f /etc/os-release ]; then
                source /etc/os-release
                if [ -n "${PRETTY_NAME}" ]; then

                        os=${PRETTY_NAME}
                else

                        [[ -n "${VERSION}" ]] && printf " ${VERSION}"

                        os=${NAME}
                fi

        else
                unknown_os
        fi

        # remove whitespace from OS and dist name
        os="${os// /}"
        dist="${dist// /}"

        echo "Detected operating system as $os."
}

if [[ $EUID == 0 ]]; then
        echo "Please run this script using the Digital Signage user"
        exit
fi

check_deps() {
        if [[ $(which java) ]]; then
                echo 'Java exists'
        else
                echo 'Java does not exist'
                exit 1
        fi

        if [[ $(which firefox) ]]; then
                echo 'Firefox exists'
        else
                echo 'Firefox does not exist'
                exit 1
        fi
}

welcome_text() {
        echo 'Welcome to the Planet eStream Digital Signage Client Linux installer'
        echo 'This will install the necessary software dependencies for the Digital Signage Client to run'
        echo 'OS Updates will be applied during this installation'
        echo 'The installer will request escalation for running updates and installation of dependencies'
        echo 'The client will be set to run at logon'
        echo 'Please set a user to login automatically'
        echo 'Please disable any power management settings such as idle lock and display timeout'
        echo 'If you have any questions regarding the client please contact Planet eStream Support on:'
        echo 'Email: support@planetestream.co.uk'
        echo 'Phone: 01274 713425'
        echo ' '
}

main() {
        welcome_text
        # detect_os

        echo "Checking network connection"
        wget -q --spider https://www.google.co.uk/

        if [ $? -eq 0 ]; then
                echo "Network connectivity found!"
        else
                echo "No network connection found, please check that access to the internet has been provided."
                exit
        fi

        if [ -d ~/.mozilla ]; then
                echo "Clearing Firefox cache"
                rm -rf ~/.mozilla
                rm -rf ~/.cache/mozilla/
        fi

        if [ $os == "Ubuntu" ]; then
                echo "Ubuntu detected"
                # The update manager application is known to load automatically, this locks the various tools used in this script.
                killall update-manager &>/dev/null

                # attempting to approve the EULA for the ttf-mscorefonts-installer
                echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
                echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

                echo "Updating and installing dependencies"
                sudo apt-get update
                sudo apt-get dist-upgrade -y
                DEBIAN_FRONTEND=noninteractive sudo apt-get install ttf-mscorefonts-installer -y
                sudo apt-get install default-jdk unclutter firefox ubuntu-restricted-extras unzip -y
                sudo apt-get remove gnome-screensaver -y

                # In some setups HTTPS sites will not load in Java without this being setup
                echo "Updating Java SSL settings"
                printf '\xfe\xed\xfe\xed\x00\x00\x00\x02\x00\x00\x00\x00\xe2\x68\x6e\x45\xfb\x43\xdf\xa4\xd9\x92\xdd\x41\xce\xb6\xb2\x1c\x63\x30\xd7\x92' | sudo tee /etc/ssl/certs/java/cacerts 1>/dev/null
                sudo /var/lib/dpkg/info/ca-certificates-java.postinst configure 1>/dev/null

                echo 'Attempting to disable screensaver, display lock, and auto dim options'
                gsettings set org.gnome.desktop.session idle-delay 0
                gsettings set org.gnome.desktop.screensaver lock-enabled false
                gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
                gsettings set com.ubuntu.update-notifier no-show-notifications true

                # Keyring for saving passwords usually will unlock, when a user is set to automatically login this is not automatically done.
                # This disables the keyring operation so it does not show for each load
                echo 'Disabling Gnome Keyring'
                sudo chmod -x $(type -p gnome-keyring-daemon)

                # The HDMI audio can have issues with certain versions of the Intel Compute Stick,
                # this fix is explained in http://linuxiumcomau.blogspot.com/2018/03/fixing-broken-hdmi-audio-again.html?
               # prod=$(cat /sys/class/dmi/id/product_name)
                #if [[ $prod == 'STK1A32SC' ]] || [[ $prod == 'STK1AW32SC' ]]; then
                #       echo "Intel Compute Stick detected! Applying audio patch"
                #        if grep -Rq "Linuxium" /etc/pulse/default.pa; then
                #                echo "Compute Stick audio fix already set"
                #        else
                #                sudo sed -i '/module-detect/ {n;a\
                #                ### Linuxium fix for HDMI audio on Intel Compute Stick products STK1A32SC and STK1AW32SC\
                #                unload-module module-alsa-card\
                #                load-module module-alsa-sink device=hw:0,2
                #                }' /etc/pulse/default.pa
                #                pulseaudio -k
                #                pulseaudio --start
                #        fi
                #fi

                if grep -Rq "#assistive" /etc/java-*-openjdk/accessibility.properties; then
                        echo "Assistive Technologies already disabled"
                else
                        echo "Disabling Assistive Technologies"
                        sudo sed -i "s/^assistive_technologies=/#&/" /etc/java-*-openjdk/accessibility.properties
                fi
                # Below disabled to allow scheduled updates
                # echo "Disabling automatic check for updates"
                # sudo sed -i 's/APT::Periodic::Update-Package-Lists "1"/APT::Periodic::Update-Package-Lists "0"/' /etc/apt/apt.conf.d/20auto-upgrades

                FILE=/lib/firefox/firefox.cfg
                if [ -f "$FILE" ]; then
                        echo "$FILE exists."
                        printf '// IMPORTANT: Start your code on the 2nd line\nlockPref("media.videocontrols.picture-in-picture.enabled", false);\nlockPref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);\nlockPref("trailhead.firstrun.didSeeAboutWelcome", true);\nlockPref("browser.aboutwelcome.enabled", false);\nlockPref("browser.preferences.defaultPerformanceSettings.enabled", false);\n;\nPref("layers.acceleration.disabled", true);\nlockPref("media.autoplay.default", 0);\n' | sudo tee /lib/firefox/firefox.cfg 1>/dev/null
                        printf 'pref("general.config.filename", "firefox.cfg");\npref("general.config.obscure_value", 0);\n' | sudo tee /lib/firefox/defaults/pref/autoconfig.js 1>/dev/null
                else
                        echo "$FILE does not exist."
                        printf '// IMPORTANT: Start your code on the 2nd line\nlockPref("media.videocontrols.picture-in-picture.enabled", false);\nlockPref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);\nlockPref("trailhead.firstrun.didSeeAboutWelcome", true);\nlockPref("browser.aboutwelcome.enabled", false);\nlockPref("browser.preferences.defaultPerformanceSettings.enabled", false);\n;\nPref("layers.acceleration.disabled", true);\nlockPref("media.autoplay.default", 0);\n' | sudo tee /lib/firefox/firefox.cfg 1>/dev/null
                        printf 'pref("general.config.filename", "firefox.cfg");\npref("general.config.obscure_value", 0);\n' | sudo tee /lib/firefox/defaults/pref/autoconfig.js 1>/dev/null
                fi

        elif
                [ $os == "raspbian" ]
        then
                echo "Raspberry Pi detected"
                echo "Updating and installing dependencies"
                sudo apt-get purge xscreensaver -y 1>/dev/null
                sudo apt-get update 1>/dev/null
                sudo apt-get dist-upgrade -y 1>/dev/null
                sudo apt-get install default-jdk unclutter firefox -y 1>/dev/null

                if [[ $(which firefox) ]]; then
                        echo 'Firefox exists'
                else
                        echo 'Firefox does not exist, attempting installation of ESR version'
                        sudo apt-get install firefox-esr -y 1>/dev/null
                fi

                echo "Attempting to update the Java SSL"
                printf '\xfe\xed\xfe\xed\x00\x00\x00\x02\x00\x00\x00\x00\xe2\x68\x6e\x45\xfb\x43\xdf\xa4\xd9\x92\xdd\x41\xce\xb6\xb2\x1c\x63\x30\xd7\x92' | sudo tee /etc/ssl/certs/java/cacerts 1>/dev/null
                sudo /var/lib/dpkg/info/ca-certificates-java.postinst configure 1>/dev/null

                echo 'Disabling screensaver options'
                xset s off
                xset s noblank
                xset -dpms

                if test -f ".profile"; then
                        echo "$FILE exist"
                        if grep -Rq "xset s off" .profile; then
                                echo "Screensaver set"
                        else
                                echo '# Planet eStream screensaver settings' >>.profile
                                echo 'xset s off' >>.profile
                                echo 'xset s noblank' >>.profile
                                echo 'xset -dpms' >>.profile
                        fi
                fi

                FILE=/lib/firefox-esr/firefox.cfg
                if [ -f "$FILE" ]; then
                        echo "$FILE exists."
                        printf '// IMPORTANT: Start your code on the 2nd line\nlockPref("media.videocontrols.picture-in-picture.enabled", false);\nlockPref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);\nlockPref("trailhead.firstrun.didSeeAboutWelcome", true);\nlockPref("browser.preferences.defaultPerformanceSettings.enabled", false);\nlockPref("browser.aboutwelcome.enabled", false);\n;\nlockPref("media.autoplay.default", 0);\n' | sudo tee /usr/lib/firefox-esr/firefox.cfg 1>/dev/null
                        printf 'pref("general.config.filename", "firefox.cfg");\npref("general.config.obscure_value", 0);\n' | sudo tee /usr/lib/firefox-esr/defaults/pref/autoconfig.js 1>/dev/null
                        printf '// IMPORTANT: Start your code on the 2nd line\nlockPref("media.videocontrols.picture-in-picture.enabled", false);\nlockPref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);\nlockPref("trailhead.firstrun.didSeeAboutWelcome", true);\nlockPref("browser.preferences.defaultPerformanceSettings.enabled", false);\nlockPref("browser.aboutwelcome.enabled", false);\n;\nlockPref("media.autoplay.default", 0);\n' | sudo tee /lib/firefox-esr/firefox.cfg 1>/dev/null
                        printf 'pref("general.config.filename", "firefox.cfg");\npref("general.config.obscure_value", 0);\n' | sudo tee /lib/firefox-esr/defaults/pref/autoconfig.js 1>/dev/null
                else
                        echo "$FILE does not exist."
                        printf '// IMPORTANT: Start your code on the 2nd line\nlockPref("media.videocontrols.picture-in-picture.enabled", false);\nlockPref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);\nlockPref("trailhead.firstrun.didSeeAboutWelcome", true);\nlockPref("browser.preferences.defaultPerformanceSettings.enabled", false);\nlockPref("browser.aboutwelcome.enabled", false);\n;\nlockPref("media.autoplay.default", 0);\n' | sudo tee /usr/lib/firefox-esr/firefox.cfg 1>/dev/null
                        printf 'pref("general.config.filename", "firefox.cfg");\npref("general.config.obscure_value", 0);\n' | sudo tee /usr/lib/firefox-esr/defaults/pref/autoconfig.js 1>/dev/null
                        printf '// IMPORTANT: Start your code on the 2nd line\nlockPref("media.videocontrols.picture-in-picture.enabled", false);\nlockPref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);\nlockPref("trailhead.firstrun.didSeeAboutWelcome", true);\nlockPref("browser.preferences.defaultPerformanceSettings.enabled", false);\nlockPref("browser.aboutwelcome.enabled", false);\n;\nlockPref("media.autoplay.default", 0);\n' | sudo tee /lib/firefox-esr/firefox.cfg 1>/dev/null
                        printf 'pref("general.config.filename", "firefox.cfg");\npref("general.config.obscure_value", 0);\n' | sudo tee /usr/lib/firefox-esr/defaults/pref/autoconfig.js 1>/dev/null
                fi

                FILE=/lib/firefox/firefox.cfg
                if [ -f "$FILE" ]; then
                        echo "$FILE exists."
                        printf '// IMPORTANT: Start your code on the 2nd line\nlockPref("media.videocontrols.picture-in-picture.enabled", false);\nlockPref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);\nlockPref("trailhead.firstrun.didSeeAboutWelcome", true);\nlockPref("browser.preferences.defaultPerformanceSettings.enabled", false);\nlockPref("browser.aboutwelcome.enabled", false);\n;\nlockPref("media.autoplay.default", 0);\n' | sudo tee /usr/lib/firefox/firefox.cfg 1>/dev/null
                        printf 'pref("general.config.filename", "firefox.cfg");\npref("general.config.obscure_value", 0);\n' | sudo tee /usr/lib/firefox/defaults/pref/autoconfig.js 1>/dev/null
                        printf '// IMPORTANT: Start your code on the 2nd line\nlockPref("media.videocontrols.picture-in-picture.enabled", false);\nlockPref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);\nlockPref("trailhead.firstrun.didSeeAboutWelcome", true);\nlockPref("browser.preferences.defaultPerformanceSettings.enabled", false);\nlockPref("browser.aboutwelcome.enabled", false);\n;\nlockPref("media.autoplay.default", 0);\n' | sudo tee /lib/firefox/firefox.cfg 1>/dev/null
                        printf 'pref("general.config.filename", "firefox.cfg");\npref("general.config.obscure_value", 0);\n' | sudo tee /lib/firefox/defaults/pref/autoconfig.js 1>/dev/null
                else
                        echo "$FILE does not exist."
                        printf '// IMPORTANT: Start your code on the 2nd line\nlockPref("media.videocontrols.picture-in-picture.enabled", false);\nlockPref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);\nlockPref("trailhead.firstrun.didSeeAboutWelcome", true);\nlockPref("browser.preferences.defaultPerformanceSettings.enabled", false);\nlockPref("browser.aboutwelcome.enabled", false);\n;\nlockPref("media.autoplay.default", 0);\n' | sudo tee /usr/lib/firefox/firefox.cfg 1>/dev/null
                        printf 'pref("general.config.filename", "firefox.cfg");\npref("general.config.obscure_value", 0);\n' | sudo tee /usr/lib/firefox/defaults/pref/autoconfig.js 1>/dev/null
                        printf '// IMPORTANT: Start your code on the 2nd line\nlockPref("media.videocontrols.picture-in-picture.enabled", false);\nlockPref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);\nlockPref("trailhead.firstrun.didSeeAboutWelcome", true);\nlockPref("browser.preferences.defaultPerformanceSettings.enabled", false);\nlockPref("browser.aboutwelcome.enabled", false);\n;\nlockPref("media.autoplay.default", 0);\n' | sudo tee /lib/firefox/firefox.cfg 1>/dev/null
                        printf 'pref("general.config.filename", "firefox.cfg");\npref("general.config.obscure_value", 0);\n' | sudo tee /usr/lib/firefox/defaults/pref/autoconfig.js 1>/dev/null
                fi

        elif [ $os == "debian" ]; then
                echo "Debian detected"
                sudo apt-get update && sudo apt-get dist-upgrade -y

                sudo apt-get install openjdk-21-jdk unclutter firefox -y
                sudo apt-get remove gnome-screensaver -y

        elif [ $os == "LinuxMint" ]; then
                echo "LinuxMint detected"
                sudo apt-get update && sudo apt-get dist-upgrade -y

                sudo apt-get install openjdk-11-jdk unclutter firefox -y
                sudo apt-get remove gnome-screensaver -y

        elif
                [[ $os == *"SUSE"* ]]
        then
                echo "OpenSUSE detected"
                sudo zypper -n refresh
                sudo zypper -n install chromium openjdk-11-jdk unclutter

        elif [ $os == "centos" ]; then
                echo "CentOS detected"
                sudo yum update -y
                sudo yum install epel-release -y
                sudo yum install chromium openjdk-11-jdk unclutter -y

        elif [[ $os == *"Fedora"* ]]; then
                echo "Fedora detected"
                sudo yum update -y
                sudo yum install chromium openjdk-11-jdk unclutter -y

        else
                echo 'Operating system type not detected, please contact Planet eStream Support at: support@planetestream.co.uk for help'
                exit
        fi

        check_deps

        quote="'"

        echo '#!/bin/bash' >run.sh
        echo 'unclutter -idle 5.0 -root &' >>run.sh
        echo 'killall firefox' >>run.sh
        echo 'killall java' >>run.sh
        #printf 'perl -pi -e ''s/exit_type\":\"Crashed/exit_type\":\"none/'' ~/.config/chromium/Default/Preferences'
        #echo 'perl -pi -e '$quote's/exit_type\":\"Crashed/exit_type\":\"none/'$quote' ~/.config/chromium/Default/Preferences' >>run.sh
        #echo 'sed -i '$quote's/"exited_cleanly": false/"exited_cleanly": true/'$quote' ~/.config/chromium/Default/Preferences' >>run.sh
        #echo 'sed -i '$quote's/"exit_type": "Crashed"/"exit_type": "None"/'$quote' ~/.config/chromium/Default/Preferences' >>run.sh
        echo 'cd eSignJava' >>run.sh
        echo 'java -cp .:json.jar eSign >>Debug.txt' >>run.sh

        chmod +x run.sh

        FILE=eSignJava.zip

        # should handle if the eSignJava has been downloaded already

        if [ -f "$FILE" ]; then
                echo "$FILE exists (1)."
        else
                wget 'https://www.planetestream.co.uk/files/eSignJava.zip' &>/dev/null
                #wget 'http://files.planetestream.org/files/eSignJava.zip'
                #curl -L 'https://www.planetestream.co.uk/files/eSignJava.zip' --output 'eSignJava.zip'
        fi

        if [ -f "$FILE" ]; then
                echo "$FILE exists (2)."
        else
                echo "There was an error downloading $FILE, exiting."
                exit 1
        fi

        if [ -f "./eSignJava/settings.txt" ]; then
                echo "Settings file exists, saving"
                mv ./eSignJava/settings.txt ./eSignJava/settings.txt.bak
        fi

        unzip -o -j 'eSignJava.zip' -d ~/eSignJava &>/dev/null

        # testing path exists, just in case the unzip fails
        if [ -d "eSignJava" ]; then
                echo "Extracted eSignJava folder exists."
        else
                echo "There was an error extracting file, exiting."
                exit 1
        fi

        if [ -f "./eSignJava/settings.txt.bak" ]; then
                echo "Settings file exists, restoring"
                mv ./eSignJava/settings.txt.bak ./eSignJava/settings.txt
        fi

        cd eSignJava

        echo "Compiling eSign Client"
        javac -cp .:json.jar main.java

        cd ~/

        rm 'eSignJava.zip'

        # Attempts to set the default browser to Chrome to prevent the notification that shows without user intervention
        if grep -Rq "text/html=firefox.desktop" .config/mimeapps.list; then
                echo "Firefox default already set"
        else
                echo "Setting Firefox to default browser"
                echo '[Default Applications]' >>.config/mimeapps.list
                echo 'text/html=firefox.desktop' >>.config/mimeapps.list
                echo 'x-scheme-handler/http=firefox.desktop' >>.config/mimeapps.list
                echo 'x-scheme-handler/https=firefox.desktop' >>.config/mimeapps.list
                echo 'x-scheme-handler/about=firefox.desktop' >>.config/mimeapps.list
                echo 'x-scheme-handler/unknown=firefox.desktop' >>.config/mimeapps.list
        fi

        mkdir .config/autostart 1>/dev/null

        if [ -f ".config/autostart/run.sh.desktop" ]; then
                echo "Autostart file exists"
        else
                echo "Setting client to autostart"
                echo '[Desktop Entry]' >>.config/autostart/run.sh.desktop
                echo 'Type=Application' >>.config/autostart/run.sh.desktop
                echo 'Exec='${HOME}'/run.sh' >>.config/autostart/run.sh.desktop
                echo 'Hidden=false' >>.config/autostart/run.sh.desktop
                echo 'NoDisplay=false' >>.config/autostart/run.sh.desktop
                echo 'X-GNOME-Autostart-enabled=true' >>.config/autostart/run.sh.desktop
                echo 'Name[en_GB]=eSign' >>.config/autostart/run.sh.desktop
                echo 'Name=eSign' >>.config/autostart/run.sh.desktop
                echo 'Comment[en_GB]=' >>.config/autostart/run.sh.desktop
                echo 'Comment=' >>.config/autostart/run.sh.desktop
        fi

        if sudo grep -Rq "reboot" /etc/sudoers; then
                echo "Sudo permissions already set"
        else
                echo 'Adding the current user to sudoers to allow reboot commands'
                sudo sh -c "echo \"${USER} ALL=(ALL) NOPASSWD: /sbin/reboot\" >> /etc/sudoers"
        fi

        echo 'The Planet eSign Client has now been installed'
        echo 'You can run the client manually by running: ./run.sh'
        echo 'Or by rebooting the device'
        echo 'Please note it is recommended to reboot the device if kernel updates were applied'
        echo ''
}

for ARGUMENT in "$@"; do
        KEY=$(echo $ARGUMENT | cut -f1 -d=)

        KEY_LENGTH=${#KEY}
        VALUE="${ARGUMENT:$KEY_LENGTH+1}"

        export "$KEY"="$VALUE"
done

echo "OS = $os"

if [ -z "$os" ]; then
        detect_os
fi

main "$os"
