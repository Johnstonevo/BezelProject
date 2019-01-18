#!/bin/bash

#IFS=';'
raconfigdir="$HOME/.config/retroarch"
configdir="$HOME/.config/RetroPie"
# Welcome
 dialog --backtitle "The Bezel Project" --title "The Bezel Project - Bezel Pack Utility" \
    --yesno "\nThe Bezel Project Bezel Utility menu.\n\nThis utility will provide a downloader for Retroarach system bezel packs to be used for various systems within RetroPie.\n\nThese bezel packs will only work if the ROMs you are using are named according to the No-Intro naming convention used by EmuMovies/HyperSpin.\n\nThis utility provides a download for a bezel pack for a system and includes a PNG bezel file for every ROM for that system.  The download will also include the necessary configuration files needed for Retroarch to show them.  The script will also update the required retroarch.cfg files for the emulators located in the /opt/retropie/configs directory.  These changes are necessary to show the PNG bezels with an opacity of 1.\n\nPeriodically, new bezel packs are completed and you will need to run the script updater to download the newest version to see these additional packs.\n\n**NOTE**\nThe MAME bezel back is inclusive for any roms located in the arcade/fba/mame-libretro rom folders.\n\n\nDo you want to proceed?" \
    28 110 2>&1 > /dev/tty \
    || exit




function main_menu() {
    local choice

    while true; do
        choice=$(dialog --backtitle "$BACKTITLE" --title " MAIN MENU " \
            --ok-label OK --cancel-label Exit \
            --menu "What action would you like to perform?" 25 75 20 \
            1 "Download system bezel pack (will automatcally enable bezels)" \
            2 "Enable system bezel pack" \
            3 "Disable system bezel pack" \
            4 "Information:  Retroarch cores setup for bezels per system" \
            2>&1 > /dev/tty)

        case "$choice" in
            1) download_bezel  ;;
            2) enable_bezel  ;;
            3) disable_bezel  ;;
            4) retroarch_bezelinfo  ;;
            *)  break ;;
        esac
    done
}

#########################################################
# Functions for download and enable/disable bezel packs #
#########################################################

function install_bezel_pack() {
    local theme="$1"
    local repo="$2"
    if [[ -z "$repo" ]]; then
        repo="default"
    fi
    if [[ -z "$theme" ]]; then
        theme="default"
        repo="default"
    fi
    atheme=`echo ${theme} | sed 's/.*/\L&/'`

    if [[ "${atheme}" == "mame" ]];then
      mv "$raconfigdir/config/disable_FB Alpha" "$raconfigdir/config/FB Alpha" 2> /dev/null
      mv "$raconfigdir/config/disable_MAME 2003" "$raconfigdir/config/MAME 2003" 2> /dev/null
      mv "$raconfigdir/config/disable_MAME 2010" "$raconfigdir/config/MAME 2010" 2> /dev/null
    fi

    git clone "https://github.com/$repo/bezelproject-$theme.git" "/home/$USER/RetroPie-Setup/tmp/${theme}"
    cp -r "/home/$USER/RetroPie-Setup/tmp/${theme}/retroarch/" ../$raconfigdir
    sudo rm -rf "/tmp/${theme}"

    if [[ "${atheme}" == "mame" ]];then
      show_bezel "arcade"
      show_bezel "fba"
      show_bezel "mame-libretro"
    else
      show_bezel "${atheme}"
    fi
}

function uninstall_bezel_pack() {
    local theme="$1"
    if [[ -d "$raconfigdir/overlay/GameBezels/$theme" ]]; then
        rm -rf "$raconfigdir/overlay/GameBezels/$theme"
    fi
    if [[ "${theme}" == "MAME" ]]; then
      if [[ -d "$raconfigdir/overlay/ArcadeBezels" ]]; then
        rm -rf "$raconfigdir/overlay/ArcadeBezels"
      fi
    fi
}

function download_bezel() {
    local themes=(
        'thebezelproject MAME'
        'thebezelproject Atari2600'
        'thebezelproject Atari5200'
        'thebezelproject Atari7800'
        'thebezelproject GCEVectrex'
        'thebezelproject MasterSystem'
        'thebezelproject MegaDrive'
        'thebezelproject NES'
        'thebezelproject Sega32X'
        'thebezelproject SegaCD'
        'thebezelproject SG-1000'
        'thebezelproject SNES'
        'thebezelproject SuperGrafx'
        'thebezelproject PSX'
        'thebezelproject TG16'
        'thebezelproject TG-CD'
    )
    while true; do
        local theme
        local installed_bezelpacks=()
        local repo
        local options=()
        local status=()
        local default

        options+=(U "Update install script - script will exit when updated")

        local i=1
        for theme in "${themes[@]}"; do
            theme=($theme)
            repo="${theme[0]}"
            theme="${theme[1]}"
            if [[ -d "$raconfigdir/overlay/GameBezels/$theme" ]]; then
                status+=("i")
                options+=("$i" "Update or Uninstall $theme (installed)")
                installed_bezelpacks+=("$theme $repo")
            else
                status+=("n")
                options+=("$i" "Install $theme (not installed)")
            fi
            ((i++))
        done
        local cmd=(dialog --default-item "$default" --backtitle "$__backtitle" --menu "The Bezel Project -  Bezel Pack Downloader - Choose an option" 22 76 16)
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        default="$choice"
        [[ -z "$choice" ]] && break
        case "$choice" in
            U)  #update install script to get new theme listings
                if [[ -d "/home/pigaming" ]]; then
                    cd "/home/pigaming/RetroPie/retropiemenu"
                else
                    cd "/home/$USER/RetroPie/retropiemenu"
                fi
                mv "bezelproject.sh" "bezelproject.sh.bkp"
                wget "https://raw.githubusercontent.com/Johnstonevo/BezelProject/master/bezelproject.sh"
                chmod 777 "bezelproject.sh"
                exit
                ;;
            *)  #install or update themes
                theme=(${themes[choice-1]})
                repo="${theme[0]}"
                theme="${theme[1]}"
#                if [[ "${status[choice]}" == "i" ]]; then
                if [[ -d "$raconfigdir/overlay/GameBezels/$theme" ]]; then
                    options=(1 "Update $theme" 2 "Uninstall $theme")
                    cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option for the bezel pack" 12 40 06)
                    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
                    case "$choice" in
                        1)
                            install_bezel_pack "$theme" "$repo"
                            ;;
                        2)
                            uninstall_bezel_pack "$theme"
                            ;;
                    esac
                else
                    install_bezel_pack "$theme" "$repo"
                fi
                ;;
        esac
    done
}


function disable_bezel() {

clear
    while true; do
        choice=$(dialog --backtitle "$BACKTITLE" --title " MAIN MENU " \
            --ok-label OK --cancel-label Exit \
            --menu "Which system would you like to disable bezels for?" 25 75 20 \
            1 "GCEVectrex" \
            2 "SuperGrafx" \
            3 "Sega32X" \
            4 "SG-1000" \
            5 "Arcade" \
            6 "Final Burn Alpha" \
            7 "MAME Libretro" \
            8 "NES" \
            9 "MasterSystem" \
            10 "Atari 5200" \
            11 "Atari 7800" \
            12 "SNES" \
            13 "MegaDrive" \
            14 "SegaCD" \
            15 "PSX" \
            16 "TG16" \
            17 "TG-CD" \
            18 "Atari 2600" \
            2>&1 > /dev/tty)

        case "$choice" in
            1) hide_bezel vectrex ;;
            2) hide_bezel supergrafx ;;
            3) hide_bezel sega32x ;;
            4) hide_bezel sg-1000 ;;
            5) hide_bezel arcade ;;
            6) hide_bezel fba ;;
            7) hide_bezel mame-libretro ;;
            8) hide_bezel nes ;;
            9) hide_bezel mastersystem ;;
            10) hide_bezel atari5200 ;;
            11) hide_bezel atari7800 ;;
            12) hide_bezel snes ;;
            13) hide_bezel megadrive ;;
            14) hide_bezel segacd ;;
            15) hide_bezel psx ;;
            16) hide_bezel tg16 ;;
            17) hide_bezel tg-cd ;;
            18) hide_bezel atari2600 ;;
            *)  break ;;
        esac
    done

}

function enable_bezel() {

clear
    while true; do
        choice=$(dialog --backtitle "$BACKTITLE" --title " MAIN MENU " \
            --ok-label OK --cancel-label Exit \
            --menu "Which system would you like to enable bezels for?" 25 75 20 \
            1 "GCEVectrex" \
            2 "SuperGrafx" \
            3 "Sega32X" \
            4 "SG-1000" \
            5 "Arcade" \
            6 "Final Burn Alpha" \
            7 "MAME Libretro" \
            8 "NES" \
            9 "MasterSystem" \
            10 "Atari 5200" \
            11 "Atari 7800" \
            12 "SNES" \
            13 "MegaDrive" \
            14 "SegaCD" \
            15 "PSX" \
            16 "TG16" \
            17 "TG-CD" \
            18 "Atari 2600" \
            2>&1 > /dev/tty)

        case "$choice" in
            1) show_bezel gcevectrex ;;
            2) show_bezel supergrafx ;;
            3) show_bezel sega32x ;;
            4) show_bezel sg-1000 ;;
            5) show_bezel arcade ;;
            6) show_bezel fba ;;
            7) show_bezel mame-libretro ;;
            8) show_bezel nes ;;
            9) show_bezel mastersystem ;;
            10) show_bezel atari5200 ;;
            11) show_bezel atari7800 ;;
            12) show_bezel snes ;;
            13) show_bezel megadrive ;;
            14) show_bezel segacd ;;
            15) show_bezel psx ;;
            16) show_bezel tg16 ;;
            17) show_bezel tg-cd ;;
            18) show_bezel atari2600 ;;
            *)  break ;;
        esac
    done

}

function hide_bezel() {
dialog --infobox "...processing..." 3 20 ; sleep 2
emulator=$1
file="$configdir/${emulator}/retroarch.cfg"

case ${emulator} in
arcade)
  cp $configdir/${emulator}/retroarch.cfg $configdir/${emulator}/retroarch.cfg.bkp
  cat $configdir/${emulator}/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
  cp /tmp/retroarch.cfg $configdir/${emulator}/retroarch.cfg
  mv "$raconfigdir/config/FB Alpha" "$raconfigdir/config/disable_FB Alpha"
  mv "$raconfigdir/config/MAME 2003" "$raconfigdir/config/disable_MAME 2003"
  mv "$raconfigdir/config/MAME 2010" "$raconfigdir/config/disable_MAME 2010"
  ;;
fba)
  cp $configdir/${emulator}/retroarch.cfg $configdir/${emulator}/retroarch.cfg.bkp
  cat $configdir/${emulator}/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
  cp /tmp/retroarch.cfg $configdir/${emulator}/retroarch.cfg
  mv "$raconfigdir/config/FB Alpha" "$raconfigdir/config/disable_FB Alpha"
  ;;
mame-libretro)
  cp $configdir/${emulator}/retroarch.cfg $configdir/${emulator}/retroarch.cfg.bkp
  cat $configdir/${emulator}/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
  cp /tmp/retroarch.cfg $configdir/${emulator}/retroarch.cfg
  mv "$raconfigdir/config/MAME 2003" "$raconfigdir/config/disable_MAME 2003"
  mv "$raconfigdir/config/MAME 2010" "$raconfigdir/config/disable_MAME 2010"
  ;;
*)
  cp $configdir/${emulator}/retroarch.cfg $configdir/${emulator}/retroarch.cfg.bkp
  cat $configdir/${emulator}/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
  cp /tmp/retroarch.cfg $configdir/${emulator}/retroarch.cfg
  ;;
esac

}

function show_bezel() {
dialog --infobox "...processing..." 3 20 ; sleep 2
emulator=$1
file="$configdir/${emulator}/retroarch.cfg"

case ${emulator} in
arcade)
  ifexist=`cat $configdir/arcade/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/arcade/retroarch.cfg $configdir/arcade/retroarch.cfg.bkp
    cat $configdir/arcade/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/arcade/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/MAME-Horizontal.cfg"' $configdir/arcade/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/arcade/retroarch.cfg
    mv "$raconfigdir/config/disable_FB Alpha" "$raconfigdir/config/FB Alpha"
    mv "$raconfigdir/config/disable_MAME 2003" "$raconfigdir/config/MAME 2003"
    mv "$raconfigdir/config/disable_MAME 2010" "$raconfigdir/config/MAME 2010"
  else
    cp $configdir/arcade/retroarch.cfg $configdir/arcade/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/MAME-Horizontal.cfg"' $configdir/arcade/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/arcade/retroarch.cfg
    mv "$raconfigdir/config/disable_FB Alpha" "$raconfigdir/config/FB Alpha"
    mv "$raconfigdir/config/disable_MAME 2003" "$raconfigdir/config/MAME 2003"
    mv "$raconfigdir/config/disable_MAME 2010" "$raconfigdir/config/MAME 2010"
  fi
  ;;
fba)
  ifexist=`cat $configdir/fba/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/fba/retroarch.cfg $configdir/fba/retroarch.cfg.bkp
    cat $configdir/fba/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/fba/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/MAME-Horizontal.cfg"' $configdir/fba/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/fba/retroarch.cfg
    mv "$raconfigdir/config/disable_FB Alpha" "$raconfigdir/config/FB Alpha"
  else
    cp $configdir/fba/retroarch.cfg $configdir/fba/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/MAME-Horizontal.cfg"' $configdir/fba/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/fba/retroarch.cfg
    mv "$raconfigdir/config/disable_FB Alpha" "$raconfigdir/config/FB Alpha"
  fi
  ;;
mame-libretro)
  ifexist=`cat $configdir/mame-libretro/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/mame-libretro/retroarch.cfg $configdir/mame-libretro/retroarch.cfg.bkp
    cat $configdir/mame-libretro/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/mame-libretro/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/MAME-Horizontal.cfg"' $configdir/mame-libretro/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/mame-libretro/retroarch.cfg
    mv "$raconfigdir/config/disable_MAME 2003" "$raconfigdir/config/MAME 2003"
    mv "$raconfigdir/config/disable_MAME 2010" "$raconfigdir/config/MAME 2010"
    ln -s "$raconfigdir/config/MAME 2003" "$raconfigdir/config/MAME 2003 (0.78)"
    ln -s "$raconfigdir/config/MAME 2003" "$raconfigdir/config/MAME 2003-Plus"

  else
    cp $configdir/mame-libretro/retroarch.cfg $configdir/mame-libretro/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/MAME-Horizontal.cfg"' $configdir/mame-libretro/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/mame-libretro/retroarch.cfg
    mv "$raconfigdir/config/disable_MAME 2003" "$raconfigdir/config/MAME 2003"
    mv "$raconfigdir/config/disable_MAME 2010" "$raconfigdir/config/MAME 2010"
    ln -s "$raconfigdir/config/MAME 2003" "$raconfigdir/config/MAME 2003 (0.78)"
    ln -s "$raconfigdir/config/MAME 2003" "$raconfigdir/config/MAME 2003-Plus"

  fi
  ;;
atari2600)
  ifexist=`cat $configdir/atari2600/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/atari2600/retroarch.cfg $configdir/atari2600/retroarch.cfg.bkp
    cat $configdir/atari2600/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/atari2600/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-2600.cfg"' $configdir/atari2600/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atari2600/retroarch.cfg
  else
    cp $configdir/atari2600/retroarch.cfg $configdir/atari2600/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-2600.cfg"' $configdir/atari2600/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atari2600/retroarch.cfg
  fi
  ;;
atari5200)
  ifexist=`cat $configdir/atari5200/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/atari5200/retroarch.cfg $configdir/atari5200/retroarch.cfg.bkp
    cat $configdir/atari5200/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/atari5200/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-5200.cfg"' $configdir/atari5200/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atari5200/retroarch.cfg
  else
    cp $configdir/atari5200/retroarch.cfg $configdir/atari5200/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-5200.cfg"' $configdir/atari5200/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atari5200/retroarch.cfg
  fi
  ;;
atari7800)
  ifexist=`cat $configdir/atari7800/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/atari7800/retroarch.cfg $configdir/atari7800/retroarch.cfg.bkp
    cat $configdir/atari7800/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/atari7800/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-7800.cfg"' $configdir/atari7800/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atari7800/retroarch.cfg
  else
    cp $configdir/atari7800/retroarch.cfg $configdir/atari7800/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-7800.cfg"' $configdir/atari7800/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atari7800/retroarch.cfg
  fi
  ;;
coleco)
  ifexist=`cat $configdir/coleco/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/coleco/retroarch.cfg $configdir/coleco/retroarch.cfg.bkp
    cat $configdir/coleco/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/coleco/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Colecovision.cfg"' $configdir/coleco/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/coleco/retroarch.cfg
    ln -s $raconfigdir/config/BlueMSX $raconfigdir/config/blueMSX

  else
    cp $configdir/coleco/retroarch.cfg $configdir/coleco/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Colecovision.cfg"' $configdir/coleco/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/coleco/retroarch.cfg
    ln -s $raconfigdir/config/BlueMSX $raconfigdir/config/blueMSX

  fi
  ;;
famicom)
  ifexist=`cat $configdir/famicom/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/famicom/retroarch.cfg $configdir/famicom/retroarch.cfg.bkp
    cat $configdir/famicom/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/famicom/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Famicom.cfg"' $configdir/famicom/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/famicom/retroarch.cfg
  else
    cp $configdir/famicom/retroarch.cfg $configdir/famicom/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Famicom.cfg"' $configdir/famicom/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/famicom/retroarch.cfg
  fi
  ;;
fds)
  ifexist=`cat $configdir/fds/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/fds/retroarch.cfg $configdir/fds/retroarch.cfg.bkp
    cat $configdir/fds/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/fds/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Famicom-Disk-System.cfg"' $configdir/fds/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/fds/retroarch.cfg
  else
    cp $configdir/fds/retroarch.cfg $configdir/fds/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Famicom-Disk-System.cfg"' $configdir/fds/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/fds/retroarch.cfg
  fi
  ;;
mastersystem)
  ifexist=`cat $configdir/mastersystem/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/mastersystem/retroarch.cfg $configdir/mastersystem/retroarch.cfg.bkp
    cat $configdir/mastersystem/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/mastersystem/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Master-System.cfg"' $configdir/mastersystem/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/mastersystem/retroarch.cfg
  else
    cp $configdir/mastersystem/retroarch.cfg $configdir/mastersystem/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Master-System.cfg"' $configdir/mastersystem/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/mastersystem/retroarch.cfg
  fi
  ;;
megadrive)
  ifexist=`cat $configdir/megadrive/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/megadrive/retroarch.cfg $configdir/megadrive/retroarch.cfg.bkp
    cat $configdir/megadrive/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/megadrive/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Mega-Drive.cfg"' $configdir/megadrive/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/megadrive/retroarch.cfg
  else
    cp $configdir/megadrive/retroarch.cfg $configdir/megadrive/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Mega-Drive.cfg"' $configdir/megadrive/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/megadrive/retroarch.cfg
  fi
  ;;
megadrive-japan)
  ifexist=`cat $configdir/megadrive-japan/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/megadrive-japan/retroarch.cfg $configdir/megadrive-japan/retroarch.cfg.bkp
    cat $configdir/megadrive-japan/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/megadrive-japan/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Mega-Drive-Japan.cfg"' $configdir/megadrive-japan/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/megadrive-japan/retroarch.cfg
  else
    cp $configdir/megadrive-japan/retroarch.cfg $configdir/megadrive-japan/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Mega-Drive-Japan.cfg"' $configdir/megadrive-japan/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/megadrive-japan/retroarch.cfg
  fi
  ;;
n64)
  ifexist=`cat $configdir/n64/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/n6n64/retroarch.cfg $configdir/n64/retroarch.cfg.bkp
    cat $configdir/n6/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/n64/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-64.cfg"' $configdir/n64/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/n64/retroarch.cfg
  else
    cp $configdir/n64/retroarch.cfg $configdir/n64/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-64.cfg"' $configdir/n64/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/n64/retroarch.cfg
  fi
  ;;
neogeo)
  ifexist=`cat $configdir/neogeo/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/neogeo/retroarch.cfg $configdir/neogeo/retroarch.cfg.bkp
    cat $configdir/neogeo/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/neogeo/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/MAME-Horizontal.cfg"' $configdir/neogeo/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/neogeo/retroarch.cfg
  else
    cp $configdir/neogeo/retroarch.cfg $configdir/neogeo/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/MAME-Horizontal.cfg"' $configdir/neogeo/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/neogeo/retroarch.cfg
  fi
  ;;
nes)
  ifexist=`cat $configdir/nes/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/nes/retroarch.cfg $configdir/nes/retroarch.cfg.bkp
    cat $configdir/nes/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport |grep -v force_aspect > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/nes/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Entertainment-System.cfg"' $configdir/nes/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/nes/retroarch.cfg
    sed -i '4i aspect_ratio_index = "16"' $configdir/nes/retroarch.cfg
    sed -i '5i video_force_aspect = "true"' $configdir/nes/retroarch.cfg
    sed -i '6i video_aspect_ratio = "-1.000000"' $configdir/nes/retroarch.cfg
  else
    cp $configdir/nes/retroarch.cfg $configdir/nes/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Entertainment-System.cfg"' $configdir/nes/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/nes/retroarch.cfg
    sed -i '4i aspect_ratio_index = "16"' $configdir/nes/retroarch.cfg
    sed -i '5i video_force_aspect = "true"' $configdir/nes/retroarch.cfg
    sed -i '6i video_aspect_ratio = "-1.000000"' $configdir/nes/retroarch.cfg
  fi
  ;;
pce-cd)
  ifexist=`cat $configdir/pce-cd/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/pce-cd/retroarch.cfg $configdir/pce-cd/retroarch.cfg.bkp
    cat $configdir/pce-cd/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/pce-cd/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/NEC-PC-Engine-CD.cfg"' $configdir/pce-cd/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/pce-cd/retroarch.cfg
    ln -s  "$raconfigdir/config/Mednafen PCE Fast" "$raconfigdir/config/Beetle PCE Fast"

  else
    cp $configdir/pce-cd/retroarch.cfg $configdir/pce-cd/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/NEC-PC-Engine-CD.cfg"' $configdir/pce-cd/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/pce-cd/retroarch.cfg
    ln -s  "$raconfigdir/config/Mednafen PCE Fast" "$raconfigdir/config/Beetle PCE Fast"

  fi
  ;;
pcengine)
  ifexist=`cat $configdir/pcengine/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/pcengine/retroarch.cfg $configdir/pcengine/retroarch.cfg.bkp
    cat $configdir/pcengine/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/pcengine/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/NEC-PC-Engine.cfg"' $configdir/pcengine/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/pcengine/retroarch.cfg
    ln -s  "$raconfigdir/config/Mednafen PCE Fast" "$raconfigdir/config/Beetle PCE Fast"

  else
    cp $configdir/pcengine/retroarch.cfg $configdir/pcengine/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/NEC-PC-Engine.cfg"' $configdir/pcengine/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/pcengine/retroarch.cfg
    ln -s  "$raconfigdir/config/Mednafen PCE Fast" "$raconfigdir/config/Beetle PCE Fast"

  fi
  ;;
psx)
  ifexist=`cat $configdir/psx/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/psx/retroarch.cfg $configdir/psx/retroarch.cfg.bkp
    cat $configdir/psx/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/psx/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PlayStation.cfg"' $configdir/psx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/psx/retroarch.cfg
    ln -s $raconfigdir/config/PCSX-ReARMed  $raconfigdir/config/PCSX1
    ln -s $raconfigdir/config/PCSX-ReARMed  $raconfigdir/config/Beetle\ PSX

  else
    cp $configdir/psx/retroarch.cfg $configdir/psx/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PlayStation.cfg"' $configdir/psx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/psx/retroarch.cfg
    ln -s $raconfigdir/config/PCSX-ReARMed  $raconfigdir/config/PCSX1
    ln -s $raconfigdir/config/PCSX-ReARMed  $raconfigdir/config/Beetle\ PSX

  fi
  ;;
sega32x)
  ifexist=`cat $configdir/sega32x/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/sega32x/retroarch.cfg $configdir/sega32x/retroarch.cfg.bkp
    cat $configdir/sega32x/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/sega32x/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-32X.cfg"' $configdir/sega32x/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/sega32x/retroarch.cfg
  else
    cp $configdir/sega32x/retroarch.cfg $configdir/sega32x/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-32X.cfg"' $configdir/sega32x/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/sega32x/retroarch.cfg
  fi
  ;;
segacd)
  ifexist=`cat $configdir/segacd/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/segacd/retroarch.cfg $configdir/segacd/retroarch.cfg.bkp
    cat $configdir/segacd/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/segacd/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-CD.cfg"' $configdir/segacd/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/segacd/retroarch.cfg
  else
    cp $configdir/segacd/retroarch.cfg $configdir/segacd/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-CD.cfg"' $configdir/segacd/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/segacd/retroarch.cfg
  fi
  ;;
sfc)
  ifexist=`cat $configdir/sfc/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/sfc/retroarch.cfg $configdir/sfc/retroarch.cfg.bkp
    cat $configdir/sfc/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/sfc/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Super-Famicom.cfg"' $configdir/sfc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/sfc/retroarch.cfg
  else
    cp $configdir/sfc/retroarch.cfg $configdir/sfc/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Super-Famicom.cfg"' $configdir/sfc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/sfc/retroarch.cfg
  fi
  ;;
sg-1000)
  ifexist=`cat $configdir/sg-1000/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/sg-1000/retroarch.cfg $configdir/sg-1000/retroarch.cfg.bkp
    cat $configdir/sg-1000/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/sg-1000/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-SG-1000.cfg"' $configdir/sg-1000/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/sg-1000/retroarch.cfg
  else
    cp $configdir/sg-1000/retroarch.cfg $configdir/sg-1000/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-SG-1000.cfg"' $configdir/sg-1000/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/sg-1000/retroarch.cfg
  fi
  ;;
snes)
  ifexist=`cat $configdir/snes/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/snes/retroarch.cfg $configdir/snes/retroarch.cfg.bkp
    cat $configdir/snes/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/snes/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Super-Nintendo-Entertainment-System.cfg"' $configdir/snes/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/snes/retroarch.cfg
    ln -s $raconfigdir/config/Snes9x $raconfigdir/config/bsnes

  else
    cp $configdir/snes/retroarch.cfg $configdir/snes/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Super-Nintendo-Entertainment-System.cfg"' $configdir/snes/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/snes/retroarch.cfg
    ln -s $raconfigdir/config/Snes9x $raconfigdir/config/bsnes

  fi
  ;;
supergrafx)
  ifexist=`cat $configdir/supergrafx/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/supergrafx/retroarch.cfg $configdir/supergrafx/retroarch.cfg.bkp
    cat $configdir/supergrafx/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/supergrafx/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/NEC-SuperGrafx.cfg"' $configdir/supergrafx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/supergrafx/retroarch.cfg
  else
    cp $configdir/supergrafx/retroarch.cfg $configdir/supergrafx/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/NEC-SuperGrafx.cfg"' $configdir/supergrafx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/supergrafx/retroarch.cfg
  fi
  ;;
tg16)
  ifexist=`cat $configdir/tg16/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/tg16/retroarch.cfg $configdir/tg16/retroarch.cfg.bkp
    cat $configdir/tg16/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/tg16/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/NEC-TurboGrafx-16.cfg"' $configdir/tg16/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/tg16/retroarch.cfg
  else
    cp $configdir/tg16/retroarch.cfg $configdir/tg16/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/NEC-TurboGrafx-16.cfg"' $configdir/tg16/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/tg16/retroarch.cfg
  fi
  ;;
tg-cd)
  ifexist=`cat $configdir/tg-cd/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/tg-cd/retroarch.cfg $configdir/tg-cd/retroarch.cfg.bkp
    cat $configdir/tg-cd/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/tg-cd/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/NEC-TurboGrafx-CD.cfg"' $configdir/tg-cd/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/tg-cd/retroarch.cfg
  else
    cp $configdir/tg-cd/retroarch.cfg $configdir/tg-cd/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/NEC-TurboGrafx-CD.cfg"' $configdir/tg-cd/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/tg-cd/retroarch.cfg
  fi
  ;;
gcevectrex)
  ifexist=`cat $configdir/vectrex/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/vectrex/retroarch.cfg $configdir/vectrex/retroarch.cfg.bkp
    cat $configdir/vectrex/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/vectrex/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/GCE-Vectrex.cfg"' $configdir/vectrex/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/vectrex/retroarch.cfg
  else
    cp $configdir/vectrex/retroarch.cfg $configdir/vectrex/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/GCE-Vectrex.cfg"' $configdir/vectrex/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/vectrex/retroarch.cfg
  fi
  ;;
atarilynx_1080)
  ifexist=`cat $configdir/atarilynx/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/atarilynx/retroarch.cfg $configdir/atarilynx/retroarch.cfg.bkp
    cat $configdir/atarilynx/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/atarilynx/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-Lynx-Horizontal.cfg"' $configdir/atarilynx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atarilynx/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/atarilynx/retroarch.cfg
    sed -i '5i custom_viewport_width = "1010"' $configdir/atarilynx/retroarch.cfg
    sed -i '6i custom_viewport_height = "640"' $configdir/atarilynx/retroarch.cfg
    sed -i '7i custom_viewport_x = "455"' $configdir/atarilynx/retroarch.cfg
    sed -i '8i custom_viewport_y = "225"' $configdir/atarilynx/retroarch.cfg
  else
    cp $configdir/atarilynx/retroarch.cfg $configdir/atarilynx/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-Lynx-Horizontal.cfg"' $configdir/atarilynx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atarilynx/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/atarilynx/retroarch.cfg
    sed -i '5i custom_viewport_width = "1010"' $configdir/atarilynx/retroarch.cfg
    sed -i '6i custom_viewport_height = "640"' $configdir/atarilynx/retroarch.cfg
    sed -i '7i custom_viewport_x = "455"' $configdir/atarilynx/retroarch.cfg
    sed -i '8i custom_viewport_y = "225"' $configdir/atarilynx/retroarch.cfg
  fi
  ;;
atarilynx_720)
  ifexist=`cat $configdir/atarilynx/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/atarilynx/retroarch.cfg $configdir/atarilynx/retroarch.cfg.bkp
    cat $configdir/atarilynx/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/atarilynx/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-Lynx-Horizontal.cfg"' $configdir/atarilynx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atarilynx/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/atarilynx/retroarch.cfg
    sed -i '5i custom_viewport_width = "670"' $configdir/atarilynx/retroarch.cfg
    sed -i '6i custom_viewport_height = "425"' $configdir/atarilynx/retroarch.cfg
    sed -i '7i custom_viewport_x = "305"' $configdir/atarilynx/retroarch.cfg
    sed -i '8i custom_viewport_y = "150"' $configdir/atarilynx/retroarch.cfg
  else
    cp $configdir/atarilynx/retroarch.cfg $configdir/atarilynx/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-Lynx-Horizontal.cfg"' $configdir/atarilynx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atarilynx/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/atarilynx/retroarch.cfg
    sed -i '5i custom_viewport_width = "670"' $configdir/atarilynx/retroarch.cfg
    sed -i '6i custom_viewport_height = "425"' $configdir/atarilynx/retroarch.cfg
    sed -i '7i custom_viewport_x = "305"' $configdir/atarilynx/retroarch.cfg
    sed -i '8i custom_viewport_y = "150"' $configdir/atarilynx/retroarch.cfg
  fi
  ;;
atarilynx_other)
  ifexist=`cat $configdir/atarilynx/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/atarilynx/retroarch.cfg $configdir/atarilynx/retroarch.cfg.bkp
    cat $configdir/atarilynx/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/atarilynx/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-Lynx-Horizontal.cfg"' $configdir/atarilynx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atarilynx/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/atarilynx/retroarch.cfg
    sed -i '5i custom_viewport_width = "715"' $configdir/atarilynx/retroarch.cfg
    sed -i '6i custom_viewport_height = "460"' $configdir/atarilynx/retroarch.cfg
    sed -i '7i custom_viewport_x = "325"' $configdir/atarilynx/retroarch.cfg
    sed -i '8i custom_viewport_y = "160"' $configdir/atarilynx/retroarch.cfg
  else
    cp $configdir/atarilynx/retroarch.cfg $configdir/atarilynx/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-Lynx-Horizontal.cfg"' $configdir/atarilynx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atarilynx/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/atarilynx/retroarch.cfg
    sed -i '5i custom_viewport_width = "715"' $configdir/atarilynx/retroarch.cfg
    sed -i '6i custom_viewport_height = "460"' $configdir/atarilynx/retroarch.cfg
    sed -i '7i custom_viewport_x = "325"' $configdir/atarilynx/retroarch.cfg
    sed -i '8i custom_viewport_y = "160"' $configdir/atarilynx/retroarch.cfg
  fi
  ;;
gamegear_1080)
  ifexist=`cat $configdir/gamegear/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gamegear/retroarch.cfg $configdir/gamegear/retroarch.cfg.bkp
    cat $configdir/gamegear/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gamegear/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Game-Gear.cfg"' $configdir/gamegear/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gamegear/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gamegear/retroarch.cfg
    sed -i '5i custom_viewport_width = "1160"' $configdir/gamegear/retroarch.cfg
    sed -i '6i custom_viewport_height = "850"' $configdir/gamegear/retroarch.cfg
    sed -i '7i custom_viewport_x = "380"' $configdir/gamegear/retroarch.cfg
    sed -i '8i custom_viewport_y = "120"' $configdir/gamegear/retroarch.cfg
  else
    cp $configdir/gamegear/retroarch.cfg $configdir/gamegear/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Game-Gear.cfg"' $configdir/gamegear/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gamegear/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gamegear/retroarch.cfg
    sed -i '5i custom_viewport_width = "1160"' $configdir/gamegear/retroarch.cfg
    sed -i '6i custom_viewport_height = "850"' $configdir/gamegear/retroarch.cfg
    sed -i '7i custom_viewport_x = "380"' $configdir/gamegear/retroarch.cfg
    sed -i '8i custom_viewport_y = "120"' $configdir/gamegear/retroarch.cfg
  fi
  ;;
gamegear_720)
  ifexist=`cat $configdir/gamegear/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gamegear/retroarch.cfg $configdir/gamegear/retroarch.cfg.bkp
    cat $configdir/gamegear/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gamegear/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Game-Gear.cfg"' $configdir/gamegear/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gamegear/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gamegear/retroarch.cfg
    sed -i '5i custom_viewport_width = "780"' $configdir/gamegear/retroarch.cfg
    sed -i '6i custom_viewport_height = "580"' $configdir/gamegear/retroarch.cfg
    sed -i '7i custom_viewport_x = "245"' $configdir/gamegear/retroarch.cfg
    sed -i '8i custom_viewport_y = "70"' $configdir/gamegear/retroarch.cfg
  else
    cp $configdir/gamegear/retroarch.cfg $configdir/gamegear/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Game-Gear.cfg"' $configdir/gamegear/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gamegear/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gamegear/retroarch.cfg
    sed -i '5i custom_viewport_width = "780"' $configdir/gamegear/retroarch.cfg
    sed -i '6i custom_viewport_height = "580"' $configdir/gamegear/retroarch.cfg
    sed -i '7i custom_viewport_x = "245"' $configdir/gamegear/retroarch.cfg
    sed -i '8i custom_viewport_y = "70"' $configdir/gamegear/retroarch.cfg
  fi
  ;;
gamegear_other)
  ifexist=`cat $configdir/gamegear/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gamegear/retroarch.cfg $configdir/gamegear/retroarch.cfg.bkp
    cat $configdir/gamegear/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gamegear/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Game-Gear.cfg"' $configdir/gamegear/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gamegear/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gamegear/retroarch.cfg
    sed -i '5i custom_viewport_width = "835"' $configdir/gamegear/retroarch.cfg
    sed -i '6i custom_viewport_height = "625"' $configdir/gamegear/retroarch.cfg
    sed -i '7i custom_viewport_x = "270"' $configdir/gamegear/retroarch.cfg
    sed -i '8i custom_viewport_y = "75"' $configdir/gamegear/retroarch.cfg
  else
    cp $configdir/gamegear/retroarch.cfg $configdir/gamegear/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sega-Game-Gear.cfg"' $configdir/gamegear/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gamegear/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gamegear/retroarch.cfg
    sed -i '5i custom_viewport_width = "835"' $configdir/gamegear/retroarch.cfg
    sed -i '6i custom_viewport_height = "625"' $configdir/gamegear/retroarch.cfg
    sed -i '7i custom_viewport_x = "270"' $configdir/gamegear/retroarch.cfg
    sed -i '8i custom_viewport_y = "75"' $configdir/gamegear/retroarch.cfg
  fi
  ;;
gb_1080)
  ifexist=`cat $configdir/gb/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gb/retroarch.cfg $configdir/gb/retroarch.cfg.bkp
    cat $configdir/gb/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gb/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy.cfg"' $configdir/gb/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gb/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gb/retroarch.cfg
    sed -i '5i custom_viewport_width = "625"' $configdir/gb/retroarch.cfg
    sed -i '6i custom_viewport_height = "565"' $configdir/gb/retroarch.cfg
    sed -i '7i custom_viewport_x = "645"' $configdir/gb/retroarch.cfg
    sed -i '8i custom_viewport_y = "235"' $configdir/gb/retroarch.cfg
  else
    cp $configdir/gb/retroarch.cfg $configdir/gb/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy.cfg"' $configdir/gb/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gb/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gb/retroarch.cfg
    sed -i '5i custom_viewport_width = "625"' $configdir/gb/retroarch.cfg
    sed -i '6i custom_viewport_height = "565"' $configdir/gb/retroarch.cfg
    sed -i '7i custom_viewport_x = "645"' $configdir/gb/retroarch.cfg
    sed -i '8i custom_viewport_y = "235"' $configdir/gb/retroarch.cfg
  fi
  ;;
gb_720)
  ifexist=`cat $configdir/gb/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gb/retroarch.cfg $configdir/gb/retroarch.cfg.bkp
    cat $configdir/gb/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gb/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy.cfg"' $configdir/gb/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gb/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gb/retroarch.cfg
    sed -i '5i custom_viewport_width = "429"' $configdir/gb/retroarch.cfg
    sed -i '6i custom_viewport_height = "380"' $configdir/gb/retroarch.cfg
    sed -i '7i custom_viewport_x = "420"' $configdir/gb/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/gb/retroarch.cfg
  else
    cp $configdir/gb/retroarch.cfg $configdir/gb/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy.cfg"' $configdir/gb/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gb/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gb/retroarch.cfg
    sed -i '5i custom_viewport_width = "429"' $configdir/gb/retroarch.cfg
    sed -i '6i custom_viewport_height = "380"' $configdir/gb/retroarch.cfg
    sed -i '7i custom_viewport_x = "420"' $configdir/gb/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/gb/retroarch.cfg
  fi
  ;;
gb_other)
  ifexist=`cat $configdir/gb/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gb/retroarch.cfg $configdir/gb/retroarch.cfg.bkp
    cat $configdir/gb/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gb/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy.cfg"' $configdir/gb/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gb/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gb/retroarch.cfg
    sed -i '5i custom_viewport_width = "455"' $configdir/gb/retroarch.cfg
    sed -i '6i custom_viewport_height = "415"' $configdir/gb/retroarch.cfg
    sed -i '7i custom_viewport_x = "455"' $configdir/gb/retroarch.cfg
    sed -i '8i custom_viewport_y = "162"' $configdir/gb/retroarch.cfg
  else
    cp $configdir/gb/retroarch.cfg $configdir/gb/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy.cfg"' $configdir/gb/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gb/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gb/retroarch.cfg
    sed -i '5i custom_viewport_width = "455"' $configdir/gb/retroarch.cfg
    sed -i '6i custom_viewport_height = "415"' $configdir/gb/retroarch.cfg
    sed -i '7i custom_viewport_x = "455"' $configdir/gb/retroarch.cfg
    sed -i '8i custom_viewport_y = "162"' $configdir/gb/retroarch.cfg
  fi
  ;;
gba_1080)
  ifexist=`cat $configdir/gba/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gba/retroarch.cfg $configdir/gba/retroarch.cfg.bkp
    cat $configdir/gba/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gba/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Advance.cfg"' $configdir/gba/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gba/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gba/retroarch.cfg
    sed -i '5i custom_viewport_width = "1005"' $configdir/gba/retroarch.cfg
    sed -i '6i custom_viewport_height = "645"' $configdir/gba/retroarch.cfg
    sed -i '7i custom_viewport_x = "455"' $configdir/gba/retroarch.cfg
    sed -i '8i custom_viewport_y = "215"' $configdir/gba/retroarch.cfg
  else
    cp $configdir/gba/retroarch.cfg $configdir/gba/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Advance.cfg"' $configdir/gba/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gba/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gba/retroarch.cfg
    sed -i '5i custom_viewport_width = "1005"' $configdir/gba/retroarch.cfg
    sed -i '6i custom_viewport_height = "645"' $configdir/gba/retroarch.cfg
    sed -i '7i custom_viewport_x = "455"' $configdir/gba/retroarch.cfg
    sed -i '8i custom_viewport_y = "215"' $configdir/gba/retroarch.cfg
  fi
  ;;
gba_720)
  ifexist=`cat $configdir/gba/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gba/retroarch.cfg $configdir/gba/retroarch.cfg.bkp
    cat $configdir/gba/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gba/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Advance.cfg"' $configdir/gba/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gba/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gba/retroarch.cfg
    sed -i '5i custom_viewport_width = "467"' $configdir/gba/retroarch.cfg
    sed -i '6i custom_viewport_height = "316"' $configdir/gba/retroarch.cfg
    sed -i '7i custom_viewport_x = "405"' $configdir/gba/retroarch.cfg
    sed -i '8i custom_viewport_y = "190"' $configdir/gba/retroarch.cfg
  else
    cp $configdir/gba/retroarch.cfg $configdir/gba/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Advance.cfg"' $configdir/gba/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gba/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gba/retroarch.cfg
    sed -i '5i custom_viewport_width = "467"' $configdir/gba/retroarch.cfg
    sed -i '6i custom_viewport_height = "316"' $configdir/gba/retroarch.cfg
    sed -i '7i custom_viewport_x = "405"' $configdir/gba/retroarch.cfg
    sed -i '8i custom_viewport_y = "190"' $configdir/gba/retroarch.cfg
  fi
  ;;
gba_other)
  ifexist=`cat $configdir/gba/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gba/retroarch.cfg $configdir/gba/retroarch.cfg.bkp
    cat $configdir/gba/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gba/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Advance.cfg"' $configdir/gba/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gba/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gba/retroarch.cfg
    sed -i '5i custom_viewport_width = "720"' $configdir/gba/retroarch.cfg
    sed -i '6i custom_viewport_height = "455"' $configdir/gba/retroarch.cfg
    sed -i '7i custom_viewport_x = "320"' $configdir/gba/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/gba/retroarch.cfg
  else
    cp $configdir/gba/retroarch.cfg $configdir/gba/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Advance.cfg"' $configdir/gba/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gba/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gba/retroarch.cfg
    sed -i '5i custom_viewport_width = "720"' $configdir/gba/retroarch.cfg
    sed -i '6i custom_viewport_height = "455"' $configdir/gba/retroarch.cfg
    sed -i '7i custom_viewport_x = "320"' $configdir/gba/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/gba/retroarch.cfg
  fi
  ;;
gbc_1080)
  ifexist=`cat $configdir/gbc/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gbc/retroarch.cfg $configdir/gbc/retroarch.cfg.bkp
    cat $configdir/gbc/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gbc/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Color.cfg"' $configdir/gbc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gbc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gbc/retroarch.cfg
    sed -i '5i custom_viewport_width = "625"' $configdir/gbc/retroarch.cfg
    sed -i '6i custom_viewport_height = "565"' $configdir/gbc/retroarch.cfg
    sed -i '7i custom_viewport_x = "645"' $configdir/gbc/retroarch.cfg
    sed -i '8i custom_viewport_y = "235"' $configdir/gbc/retroarch.cfg
  else
    cp $configdir/gbc/retroarch.cfg $configdir/gbc/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Color.cfg"' $configdir/gbc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gbc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gbc/retroarch.cfg
    sed -i '5i custom_viewport_width = "625"' $configdir/gbc/retroarch.cfg
    sed -i '6i custom_viewport_height = "565"' $configdir/gbc/retroarch.cfg
    sed -i '7i custom_viewport_x = "645"' $configdir/gbc/retroarch.cfg
    sed -i '8i custom_viewport_y = "235"' $configdir/gbc/retroarch.cfg
  fi
  ;;
gbc_720)
  ifexist=`cat $configdir/gbc/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gbc/retroarch.cfg $configdir/gbc/retroarch.cfg.bkp
    cat $configdir/gbc/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gbc/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Color.cfg"' $configdir/gbc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gbc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gbc/retroarch.cfg
    sed -i '5i custom_viewport_width = "430"' $configdir/gbc/retroarch.cfg
    sed -i '6i custom_viewport_height = "380"' $configdir/gbc/retroarch.cfg
    sed -i '7i custom_viewport_x = "425"' $configdir/gbc/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/gbc/retroarch.cfg
  else
    cp $configdir/gbc/retroarch.cfg $configdir/gbc/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Color.cfg"' $configdir/gbc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gbc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gbc/retroarch.cfg
    sed -i '5i custom_viewport_width = "430"' $configdir/gbc/retroarch.cfg
    sed -i '6i custom_viewport_height = "380"' $configdir/gbc/retroarch.cfg
    sed -i '7i custom_viewport_x = "425"' $configdir/gbc/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/gbc/retroarch.cfg
  fi
  ;;
gbc_other)
  ifexist=`cat $configdir/gbc/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/gbc/retroarch.cfg $configdir/gbc/retroarch.cfg.bkp
    cat $configdir/gbc/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/gbc/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Color.cfg"' $configdir/gbc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gbc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gbc/retroarch.cfg
    sed -i '5i custom_viewport_width = "455"' $configdir/gbc/retroarch.cfg
    sed -i '6i custom_viewport_height = "405"' $configdir/gbc/retroarch.cfg
    sed -i '7i custom_viewport_x = "455"' $configdir/gbc/retroarch.cfg
    sed -i '8i custom_viewport_y = "165"' $configdir/gbc/retroarch.cfg
  else
    cp $configdir/gbc/retroarch.cfg $configdir/gbc/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Game-Boy-Color.cfg"' $configdir/gbc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/gbc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/gbc/retroarch.cfg
    sed -i '5i custom_viewport_width = "455"' $configdir/gbc/retroarch.cfg
    sed -i '6i custom_viewport_height = "405"' $configdir/gbc/retroarch.cfg
    sed -i '7i custom_viewport_x = "455"' $configdir/gbc/retroarch.cfg
    sed -i '8i custom_viewport_y = "165"' $configdir/gbc/retroarch.cfg
  fi
  ;;
ngp_1080)
  ifexist=`cat $configdir/ngp/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/ngp/retroarch.cfg $configdir/ngp/retroarch.cfg.bkp
    cat $configdir/ngp/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/ngp/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket.cfg"' $configdir/ngp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngp/retroarch.cfg
    sed -i '5i custom_viewport_width = "700"' $configdir/ngp/retroarch.cfg
    sed -i '6i custom_viewport_height = "635"' $configdir/ngp/retroarch.cfg
    sed -i '7i custom_viewport_x = "610"' $configdir/ngp/retroarch.cfg
    sed -i '8i custom_viewport_y = "220"' $configdir/ngp/retroarch.cfg
  else
    cp $configdir/ngp/retroarch.cfg $configdir/ngp/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket.cfg"' $configdir/ngp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngp/retroarch.cfg
    sed -i '5i custom_viewport_width = "700"' $configdir/ngp/retroarch.cfg
    sed -i '6i custom_viewport_height = "635"' $configdir/ngp/retroarch.cfg
    sed -i '7i custom_viewport_x = "610"' $configdir/ngp/retroarch.cfg
    sed -i '8i custom_viewport_y = "220"' $configdir/ngp/retroarch.cfg
  fi
  ;;
ngp_720)
  ifexist=`cat $configdir/ngp/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/ngp/retroarch.cfg $configdir/ngp/retroarch.cfg.bkp
    cat $configdir/ngp/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/ngp/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket.cfg"' $configdir/ngp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngp/retroarch.cfg
    sed -i '5i custom_viewport_width = "461"' $configdir/ngp/retroarch.cfg
    sed -i '6i custom_viewport_height = "428"' $configdir/ngp/retroarch.cfg
    sed -i '7i custom_viewport_x = "407"' $configdir/ngp/retroarch.cfg
    sed -i '8i custom_viewport_y = "145"' $configdir/ngp/retroarch.cfg
  else
    cp $configdir/ngp/retroarch.cfg $configdir/ngp/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket.cfg"' $configdir/ngp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngp/retroarch.cfg
    sed -i '5i custom_viewport_width = "461"' $configdir/ngp/retroarch.cfg
    sed -i '6i custom_viewport_height = "428"' $configdir/ngp/retroarch.cfg
    sed -i '7i custom_viewport_x = "407"' $configdir/ngp/retroarch.cfg
    sed -i '8i custom_viewport_y = "145"' $configdir/ngp/retroarch.cfg
  fi
  ;;
ngp_other)
  ifexist=`cat $configdir/ngp/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/ngp/retroarch.cfg $configdir/ngp/retroarch.cfg.bkp
    cat $configdir/ngp/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/ngp/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket.cfg"' $configdir/ngp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngp/retroarch.cfg
    sed -i '5i custom_viewport_width = "490"' $configdir/ngp/retroarch.cfg
    sed -i '6i custom_viewport_height = "455"' $configdir/ngp/retroarch.cfg
    sed -i '7i custom_viewport_x = "435"' $configdir/ngp/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/ngp/retroarch.cfg
  else
    cp $configdir/ngp/retroarch.cfg $configdir/ngp/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket.cfg"' $configdir/ngp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngp/retroarch.cfg
    sed -i '5i custom_viewport_width = "490"' $configdir/ngp/retroarch.cfg
    sed -i '6i custom_viewport_height = "455"' $configdir/ngp/retroarch.cfg
    sed -i '7i custom_viewport_x = "435"' $configdir/ngp/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/ngp/retroarch.cfg
  fi
  ;;
ngpc_1080)
  ifexist=`cat $configdir/ngpc/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/ngpc/retroarch.cfg $configdir/ngpc/retroarch.cfg.bkp
    cat $configdir/ngpc/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/ngpc/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket-Color.cfg"' $configdir/ngpc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngpc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngpc/retroarch.cfg
    sed -i '5i custom_viewport_width = "700"' $configdir/ngpc/retroarch.cfg
    sed -i '6i custom_viewport_height = "640"' $configdir/ngpc/retroarch.cfg
    sed -i '7i custom_viewport_x = "610"' $configdir/ngpc/retroarch.cfg
    sed -i '8i custom_viewport_y = "215"' $configdir/ngpc/retroarch.cfg
  else
    cp $configdir/ngpc/retroarch.cfg $configdir/ngpc/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket-Color.cfg"' $configdir/ngpc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngpc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngpc/retroarch.cfg
    sed -i '5i custom_viewport_width = "700"' $configdir/ngpc/retroarch.cfg
    sed -i '6i custom_viewport_height = "640"' $configdir/ngpc/retroarch.cfg
    sed -i '7i custom_viewport_x = "610"' $configdir/ngpc/retroarch.cfg
    sed -i '8i custom_viewport_y = "215"' $configdir/ngpc/retroarch.cfg
  fi
  ;;
ngpc_720)
  ifexist=`cat $configdir/ngpc/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/ngpc/retroarch.cfg $configdir/ngpc/retroarch.cfg.bkp
    cat $configdir/ngpc/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/ngpc/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket-Color.cfg"' $configdir/ngpc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngpc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngpc/retroarch.cfg
    sed -i '5i custom_viewport_width = "460"' $configdir/ngpc/retroarch.cfg
    sed -i '6i custom_viewport_height = "428"' $configdir/ngpc/retroarch.cfg
    sed -i '7i custom_viewport_x = "407"' $configdir/ngpc/retroarch.cfg
    sed -i '8i custom_viewport_y = "145"' $configdir/ngpc/retroarch.cfg
  else
    cp $configdir/ngpc/retroarch.cfg $configdir/ngpc/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket-Color.cfg"' $configdir/ngpc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngpc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngpc/retroarch.cfg
    sed -i '5i custom_viewport_width = "460"' $configdir/ngpc/retroarch.cfg
    sed -i '6i custom_viewport_height = "428"' $configdir/ngpc/retroarch.cfg
    sed -i '7i custom_viewport_x = "407"' $configdir/ngpc/retroarch.cfg
    sed -i '8i custom_viewport_y = "145"' $configdir/ngpc/retroarch.cfg
  fi
  ;;
ngpc_other)
  ifexist=`cat $configdir/ngpc/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/ngpc/retroarch.cfg $configdir/ngpc/retroarch.cfg.bkp
    cat $configdir/ngpc/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/ngpc/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket-Color.cfg"' $configdir/ngpc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngpc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngpc/retroarch.cfg
    sed -i '5i custom_viewport_width = "490"' $configdir/ngpc/retroarch.cfg
    sed -i '6i custom_viewport_height = "455"' $configdir/ngpc/retroarch.cfg
    sed -i '7i custom_viewport_x = "435"' $configdir/ngpc/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/ngpc/retroarch.cfg
  else
    cp $configdir/ngpc/retroarch.cfg $configdir/ngpc/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/SNK-Neo-Geo-Pocket-Color.cfg"' $configdir/ngpc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/ngpc/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/ngpc/retroarch.cfg
    sed -i '5i custom_viewport_width = "490"' $configdir/ngpc/retroarch.cfg
    sed -i '6i custom_viewport_height = "455"' $configdir/ngpc/retroarch.cfg
    sed -i '7i custom_viewport_x = "435"' $configdir/ngpc/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/ngpc/retroarch.cfg
  fi
  ;;
psp_1080)
  ifexist=`cat $configdir/psp/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/psp/retroarch.cfg $configdir/psp/retroarch.cfg.bkp
    cat $configdir/psp/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/psp/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/psp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/psp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/psp/retroarch.cfg
    sed -i '5i custom_viewport_width = "1430"' $configdir/psp/retroarch.cfg
    sed -i '6i custom_viewport_height = "820"' $configdir/psp/retroarch.cfg
    sed -i '7i custom_viewport_x = "250"' $configdir/psp/retroarch.cfg
    sed -i '8i custom_viewport_y = "135"' $configdir/psp/retroarch.cfg
  else
    cp $configdir/psp/retroarch.cfg $configdir/psp/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/psp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/psp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/psp/retroarch.cfg
    sed -i '5i custom_viewport_width = "1430"' $configdir/psp/retroarch.cfg
    sed -i '6i custom_viewport_height = "820"' $configdir/psp/retroarch.cfg
    sed -i '7i custom_viewport_x = "250"' $configdir/psp/retroarch.cfg
    sed -i '8i custom_viewport_y = "135"' $configdir/psp/retroarch.cfg
  fi
  ;;
psp_720)
  ifexist=`cat $configdir/psp/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/psp/retroarch.cfg $configdir/psp/retroarch.cfg.bkp
    cat $configdir/psp/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/psp/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/psp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/psp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/psp/retroarch.cfg
    sed -i '5i custom_viewport_width = "950"' $configdir/psp/retroarch.cfg
    sed -i '6i custom_viewport_height = "540"' $configdir/psp/retroarch.cfg
    sed -i '7i custom_viewport_x = "165"' $configdir/psp/retroarch.cfg
    sed -i '8i custom_viewport_y = "90"' $configdir/psp/retroarch.cfg
  else
    cp $configdir/psp/retroarch.cfg $configdir/psp/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/psp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/psp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/psp/retroarch.cfg
    sed -i '5i custom_viewport_width = "950"' $configdir/psp/retroarch.cfg
    sed -i '6i custom_viewport_height = "540"' $configdir/psp/retroarch.cfg
    sed -i '7i custom_viewport_x = "165"' $configdir/psp/retroarch.cfg
    sed -i '8i custom_viewport_y = "90"' $configdir/psp/retroarch.cfg
  fi
  ;;
psp_other)
  ifexist=`cat $configdir/psp/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/psp/retroarch.cfg $configdir/psp/retroarch.cfg.bkp
    cat $configdir/psp/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/psp/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/psp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/psp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/psp/retroarch.cfg
    sed -i '5i custom_viewport_width = "1015"' $configdir/psp/retroarch.cfg
    sed -i '6i custom_viewport_height = "575"' $configdir/psp/retroarch.cfg
    sed -i '7i custom_viewport_x = "175"' $configdir/psp/retroarch.cfg
    sed -i '8i custom_viewport_y = "95"' $configdir/psp/retroarch.cfg
  else
    cp $configdir/psp/retroarch.cfg $configdir/psp/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/psp/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/psp/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/psp/retroarch.cfg
    sed -i '5i custom_viewport_width = "1015"' $configdir/psp/retroarch.cfg
    sed -i '6i custom_viewport_height = "575"' $configdir/psp/retroarch.cfg
    sed -i '7i custom_viewport_x = "175"' $configdir/psp/retroarch.cfg
    sed -i '8i custom_viewport_y = "95"' $configdir/psp/retroarch.cfg
  fi
  ;;
pspminis_1080)
  ifexist=`cat $configdir/pspminis/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/pspminis/retroarch.cfg $configdir/pspminis/retroarch.cfg.bkp
    cat $configdir/pspminis/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/pspminis/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/pspminis/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/pspminis/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/pspminis/retroarch.cfg
    sed -i '5i custom_viewport_width = "1430"' $configdir/pspminis/retroarch.cfg
    sed -i '6i custom_viewport_height = "820"' $configdir/pspminis/retroarch.cfg
    sed -i '7i custom_viewport_x = "250"' $configdir/pspminis/retroarch.cfg
    sed -i '8i custom_viewport_y = "135"' $configdir/pspminis/retroarch.cfg
  else
    cp $configdir/pspminis/retroarch.cfg $configdir/pspminis/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/pspminis/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/pspminis/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/pspminis/retroarch.cfg
    sed -i '5i custom_viewport_width = "1430"' $configdir/pspminis/retroarch.cfg
    sed -i '6i custom_viewport_height = "820"' $configdir/pspminis/retroarch.cfg
    sed -i '7i custom_viewport_x = "250"' $configdir/pspminis/retroarch.cfg
    sed -i '8i custom_viewport_y = "135"' $configdir/pspminis/retroarch.cfg
  fi
  ;;
pspminis_720)
  ifexist=`cat $configdir/pspminis/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/pspminis/retroarch.cfg $configdir/pspminis/retroarch.cfg.bkp
    cat $configdir/pspminis/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/pspminis/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/pspminis/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/pspminis/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/pspminis/retroarch.cfg
    sed -i '5i custom_viewport_width = "950"' $configdir/pspminis/retroarch.cfg
    sed -i '6i custom_viewport_height = "540"' $configdir/pspminis/retroarch.cfg
    sed -i '7i custom_viewport_x = "165"' $configdir/pspminis/retroarch.cfg
    sed -i '8i custom_viewport_y = "90"' $configdir/pspminis/retroarch.cfg
  else
    cp $configdir/pspminis/retroarch.cfg $configdir/pspminis/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/pspminis/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/pspminis/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/pspminis/retroarch.cfg
    sed -i '5i custom_viewport_width = "950"' $configdir/pspminis/retroarch.cfg
    sed -i '6i custom_viewport_height = "540"' $configdir/pspminis/retroarch.cfg
    sed -i '7i custom_viewport_x = "165"' $configdir/pspminis/retroarch.cfg
    sed -i '8i custom_viewport_y = "90"' $configdir/pspminis/retroarch.cfg
  fi
  ;;
pspminis_other)
  ifexist=`cat $configdir/pspminis/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/pspminis/retroarch.cfg $configdir/pspminis/retroarch.cfg.bkp
    cat $configdir/pspminis/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/pspminis/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/pspminis/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/pspminis/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/pspminis/retroarch.cfg
    sed -i '5i custom_viewport_width = "1015"' $configdir/pspminis/retroarch.cfg
    sed -i '6i custom_viewport_height = "575"' $configdir/pspminis/retroarch.cfg
    sed -i '7i custom_viewport_x = "175"' $configdir/pspminis/retroarch.cfg
    sed -i '8i custom_viewport_y = "95"' $configdir/pspminis/retroarch.cfg
  else
    cp $configdir/pspminis/retroarch.cfg $configdir/pspminis/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sony-PSP.cfg"' $configdir/pspminis/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/pspminis/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/pspminis/retroarch.cfg
    sed -i '5i custom_viewport_width = "1015"' $configdir/pspminis/retroarch.cfg
    sed -i '6i custom_viewport_height = "575"' $configdir/pspminis/retroarch.cfg
    sed -i '7i custom_viewport_x = "175"' $configdir/pspminis/retroarch.cfg
    sed -i '8i custom_viewport_y = "95"' $configdir/pspminis/retroarch.cfg
  fi
  ;;
virtualboy_1080)
  ifexist=`cat $configdir/virtualboy/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/virtualboy/retroarch.cfg $configdir/virtualboy/retroarch.cfg.bkp
    cat $configdir/virtualboy/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/virtualboy/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Virtual-Boy.cfg"' $configdir/virtualboy/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/virtualboy/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/virtualboy/retroarch.cfg
    sed -i '5i custom_viewport_width = "1115"' $configdir/virtualboy/retroarch.cfg
    sed -i '6i custom_viewport_height = "695"' $configdir/virtualboy/retroarch.cfg
    sed -i '7i custom_viewport_x = "405"' $configdir/virtualboy/retroarch.cfg
    sed -i '8i custom_viewport_y = "215"' $configdir/virtualboy/retroarch.cfg
  else
    cp $configdir/virtualboy/retroarch.cfg $configdir/virtualboy/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Virtual-Boy.cfg"' $configdir/virtualboy/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/virtualboy/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/virtualboy/retroarch.cfg
    sed -i '5i custom_viewport_width = "1115"' $configdir/virtualboy/retroarch.cfg
    sed -i '6i custom_viewport_height = "695"' $configdir/virtualboy/retroarch.cfg
    sed -i '7i custom_viewport_x = "405"' $configdir/virtualboy/retroarch.cfg
    sed -i '8i custom_viewport_y = "215"' $configdir/virtualboy/retroarch.cfg
  fi
  ;;
virtualboy_720)
  ifexist=`cat $configdir/virtualboy/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/virtualboy/retroarch.cfg $configdir/virtualboy/retroarch.cfg.bkp
    cat $configdir/virtualboy/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/virtualboy/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Virtual-Boy.cfg"' $configdir/virtualboy/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/virtualboy/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/virtualboy/retroarch.cfg
    sed -i '5i custom_viewport_width = "740"' $configdir/virtualboy/retroarch.cfg
    sed -i '6i custom_viewport_height = "470"' $configdir/virtualboy/retroarch.cfg
    sed -i '7i custom_viewport_x = "270"' $configdir/virtualboy/retroarch.cfg
    sed -i '8i custom_viewport_y = "140"' $configdir/virtualboy/retroarch.cfg
  else
    cp $configdir/virtualboy/retroarch.cfg $configdir/virtualboy/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Virtual-Boy.cfg"' $configdir/virtualboy/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/virtualboy/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/virtualboy/retroarch.cfg
    sed -i '5i custom_viewport_width = "740"' $configdir/virtualboy/retroarch.cfg
    sed -i '6i custom_viewport_height = "470"' $configdir/virtualboy/retroarch.cfg
    sed -i '7i custom_viewport_x = "270"' $configdir/virtualboy/retroarch.cfg
    sed -i '8i custom_viewport_y = "140"' $configdir/virtualboy/retroarch.cfg
  fi
  ;;
virtualboy_other)
  ifexist=`cat $configdir/virtualboy/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/virtualboy/retroarch.cfg $configdir/virtualboy/retroarch.cfg.bkp
    cat $configdir/virtualboy/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/virtualboy/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Virtual-Boy.cfg"' $configdir/virtualboy/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/virtualboy/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/virtualboy/retroarch.cfg
    sed -i '5i custom_viewport_width = "787"' $configdir/virtualboy/retroarch.cfg
    sed -i '6i custom_viewport_height = "494"' $configdir/virtualboy/retroarch.cfg
    sed -i '7i custom_viewport_x = "290"' $configdir/virtualboy/retroarch.cfg
    sed -i '8i custom_viewport_y = "153"' $configdir/virtualboy/retroarch.cfg
  else
    cp $configdir/virtualboy/retroarch.cfg $configdir/virtualboy/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Nintendo-Virtual-Boy.cfg"' $configdir/virtualboy/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/virtualboy/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/virtualboy/retroarch.cfg
    sed -i '5i custom_viewport_width = "787"' $configdir/virtualboy/retroarch.cfg
    sed -i '6i custom_viewport_height = "494"' $configdir/virtualboy/retroarch.cfg
    sed -i '7i custom_viewport_x = "290"' $configdir/virtualboy/retroarch.cfg
    sed -i '8i custom_viewport_y = "153"' $configdir/virtualboy/retroarch.cfg
  fi
  ;;
wonderswan_1080)
  ifexist=`cat $configdir/wonderswan/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/wonderswan/retroarch.cfg $configdir/wonderswan/retroarch.cfg.bkp
    cat $configdir/wonderswan/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/wonderswan/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Horizontal.cfg"' $configdir/wonderswan/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswan/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswan/retroarch.cfg
    sed -i '5i custom_viewport_width = "950"' $configdir/wonderswan/retroarch.cfg
    sed -i '6i custom_viewport_height = "605"' $configdir/wonderswan/retroarch.cfg
    sed -i '7i custom_viewport_x = "495"' $configdir/wonderswan/retroarch.cfg
    sed -i '8i custom_viewport_y = "225"' $configdir/wonderswan/retroarch.cfg
  else
    cp $configdir/wonderswan/retroarch.cfg $configdir/wonderswan/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Horizontal.cfg"' $configdir/wonderswan/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswan/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswan/retroarch.cfg
    sed -i '5i custom_viewport_width = "950"' $configdir/wonderswan/retroarch.cfg
    sed -i '6i custom_viewport_height = "605"' $configdir/wonderswan/retroarch.cfg
    sed -i '7i custom_viewport_x = "495"' $configdir/wonderswan/retroarch.cfg
    sed -i '8i custom_viewport_y = "225"' $configdir/wonderswan/retroarch.cfg
  fi
  ;;
wonderswan_720)
  ifexist=`cat $configdir/wonderswan/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/wonderswan/retroarch.cfg $configdir/wonderswan/retroarch.cfg.bkp
    cat $configdir/wonderswan/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/wonderswan/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Horizontal.cfg"' $configdir/wonderswan/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswan/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswan/retroarch.cfg
    sed -i '5i custom_viewport_width = "645"' $configdir/wonderswan/retroarch.cfg
    sed -i '6i custom_viewport_height = "407"' $configdir/wonderswan/retroarch.cfg
    sed -i '7i custom_viewport_x = "325"' $configdir/wonderswan/retroarch.cfg
    sed -i '8i custom_viewport_y = "148"' $configdir/wonderswan/retroarch.cfg
  else
    cp $configdir/wonderswan/retroarch.cfg $configdir/wonderswan/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Horizontal.cfg"' $configdir/wonderswan/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswan/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswan/retroarch.cfg
    sed -i '5i custom_viewport_width = "645"' $configdir/wonderswan/retroarch.cfg
    sed -i '6i custom_viewport_height = "407"' $configdir/wonderswan/retroarch.cfg
    sed -i '7i custom_viewport_x = "325"' $configdir/wonderswan/retroarch.cfg
    sed -i '8i custom_viewport_y = "148"' $configdir/wonderswan/retroarch.cfg
  fi
  ;;
wonderswan_other)
  ifexist=`cat $configdir/wonderswan/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/wonderswan/retroarch.cfg $configdir/wonderswan/retroarch.cfg.bkp
    cat $configdir/wonderswan/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/wonderswan/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Horizontal.cfg"' $configdir/wonderswan/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswan/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswan/retroarch.cfg
    sed -i '5i custom_viewport_width = "690"' $configdir/wonderswan/retroarch.cfg
    sed -i '6i custom_viewport_height = "435"' $configdir/wonderswan/retroarch.cfg
    sed -i '7i custom_viewport_x = "345"' $configdir/wonderswan/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/wonderswan/retroarch.cfg
  else
    cp $configdir/wonderswan/retroarch.cfg $configdir/wonderswan/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Horizontal.cfg"' $configdir/wonderswan/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswan/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswan/retroarch.cfg
    sed -i '5i custom_viewport_width = "690"' $configdir/wonderswan/retroarch.cfg
    sed -i '6i custom_viewport_height = "435"' $configdir/wonderswan/retroarch.cfg
    sed -i '7i custom_viewport_x = "345"' $configdir/wonderswan/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/wonderswan/retroarch.cfg
  fi
  ;;
wonderswancolor_1080)
  ifexist=`cat $configdir/wonderswancolor/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/wonderswancolor/retroarch.cfg $configdir/wonderswancolor/retroarch.cfg.bkp
    cat $configdir/wonderswancolor/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/wonderswancolor/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Color-Horizontal.cfg"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '5i custom_viewport_width = "950"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '6i custom_viewport_height = "605"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '7i custom_viewport_x = "490"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '8i custom_viewport_y = "225"' $configdir/wonderswancolor/retroarch.cfg
  else
    cp $configdir/wonderswancolor/retroarch.cfg $configdir/wonderswancolor/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Color-Horizontal.cfg"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '5i custom_viewport_width = "950"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '6i custom_viewport_height = "605"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '7i custom_viewport_x = "490"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '8i custom_viewport_y = "225"' $configdir/wonderswancolor/retroarch.cfg
  fi
  ;;
wonderswancolor_720)
  ifexist=`cat $configdir/wonderswancolor/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/wonderswancolor/retroarch.cfg $configdir/wonderswancolor/retroarch.cfg.bkp
    cat $configdir/wonderswancolor/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/wonderswancolor/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Color-Horizontal.cfg"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '5i custom_viewport_width = "643"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '6i custom_viewport_height = "405"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '7i custom_viewport_x = "325"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '8i custom_viewport_y = "150"' $configdir/wonderswancolor/retroarch.cfg
  else
    cp $configdir/wonderswancolor/retroarch.cfg $configdir/wonderswancolor/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Color-Horizontal.cfg"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '5i custom_viewport_width = "643"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '6i custom_viewport_height = "405"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '7i custom_viewport_x = "325"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '8i custom_viewport_y = "150"' $configdir/wonderswancolor/retroarch.cfg
  fi
  ;;
wonderswancolor_other)
  ifexist=`cat $configdir/wonderswancolor/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/wonderswancolor/retroarch.cfg $configdir/wonderswancolor/retroarch.cfg.bkp
    cat $configdir/wonderswancolor/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/wonderswancolor/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Color-Horizontal.cfg"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '5i custom_viewport_width = "690"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '6i custom_viewport_height = "435"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '7i custom_viewport_x = "345"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/wonderswancolor/retroarch.cfg
  else
    cp $configdir/wonderswancolor/retroarch.cfg $configdir/wonderswancolor/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Bandai-WonderSwan-Color-Horizontal.cfg"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '4i aspect_ratio_index = "22"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '5i custom_viewport_width = "690"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '6i custom_viewport_height = "435"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '7i custom_viewport_x = "345"' $configdir/wonderswancolor/retroarch.cfg
    sed -i '8i custom_viewport_y = "155"' $configdir/wonderswancolor/retroarch.cfg
  fi
  ;;
amstradcpc)
  ifexist=`cat $configdir/amstradcpc/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/amstradcpc/retroarch.cfg $configdir/amstradcpc/retroarch.cfg.bkp
    cat $configdir/amstradcpc/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/amstradcpc/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Amstrad-CPC.cfg"' $configdir/amstradcpc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/amstradcpc/retroarch.cfg
  else
    cp $configdir/amstradcpc/retroarch.cfg $configdir/amstradcpc/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Amstrad-CPC.cfg"' $configdir/amstradcpc/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/amstradcpc/retroarch.cfg
  fi
  ;;
atari800)
  ifexist=`cat $configdir/atari800/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/atari800/retroarch.cfg $configdir/atari800/retroarch.cfg.bkp
    cat $configdir/atari800/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/atari800/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-800.cfg"' $configdir/atari800/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atari800/retroarch.cfg
  else
    cp $configdir/atari800/retroarch.cfg $configdir/atari800/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-800.cfg"' $configdir/atari800/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atari800/retroarch.cfg
  fi
  ;;
atarist)
  ifexist=`cat $configdir/atarist/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/atarist/retroarch.cfg $configdir/atarist/retroarch.cfg.bkp
    cat $configdir/atarist/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/atarist/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-ST.cfg"' $configdir/atarist/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atarist/retroarch.cfg
  else
    cp $configdir/atarist/retroarch.cfg $configdir/atarist/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-ST.cfg"' $configdir/atarist/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/atarist/retroarch.cfg
  fi
  ;;
c64)
  ifexist=`cat $configdir/c64/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/c64/retroarch.cfg $configdir/c64/retroarch.cfg.bkp
    cat $configdir/c64/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/c64/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Commodore-64.cfg"' $configdir/c64/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/c64/retroarch.cfg
  else
    cp $configdir/c64/retroarch.cfg $configdir/c64/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Commodore-64.cfg"' $configdir/c64/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/c64/retroarch.cfg
  fi
  ;;
msx)
  ifexist=`cat $configdir/msx/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/msx/retroarch.cfg $configdir/msx/retroarch.cfg.bkp
    cat $configdir/msx/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/msx/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Microsoft-MSX.cfg"' $configdir/msx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/msx/retroarch.cfg
  else
    cp $configdir/msx/retroarch.cfg $configdir/msx/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Microsoft-MSX.cfg"' $configdir/msx/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/msx/retroarch.cfg
  fi
  ;;
msx2)
  ifexist=`cat $configdir/msx2/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/msx2/retroarch.cfg $configdir/msx2/retroarch.cfg.bkp
    cat $configdir/msx2/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/msx2/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Microsoft-MSX2.cfg"' $configdir/msx2/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/msx2/retroarch.cfg
  else
    cp $configdir/msx2/retroarch.cfg $configdir/msx2/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Microsoft-MSX2.cfg"' $configdir/msx2/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/msx2/retroarch.cfg
  fi
  ;;
videopac)
  ifexist=`cat $configdir/videopac/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/videopac/retroarch.cfg $configdir/videopac/retroarch.cfg.bkp
    cat $configdir/videopac/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/videopac/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Magnavox-Odyssey-2.cfg"' $configdir/videopac/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/videopac/retroarch.cfg
  else
    cp $configdir/videopac/retroarch.cfg $configdir/videopac/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Magnavox-Odyssey-2.cfg"' $configdir/videopac/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/videopac/retroarch.cfg
  fi
  ;;
x68000)
  ifexist=`cat $configdir/x68000/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/x68000/retroarch.cfg $configdir/x68000/retroarch.cfg.bkp
    cat $configdir/x68000/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/x68000/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sharp-X68000.cfg"' $configdir/x68000/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/x68000/retroarch.cfg
  else
    cp $configdir/x68000/retroarch.cfg $configdir/x68000/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sharp-X68000.cfg"' $configdir/x68000/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/x68000/retroarch.cfg
  fi
  ;;
zxspectrum)
  ifexist=`cat $configdir/zxspectrum/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/zxspectrum/retroarch.cfg $configdir/zxspectrum/retroarch.cfg.bkp
    cat $configdir/zxspectrum/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/zxspectrum/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sinclair-ZX-Spectrum.cfg"' $configdir/zxspectrum/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/zxspectrum/retroarch.cfg
  else
    cp $configdir/zxspectrum/retroarch.cfg $configdir/zxspectrum/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/Sinclair-ZX-Spectrum.cfg"' $configdir/zxspectrum/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/zxspectrum/retroarch.cfg
  fi
  ;;
supergamemachine)
  ifexist=`cat $configdir/supergamemachine/retroarch.cfg |grep "input_overlay" |wc -l`
  if [[ ${ifexist} > 0 ]]
  then
    cp $configdir/supergamemachine/retroarch.cfg $configdir/supergamemachine/retroarch.cfg.bkp
    cat $configdir/supergamemachine/retroarch.cfg |grep -v input_overlay |grep -v aspect_ratio |grep -v custom_viewport > /tmp/retroarch.cfg
    cp /tmp/retroarch.cfg $configdir/supergamemachine/retroarch.cfg
    sed -i '2i input_overlay = "$raconfigdir/overlay/Atari-2600.cfg"' $configdir/supergamemachine/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/supergamemachine/retroarch.cfg
  else
    cp $configdir/supergamemachine/retroarch.cfg $configdir/supergamemachine/retroarch.cfg.bkp
    sed -i '2i input_overlay = "$raconfigdir/overlay/SuperGameMachine.cfg"' $configdir/supergamemachine/retroarch.cfg
    sed -i '3i input_overlay_opacity = "1.000000"' $configdir/supergamemachine/retroarch.cfg
  fi
  ;;
esac
}

function retroarch_bezelinfo() {

echo "The Bezel Project is setup with the following sytem-to-core mapping." > /tmp/bezelprojectinfo.txt
echo "" >> /tmp/bezelprojectinfo.txt

echo "To show a specific game bezel, Retroarch must have an override config file for each game.  These " >> /tmp/bezelprojectinfo.txt
echo "configuration files are saved in special directories that are named according to the Retroarch " >> /tmp/bezelprojectinfo.txt
echo "emulator core that system uses." >> /tmp/bezelprojectinfo.txt
echo "" >> /tmp/bezelprojectinfo.txt

echo "The supplied Retroarch configuration files for the bezel utility are setup to use certain " >> /tmp/bezelprojectinfo.txt
echo "emulators for certain systems." >> /tmp/bezelprojectinfo.txt
echo "" >> /tmp/bezelprojectinfo.txt

echo "In order for the supplied bezels to be shown, you must be using the proper Retroarch emulator " >> /tmp/bezelprojectinfo.txt
echo "for a system listed in the table below." >> /tmp/bezelprojectinfo.txt
echo "" >> /tmp/bezelprojectinfo.txt

echo "This table lists all of the systems that have the abilty to show bezels that The Bezel Project " >> /tmp/bezelprojectinfo.txt
echo "hopes to make bezels for." >> /tmp/bezelprojectinfo.txt
echo "" >> /tmp/bezelprojectinfo.txt
echo "" >> /tmp/bezelprojectinfo.txt

echo "System                                          Retroarch Emulator" >> /tmp/bezelprojectinfo.txt
echo "Atari 2600                                      lr-stella" >> /tmp/bezelprojectinfo.txt
echo "Atari 5200                                      lr-atari800" >> /tmp/bezelprojectinfo.txt
echo "Atari 7800                                      lr-prosystem" >> /tmp/bezelprojectinfo.txt
echo "ColecoVision                                    lr-bluemsx" >> /tmp/bezelprojectinfo.txt
echo "GCE Vectrex                                     lr-vecx" >> /tmp/bezelprojectinfo.txt
echo "NEC PC Engine CD                                lr-beetle-pce-fast" >> /tmp/bezelprojectinfo.txt
echo "NEC PC Engine                                   lr-beetle-pce-fast" >> /tmp/bezelprojectinfo.txt
echo "NEC SuperGrafx                                  lr-beetle-supergrafx" >> /tmp/bezelprojectinfo.txt
echo "NEC TurboGrafx-CD                               lr-beetle-pce-fast" >> /tmp/bezelprojectinfo.txt
echo "NEC TurboGrafx-16                               lr-beetle-pce-fast" >> /tmp/bezelprojectinfo.txt
echo "Nintendo 64                                     lr-Mupen64plus" >> /tmp/bezelprojectinfo.txt
echo "Nintendo Entertainment System                   lr-fceumm, lr-nestopia" >> /tmp/bezelprojectinfo.txt
echo "Nintendo Famicom Disk System                    lr-fceumm, lr-nestopia" >> /tmp/bezelprojectinfo.txt
echo "Nintendo Famicom                                lr-fceumm, lr-nestopia" >> /tmp/bezelprojectinfo.txt
echo "Nintendo Super Famicom                          lr-snes9x, lr-snes9x2010" >> /tmp/bezelprojectinfo.txt
echo "Sega 32X                                        lr-picodrive, lr-genesis-plus-gx" >> /tmp/bezelprojectinfo.txt
echo "Sega CD                                         lr-picodrive, lr-genesis-plus-gx" >> /tmp/bezelprojectinfo.txt
echo "Sega Genesis                                    lr-picodrive, lr-genesis-plus-gx" >> /tmp/bezelprojectinfo.txt
echo "Sega Master System                              lr-picodrive, lr-genesis-plus-gx" >> /tmp/bezelprojectinfo.txt
echo "Sega Mega Drive                                 lr-picodrive, lr-genesis-plus-gx" >> /tmp/bezelprojectinfo.txt
echo "Sega Mega Drive Japan                           lr-picodrive, lr-genesis-plus-gx" >> /tmp/bezelprojectinfo.txt
echo "Sega SG-1000                                    lr-genesis-plus-gx" >> /tmp/bezelprojectinfo.txt
echo "Sony PlayStation                                lr-pcsx-rearmed" >> /tmp/bezelprojectinfo.txt
echo "Super Nintendo Entertainment System             lr-snes9x, lr-snes9x2010" >> /tmp/bezelprojectinfo.txt
echo "" >> /tmp/bezelprojectinfo.txt

dialog --backtitle "The Bezel Project" \
--title "The Bezel Project - Bezel Pack Utility" \
--textbox /tmp/bezelprojectinfo.txt 30 110
}

# Main

main_menu
