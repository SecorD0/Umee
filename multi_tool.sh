#!/bin/bash
# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script installs a Umee node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help  show the help page"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Umee/blob/main/multi_tool.sh - script URL"
		echo -e "https://t.me/OnePackage — noderun and tech community"
		echo
		return 0 2>/dev/null; exit 0
		;;
	*|--)
		break
		;;
	esac
done
# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
# Actions
sudo apt install wget -y &>/dev/null
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
sudo apt update
sudo apt upgrade -y 
sudo apt install wget jq pkg-config build-essential libssl-dev -y
mkdir $HOME/data
umee_version=`wget -qO- https://api.github.com/repos/umee-network/umee/releases/latest | jq -r ".tag_name"`
wget -q "https://github.com/umee-network/umee/releases/download/${umee_version}/umeed-${umee_version}-linux-amd64.tar.gz"
tar -xzf "$HOME/umeed-${umee_version}-linux-amd64.tar.gz"
chmod +x "$HOME/umeed-${umee_version}-linux-amd64/umeed"
mv "$HOME/umeed-${umee_version}-linux-amd64/umeed" /usr/bin/
rm -rf "$HOME/umeed-${umee_version}-linux-amd64.tar.gz" "$HOME/umeed-${umee_version}-linux-amd64"
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n umee_chain -v "umeevengers-1c"
rm -rf $HOME/.umee/config/genesis.json
umeed unsafe-reset-all
printf_n "${C_LGn}Done!${RES}"
printf_n "
Daemon version:${C_LGn}"
umeed version
printf_n "${RES}"
