#!/bin/bash
# Default variables
create_config="false"
# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo $1 | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script automatically takes the validator out of jail"
		echo
		echo -e "Usage: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,  --help           show help page"
		echo -e "  -cc, --create-config  create or overwrite a config file"
		echo
		echo -e "${C_LGn}How to use${RES}:"
		echo -e " ${C_C}1)${RES} Install Tmux"
		echo -e "${C_LY}sudo apt install tmux${RES}"
		echo -e " ${C_C}2)${RES} Open new Tmux window"
		echo -e "${C_LY}tmux new -s unjailer${RES}"
		echo -e " ${C_C}3)${RES} Enter the node directory"
		echo -e "${C_LY}cd $HOME/.umee/${RES}"
		echo -e " ${C_C}4)${RES} Create the config file"
		echo -e "${C_LY}. <(wget -qO- https://raw.githubusercontent.com/SecorD0/Umee/main/unjailer.sh)${RES}"
		echo -e " ${C_C}5)${RES} Open the config file via MobaXterm notepad, Nano, Vi, etc. and customize it"
		echo -e "${C_LY}cat u_config.sh${RES}"
		echo -e " ${C_C}6)${RES} Run the script"
		echo -e "${C_LY}. <(wget -qO- https://raw.githubusercontent.com/SecorD0/Umee/main/unjailer.sh)${RES}"
		echo -e " ${C_C}7)${RES} Detach the window"
		echo -e "Via hotkey: ${C_LY}Ctrl+B, D${RES}"
		echo -e "Via command: ${C_LY}tmux detach${RES}"
		echo
		echo -e " Command to attach the window"
		echo -e "${C_LY}tmux attach -t unjailer${RES}"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Umee/blob/main/unjailer.sh - script URL"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-cc|--create-config)
		create_config="true"
		shift
		;;
	*|--)
		break
		;;
	esac
done
# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
current_time() { date +"%d.%m.%y %H:%M:%S"; }
# Actions
if [ ! -f u_config.sh ] || [ "$create_config" = "true" ]; then
	sudo tee <<EOF >/dev/null u_config.sh
#!/bin/bash
# Acceptable use:
# u_wallet_name="umee_node" | text
# u_wallet_name="\$umee_wallet_name" | variable

u_wallet_name="___"
u_wallet_password="___"
u_delay=60 # how often to restart the script (in secs)
EOF
	printf_n "${C_LGn}Config was created!${RES}"
	return 0 2>/dev/null; exit 0
fi
while true; do
	. ./u_config.sh
	unset u_wallet_name u_wallet_password
	u_node_tcp=`cat $HOME/.umee/config/config.toml | grep -oPm1 "(?<=^laddr = \")([^%]+)(?=\")"`
	u_status=`umeed status --node "$u_node_tcp" 2>&1`
	u_moniker=`jq -r ".NodeInfo.moniker" <<< $u_status`
	u_node_info=`umeed query staking validators --node "$u_node_tcp" --limit 1500 --output json | jq -r '.validators[] | select(.description.moniker=='\"$u_moniker\"')'`
	u_jailed=`jq -r ".jailed" <<< $u_node_info`
	if [ "$u_jailed" = "true" ]; then
		printf_n "${C_LR}`current_time` | The validator is in a jail!${RES}"
		. ./u_config.sh
		echo -e "${u_wallet_password}\n" | umeed tx slashing unjail --from "$u_wallet_name" --chain-id umeevengers-1b --gas 800000 --gas-prices 0.025uumee --node "$u_node_tcp" -y
		unset u_wallet_name u_wallet_password
	else
		printf_n "${C_LGn}`current_time` | The validator isn't in a jail!${RES}" 
	fi
	sleep $u_delay
done
