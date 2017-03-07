#!/bin/bash

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CDIR="$( cd "$( dirname "$0" )" && pwd )"
source ${CDIR}/inc/bash_colors.sh

if [[ $(id -u) -eq 0 ]]; then
	labelin; echo -n " Initializing SECTHEMALL Public Blacklist client on "; clr_blue ${CDIR}
else
	labeler; echo " This script should not be run using sudo or as the root user."
	exit 1
fi

if ! type "iptables" > /dev/null; then
	labeler; echo " iptables not found."
	echo "+"
	exit 1;
fi

if ! type "curl" > /dev/null; then
	labeler; echo " cURL not found."
	echo "+"
	exit 1;
fi

CHECKSECTHEMALLCHAINBL=$(iptables -L -n | grep -i 'Chain' | grep 'secthemall-blacklist' | wc -l)
if [[ "${CHECKSECTHEMALLCHAINBL}" == "0" ]]; then
	labelwa; echo " secthemall iptables blacklist does not exists, creating it..."
	iptables -N secthemall-blacklist
	iptables -I INPUT -j secthemall-blacklist
	iptables -I FORWARD -j secthemall-blacklist
else
	labelin; echo " secthemall iptables blacklist exists, great!"
fi

GETBLACKLIST4=$(curl -s 'https://secthemall.com/public-list/brute-force/list')
for ip in $GETBLACKLIST4; do
CHECKLIST=$(iptables -L secthemall-blacklist -n | grep -wo ${ip} | wc -l)
if [[ "${CHECKLIST}" == "0" ]]; then
	iptables -I secthemall-blacklist -s ${ip} -j DROP
	labelin; echo " IP ${ip} added to blacklist."
else
	labelwa; echo " IP ${ip} already in blacklist."
fi
done;

labelok; echo " Blacklist v4 synced."
exit 0
