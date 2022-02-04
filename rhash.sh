#!/usr/bin/env bash
set -e

### Colors ##
ESC=$(printf '\033') RESET="${ESC}[0m" BLACK="${ESC}[30m" RED="${ESC}[31m"
GREEN="${ESC}[32m" YELLOW="${ESC}[33m" BLUE="${ESC}[34m" MAGENTA="${ESC}[35m"
CYAN="${ESC}[36m" WHITE="${ESC}[37m" DEFAULT="${ESC}[39m"

greenprint() { printf "${GREEN}%s${RESET}\n" "$1"; }
blueprint() { printf "${BLUE}%s${RESET}\n" "$1"; }
redprint() { printf "${RED}%s${RESET}\n" "$1"; }
yellowprint() { printf "${YELLOW}%s${RESET}\n" "$1"; }
magentaprint() { printf "${MAGENTA}%s${RESET}\n" "$1"; }
cyanprint() { printf "${CYAN}%s${RESET}\n" "$1"; }

time=$(echo -n `date +"%Y%m%d%H%M"`)
# zfs snapshot -r backup/jt@$time
# zfs list -t snapshot
# zpool=$(zpool list -Ho name| awk -F 'zroot' '{print $1}'| tr '\n' ' '| sed 's/ *$//')
# zfs list -t snapshot -Ho name | awk '{print $1}' | xargs zfs destroy
####


zpool=$(zpool list -Ho name| tr '\n' ' '| sed 's/ *$//')

main () {

  how_to(){
    echo "$(yellowprint "[Requires: pkg install rhash, snapshot all dataset in <zpool>]")"
    echo "Usage: rhash.sh $(greenprint "<source zpool>")"
  }

  zpool_menu(){
    echo "Available zpool:"
    eval "arr=($zpool)"
    for i in "${arr[@]}"; do
      echo "$(cyanprint "$i")";
    done
    echo ""
  }

  if [ $# -ne 1 ]; then
    how_to
    zpool_menu
    exit 1
  fi

  eval "arr=($zpool)"
  CHECK=$(zfs list|awk '{print $5}'|grep $1/|wc -l|awk '{print $1}')
  if [[ $CHECK -eq 1 ]]; then
    echo "[$(greenprint "found: $CHECK directory") -- $(yellowprint "zfs snapshot") -- $(magentaprint "rhash file")]"
    zfs_list=$(zfs list | awk '{print $5'} | grep $1/ | tr '\n' ' '| sed 's/ *$//')
    eval "zfs_array=($zfs_list)"

    for i in "${zfs_array[@]}"; do
      dir_path=$(echo "$i"|sed 's/^.//')
      dir_name=$(echo "$i"|rev|cut -d/ -f1|rev)

      echo "$(cyanprint "$i") --> $(yellowprint "zfs snapshot -r $dir_path@$time") --> /usr/bin/time -h rhash -r $i > $(magentaprint "$dir_name.rhash")";
      $(zfs snapshot -r $dir_path@$time)
      #$(/usr/bin/time -h rhash -r $i > $dir_name.rhash)
    done

  elif [[ $CHECK -eq 0 ]]; then
    echo "$(greenprint "<source zpool>") $(cyanprint "$1") ($(redprint "does not have any directories"))"
    echo "#################################"
    how_to
    zpool_menu
  else
    echo "[$(greenprint "found: $CHECK directories") -- $(yellowprint "zfs snapshot") -- $(magentaprint "rhash file")]"
    zfs_list=$(zfs list | awk '{print $5'} | grep $1/ | tr '\n' ' '| sed 's/ *$//')
    eval "zfs_array=($zfs_list)"

    for i in "${zfs_array[@]}"; do
      dir_path=$(echo "$i"|sed 's/^.//')
      dir_name=$(echo "$i"|rev|cut -d/ -f1|rev)

      echo "$(cyanprint "$i") --> $(yellowprint "zfs snapshot -r $dir_path@$time") --> /usr/bin/time -h rhash -r $i > $(magentaprint "$dir_name.rhash")";
      $(zfs snapshot -r $dir_path@$time)
      $(/usr/bin/time -h rhash -r $i > $dir_name.rhash)
    done
  fi

}

main "$@"