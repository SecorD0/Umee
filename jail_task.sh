#!/bin/bash
# Default variables
rpc="http://62.171.166.224:26657/"
validator_address=""
file_name="jail_task.txt"

# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script provides advanced CLI client features"
		echo
		echo -e "Usage: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,   --help            show help page"
		echo -e "        --rpc URL         RPC that will be used to execute commands (default is ${C_LGn}${rpc}${RES})"
		echo -e "  -va ADDRESS             validator address to check (default is ${C_LGn}parsed from a list of validators${RES})"
		echo -e "  -fn,  --file-name NAME  NAME of file to save the info for form (default is ${C_LGn}${file_name}${RES})"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Umee/blob/main/jail_task.sh - script URL"
		echo -e "         (you can send Pull request with new texts to add a language)"
		echo -e "https://t.me/OnePackage — noderun and tech community"
		echo
		return 0 2>/dev/null; exit 0
		;;
	--rpc*)
		if ! grep -q "=" <<< "$1"; then shift; fi
		rpc=`option_value "$1"`
		shift
		;;
	-va*)
		if ! grep -q "=" <<< "$1"; then shift; fi
		validator_address=`option_value "$1"`
		shift
		;;
	-fn*|--file-name*)
		if ! grep -q "=" <<< "$1"; then shift; fi
		file_name=`option_value "$1"`
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
main () {
	if [ ! -n "$validator_address" ]; then
		local node_tcp=`cat "$HOME/.umee/config/config.toml" | grep -oPm1 "(?<=^laddr = \")([^%]+)(?=\")"`
		local moniker=`umeed status --node "$node_tcp" 2>&1 | jq -r ".NodeInfo.moniker"`
		local node_info=`umeed query staking validators --node "$node_tcp" --limit 1500 --output json | jq -r '.validators[] | select(.description.moniker=='\"$moniker\"')'`
		validator_address=`jq -r ".operator_address" <<< $node_info`
		printf_n "\nParsed validator address: ${C_LGn}${validator_address}${RES}\n\nStarting up in ${C_LGn}5${RES} seconds"
	else
		printf_n "\nSpecified validator address: ${C_LGn}${validator_address}${RES}\n\nStarting up in ${C_LGn}5${RES} seconds"
	fi
	for i in `seq 1 5`; do printf_n "${C_LGn}${i}${RES}"; sleep 1; done
	printf_n "\n${C_LGn}Let's go to a jail!\n\nStopping a node service file${RES}\n"
	sudo systemctl stop umeed
	printf_n "${C_LGn}Checking for a jail time${RES}"
	local checked_block=0
	while true; do
		local current_block=`wget -qO- "${rpc}abci_info" | jq -r ".result.response.last_block_height"`
		if [ "$current_block" -ne "$checked_block" ]; then
			printf_n "\nChecking block: ${C_LGn}${current_block}${RES}"
			local block_info=`umeed query staking historical-info $current_block --node "$rpc" --output json`
			local block_time=`jq -r ".header.time" <<< "$block_info"`
			printf_n "Block time: ${C_LGn}${block_time}${RES}"
			local validator_info=`jq -r '.valset[] | select(.operator_address=='\"$validator_address\"')' <<< "$block_info"`
			local jailed=`jq -r ".jailed" <<< "$validator_info"`
			printf_n "Validator jailed: ${C_LGn}${jailed}${RES}"
			if [ "$jailed" != "false" ]; then
				local jailed_block=$current_block
				local block_hash=`wget -qO- "${rpc}block?height=${current_block}" | jq -r ".result.block_id.hash"`
				local timestamp=`printf_n "$block_time" | sed 's%\.[^\.]*$%%'`
				printf_n "Jailing block height: ${jailed_block}
Jailing timestamp: ${timestamp}Z
Jailing tx HASH: ${block_hash}" >> "$file_name"
				break
			fi
			local checked_block=$current_block
			sleep 2
		fi
	done
	printf_n "\n${C_LGn}Let's escape the jail!${RES}\n\nWaiting for full ${C_LGn}synchronization${RES}"
	sudo systemctl restart umeed
	sleep 5
	while true; do
		local catching_up=`umeed status --node "$node_tcp" 2>&1 | jq -r ".SyncInfo.catching_up"`
		if [ "$catching_up" = "false" ]; then
			printf_n "${C_LGn}Synchronized${RES}"
			break
		else
			printf_n "${C_LGn}Synchronizing${RES}"
			sleep 5

		fi
	done
	printf_n "\nWaiting ${C_LGn}10${RES} minutes for chance of escape from the jail"
	for i in `seq 1 10`; do sleep 60; printf_n "${C_LGn}${i}${RES} minute"; done
	printf_n "\n${C_LGn}Sleeping some more :)${RES}\n"
	sleep 20
	printf_n "${C_LGn}Escaping from the jail${RES}\n"
	umeed tx slashing unjail --from "$umee_wallet_name" --chain-id umeevengers-1c --fees 300uumee --gas 300000 --node "$node_tcp" --keyring-backend test -y
	local current_block=`wget -qO- "${rpc}abci_info" | jq -r ".result.response.last_block_height"`
	printf_n "\nWaiting ${C_LGn}20${RES} seconds for creating blocks"
	sleep 20
	for block in `seq $((current_block-1)) $((current_block+2))`; do
		printf_n "\nChecking block: ${C_LGn}${block}${RES}"
		local block_info=`umeed query staking historical-info $block --node "$rpc" --output json`
		local block_time=`jq -r ".header.time" <<< "$block_info"`
		printf_n "Block time: ${C_LGn}${block_time}${RES}"
		local validator_info=`jq -r '.valset[] | select(.operator_address=='\"$validator_address\"')' <<< "$block_info"`
		local jailed=`jq -r ".jailed" <<< "$validator_info"`
		printf_n "Validator jailed: ${C_LGn}${jailed}${RES}"
		if [ "$jailed" = "false" ]; then
			local unjail_block=$((block-1))
			break
		fi
	done
	printf_n "\n${C_LGn}Checking unjail block${RES}"
	local block_info=`umeed query staking historical-info $unjail_block --node "$rpc" --output json`
	local block_time=`jq -r ".header.time" <<< "$block_info"`
	local block_hash=`wget -qO- "${rpc}block?height=${unjail_block}" | jq -r ".result.block_id.hash"`
	local timestamp=`printf_n "$block_time" | sed 's%\.[^\.]*$%%'`
	printf_n "Unjailing block height: ${unjail_block}
Unjailing timestamp: ${timestamp}Z
Unjailing tx HASH: ${block_hash}
Block numbers you missed while in jail: ${jailed_block}-${unjail_block}" >> "$file_name"
	printf_n "\n\n${C_LGn}All done!${RES}\nFill the form: https://docs.google.com/forms/d/e/1FAIpQLSdZoyAttixC3jnknjksNg92MJo3GNM9B3eGPlk0yYyaPscPCA/viewform\n\nInfo from this file: `pwd`/${file_name}\n"
	cat "`pwd`/${file_name}"
}

# Actions
main
