#!/usr/bin/env bash
set -e

# zfs list -t snapshot
# zfs destroy <snapshot>
# zfs list -Ht snapshot| grep <zpool>/|awk '{print $1}'|xargs -n 1 zfs destroy -vr

time=$(echo -n `date +"%Y%m%d%H%M"`)

### Colors ##
ESC=$(printf '\033') RESET="${ESC}[0m" BLACK="${ESC}[30m" RED="${ESC}[31m"
GREEN="${ESC}[32m" YELLOW="${ESC}[33m" BLUE="${ESC}[34m" MAGENTA="${ESC}[35m"
CYAN="${ESC}[36m" WHITE="${ESC}[37m" DEFAULT="${ESC}[39m"

### Color Functions ##
greenprint() { printf "${GREEN}%s${RESET}\n" "$1"; }
blueprint() { printf "${BLUE}%s${RESET}\n" "$1"; }
redprint() { printf "${RED}%s${RESET}\n" "$1"; }
yellowprint() { printf "${YELLOW}%s${RESET}\n" "$1"; }
magentaprint() { printf "${MAGENTA}%s${RESET}\n" "$1"; }
cyanprint() { printf "${CYAN}%s${RESET}\n" "$1"; }

zpool=$(zpool list -Ho name| tr '\n' ' '| sed 's/ *$//')
#snapshot=$(zfs list -Ht snapshot | awk '{print $1}' | grep $1/|sed 's/\(.*\)@//'|sort -nru)
snapshot=$(zfs list -Ht snapshot | awk '{print $1}' | sort -Vr)

main () {

  how_to(){
    echo "$(magentaprint "Note: a rhash file will be generated for each dataset in the <source zpool>")"
    echo "Usage: transfer.sh $(greenprint "<source zpool>") $(yellowprint "<destination zpool>") $(cyanprint "<snapshot YYYYMdHM>")"
  }

  zpool_menu(){
    echo "$(magentaprint "Available zpool:")"
    eval "arr=($zpool)"
    for i in "${arr[@]}"; do
      echo "$(cyanprint "$i")";
    done

    echo ""
    echo "$(magentaprint "Available snapshot:") (ascending order)"
    eval "snapshot_arr=($snapshot)"
    for i in "${snapshot_arr[@]}"; do
      echo "$(cyanprint "$i")";
    done

  }
  if [ $# -ne 3 ]; then
    echo "$(redprint "Aborted! transfer.sh requires 3 arguments")"
    how_to
    zpool_menu
    exit 1
  fi

  eval "arr=($zpool)"
  CHECK_SOURCE=$(zfs list -Ht snapshot|awk '{print $1}'|grep $1/|wc -l|awk '{print $1}')
  CHECK_DEST=$(zfs list -H|awk '{print $5}'|grep $2/|wc -l|awk '{print $1}')
  CHECK_SNAPSHOT=$(zfs list -Ht snapshot |awk '{print $1}'| sed 's/\(.*\)@//'|sort -nru| grep $3| wc -l|awk '{print $1}')

  if [[ $CHECK_SOURCE -ge 1 && $CHECK_DEST -ge 1 && $CHECK_SNAPSHOT -eq 1 && $1 != $2 ]]; then
    echo "$(greenprint "<source zpool>") $(greenprint "$1") $(yellowprint "<destination zpool>") $(greenprint "$2") $(cyanprint "<snapshot>") $(greenprint "$3")"
    echo "$(magentaprint "--- zfs send $1 | zfs recv -F $2/\${dataset} ---")"
    echo "$(magentaprint "--- /usr/bin/time -h rhash -r /\${destination_zpool}/\${dataset} > \${dataset} --" )"

    source=$(zfs list -Ht snapshot | awk '{print $1}' |grep $1/|grep $3)
    eval "source_array=($source)"

    for i in "${source_array[@]}"; do
      dataset=$(echo "$i"|awk -F/ '{print $2}' | awk -F@ '{print $1}')
      echo "$(greenprint "$i") --> $(yellowprint "$2/$dataset") --> $(cyanprint "$dataset.rhash")"
      $(/usr/bin/time -h rhash -r /$2/$dataset > $dataset.rhash)
      $(/usr/bin/time -h zfs send $i | zfs recv -F $2/$dataset)
    done

  elif [[ $CHECK_SOURCE -ge 1 && $CHECK_DEST -ge 1 && CHECK_SNAPSHOT -eq 1 && $1 == $2 ]]; then
    echo "$(redprint "Aborted! identical zpool names") $(greenprint "<source zpool>") $(greenprint "$1") $(yellowprint "<destination zpool>") $(greenprint "$2") $(cyanprint "<snapshot>") $(greenprint "$3")"
    echo "#########################################################################"
    how_to
    zpool_menu

  elif [[ $CHECK_SOURCE -ge 1 && $CHECK_DEST -ge 1 && CHECK_SNAPSHOT -eq 0 ]]; then
    echo "$(greenprint "<source zpool>") $(greenprint "$1") $(yellowprint "<destination zpool>") $(greenprint "$2") $(cyanprint "<snapshot>") $(redprint "$3 does not exist!")"
    echo "#################################"
    how_to
    zpool_menu
  elif [[ $CHECK_SOURCE -ge 1 && $CHECK_DEST -eq 0 && CHECK_SNAPSHOT -eq 0 ]]; then
    echo "$(greenprint "<source zpool>") $(greenprint "$1") $(yellowprint "<destination zpool>") $(redprint "$2 not found!") $(cyanprint "<snapshot>") $(redprint "$3 does not exist!")"
    echo "##################################################################################################"
    how_to
    zpool_menu
  elif [[ $CHECK_SOURCE -ge 1 && $CHECK_DEST -eq 0 && CHECK_SNAPSHOT -eq 1 ]]; then
    echo "$(greenprint "<source zpool>") $(greenprint "$1") $(yellowprint "<destination zpool>") $(redprint "$2 not found!") $(cyanprint "<snapshot>") $(greenprint "$3")"
    echo "##################################################################################################"
    how_to
    zpool_menu
  elif [[ $CHECK_SOURCE -eq 0 && $CHECK_DEST -eq 0 && CHECK_SNAPSHOT -eq 0 ]]; then
    echo "$(greenprint "<source zpool>") $(redprint "$1 not found!") $(yellowprint "<destination zpool>") $(redprint "$2 not found!") $(cyanprint "<snapshot>") $(redprint "$3 does not exist!")"
    echo "##################################################################################################"
    how_to
    zpool_menu
  elif [[ $CHECK_SOURCE -eq 0 && $CHECK_DEST -eq 0 && CHECK_SNAPSHOT -eq 1 ]]; then
    echo "$(greenprint "<source zpool>") $(redprint "$1 not found!") $(yellowprint "<destination zpool>") $(redprint "$2 not found!") $(cyanprint "<snapshot>") $(greenprint "$3")"
    echo "##################################################################################################"
    how_to
    zpool_menu
  elif [[ $CHECK_SOURCE -eq 0 && $CHECK_DEST -ge 1 && CHECK_SNAPSHOT -eq 1 ]]; then
    echo "$(greenprint "<source zpool>") $(redprint "$1 not found!") $(yellowprint "<destination zpool>") $(greenprint "$2") $(cyanprint "<snapshot>") $(greenprint "$3")"
    echo "##################################################################################################"
    how_to
    zpool_menu
  else [[ $CHECK_SOURCE -eq 0 && $CHECK_DEST -ge 1 && CHECK_SNAPSHOT -eq 0 ]];
    echo "$(greenprint "<source zpool>") $(redprint "$1 not found!") $(yellowprint "<destination zpool>") $(greenprint "$2") $(cyanprint "<snapshot>") $(redprint "$3 does not exist!")"
    echo "##################################################################################################"
    how_to
    zpool_menu
  fi
}

main "$@"