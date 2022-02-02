#!/usr/bin/env bash
set -e
debug=1

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


main () {
  echo -ne "
$(yellowprint 'Choose an option:') "
  #zpool=$(zpool list -Ho name |tr '\n' ','| sed 's/,$//')
  zpool=$(zpool list -Ho name |tr '\n' ' '| sed 's/ $//')

  if [ $# -ne 1 ]; then
    echo "[Create smb4.conf, create guest/guest, enable samba, start service]"
    echo "Usage: samba_setup.sh $(cyanprint '<enter zpool>')"
    echo "Available zpool: ($(greenprint "$zpool"))"
    exit 1
  fi
  if [[ "$zpool" =~ "$1" ]]; then
    echo "$(cyanprint "found zpool: $1"), $(greenprint "creating") /usr/local/etc/smb4.conf file"
    path=$(zfs list|awk '{print $5}'|grep $1/)

###### create /usr/local/etc/smb4.conf file #######

config=$(cat <<EOF
valid users = guest
writable  = yes
browsable = yes
read only = no
guest ok = no
public = no
create mask = 0666
directory mask = 0755
EOF
)


    for p in $path; do

      echo $p|rev|cut -d/ -f1|rev|awk '{print "["$1"]"}'
      echo "path = $p"
      echo "$config"
      echo ""
    done > /usr/local/etc/smb4.conf

    echo "$(greenprint "creating samba guest/guest")"

    for p in $path; do
      chown -R guest:guest $path
    done

    echo "$(greenprint "enable samba, start service")"
    echo ""
    (echo "guest" ; sleep 1 ; echo "guest") | pdbedit -au guest > /dev/null 2>&1
    (echo "guest" ; sleep 1 ; echo "guest") | smbpasswd -s -a guest > /dev/null 2>&1
    sysrc samba_server_enable=YES 1>/dev/null > /dev/null 2>&1
    service samba_server restart 1>/dev/null > /dev/null 2>&1

    if [ $debug = 1 ]; then
      echo "$(cat /usr/local/etc/smb4.conf)"
    fi
  else
    echo "$(cyanprint "zpool: $1 ")$(redprint "does not exist!")"
  fi
}

main "$@"