#!/bin/bash

IFID=$2
PUBLICIP=167.235.206.167
WGIF=wg${IFID}
WGPORT=200${IFID}
BRIDGEIF=br-${WGIF}
BRIDGENET=10.${IFID}.0
BACKUPFILE=$( date +%Y%m%d%H%M )-${WGIF}-db.tar

tenant_net_add(){
	echo "add ${BRIDGEIF}"
	incus network create ${BRIDGEIF}
	incus network set ${BRIDGEIF} ipv4.address=${BRIDGENET}.1/24
	incus network set ${BRIDGEIF} ipv6.address=
	incus network set ${BRIDGEIF} ipv6.nat=
	incus network set ${BRIDGEIF} ipv4.dhcp.ranges=${BRIDGENET}.2-${BRIDGENET}.2

	echo "IP Tables Portforward"
	# Wireguard UDP - Port-Forwading and NAT to ${BRIDGENET}.2:${WGPORT}
	iptables -A FORWARD -i eth0 -o ${BRIDGEIF} -p udp --dport ${WGPORT} -m conntrack --ctstate NEW -j ACCEPT
	iptables -A FORWARD -i eth0 -o ${BRIDGEIF} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -A FORWARD -i ${BRIDGEIF} -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	echo "IP Tables Nat"
	# Nat
	iptables -t nat -A PREROUTING -i eth0 -p udp --dport ${WGPORT} -j DNAT --to-destination ${BRIDGENET}.2 
	iptables -t nat -A POSTROUTING -o ${BRIDGEIF} -p udp --dport ${WGPORT} -d ${BRIDGENET}.2  -j SNAT --to-source ${PUBLICIP}

	# SSHD - Port-Forwading and NAT to ${BRIDGENET}.2:22
	# iptables -A FORWARD -i eth0 -o ${BRIDGEIF} -p tcp --dport ${WGPORT} -m conntrack --ctstate NEW -j ACCEPT
	# iptables -A FORWARD -i eth0 -o ${BRIDGEIF} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	# iptables -A FORWARD -i ${BRIDGEIF} -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	# Nat
	# iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 22 -j DNAT --to-destination ${BRIDGENET}.2 
	# iptables -t nat -A POSTROUTING -o ${BRIDGEIF} -p tcp --dport 22 -d ${BRIDGENET}.2  -j SNAT --to-source ${PUBLICIP}
	
	echo "saves ip tables"
	/sbin/iptables-save > /etc/iptables/rules.v4

	echo "network list"
	incus network list 
}

tenant_net_del(){
	echo "delete ${BRIDGEIF}"
	# Wireguard UDP - Port-Forwading and NAT to ${BRIDGENET}.2:${WGPORT}
	iptables -D FORWARD -i eth0 -o ${BRIDGEIF} -p udp --dport ${WGPORT} -m conntrack --ctstate NEW -j ACCEPT
	iptables -D FORWARD -i eth0 -o ${BRIDGEIF} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -D FORWARD -i ${BRIDGEIF} -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	# Nat
	iptables -t nat -D PREROUTING -i eth0 -p udp --dport ${WGPORT} -j DNAT --to-destination ${BRIDGENET}.2 
	iptables -t nat -D POSTROUTING -o ${BRIDGEIF} -p udp --dport ${WGPORT} -d ${BRIDGENET}.2  -j SNAT --to-source ${PUBLICIP}

	# SSHD - Port-Forwading and NAT to ${BRIDGENET}.2:22
	# iptables -D FORWARD -i eth0 -o ${BRIDGEIF} -p tcp --dport ${WGPORT} -m conntrack --ctstate NEW -j ACCEPT
	# iptables -D FORWARD -i eth0 -o ${BRIDGEIF} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	# iptables -D FORWARD -i ${BRIDGEIF} -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	# Nat
	# iptables -t nat -D PREROUTING -i eth0 -p tcp --dport 22 -j DNAT --to-destination ${BRIDGENET}.2 
	# iptables -t nat -D POSTROUTING -o ${BRIDGEIF} -p tcp --dport 22 -d ${BRIDGENET}.2  -j SNAT --to-source ${PUBLICIP}

	echo "saves ip tables"
	/sbin/iptables-save > /etc/iptables/rules.v4

	incus network delete ${BRIDGEIF}
	incus network list 
}

tenant_incus_add(){
	echo "adding linux container ${WGIF}-router01"
	incus launch ubuntu:22.04 ${WGIF}-router01
	#incus stop ${WGIF}-router01 
	incus config device add ${WGIF}-router01 eth0 nic nictype=bridged parent=${BRIDGEIF} name=eth0
	#incus start ${WGIF}-router01 
	incus config set ${WGIF}-router01  boot.autostart true
	incus list
}

tenant_incus_del(){
	echo "deleting linux container ${WGIF}-router01"
	incus stop ${WGIF}-router01 
	incus delete ${WGIF}-router01
	incus list
}


tenant_add() {
	echo "adding Wireguard VPN Cloud Tenant ${WGIF}"
	tenant_net_add
	tenant_incus_add	
	tenant_install
}

tenant_del() {
	echo "deleting Wireguard VPN Cloud Tenant ${WGIF}"
	tenant_incus_del
	tenant_net_del
}

tenant_prep-inst() {
	cat << EOF > wg-tenant.env
IFID=${IFID}
WGUIFQDN=${WGUIFQDN}
EOF
	incus file push wg-tenant ${WGIF}-router01/root/
	incus file push wg-tenant.env ${WGIF}-router01/root/
}

tenant_install() {
	echo "installing Wireguard Software to Tenant ${WGIF}"
        tenant_prep-inst

	echo -n "waiting for 10.${IFID}.0.2 to come up "
	until $(ping -c1 10.${IFID}.0.2 &>/dev/null); do 
		echo -n "."
	done
	echo " done"

	incus exec ${WGIF}-router01 /root/wg-tenant install 
	rm wg-tenant.env
	echo "incus exec ${WGIF}-router01 /etc/wireguard/status.sh"
}

tenant_status() {
	echo "status of Wireguard VPN Cloud Tenant ${WGIF}"
	incus exec ${WGIF}-router01 /etc/wireguard/status.sh
}

tenant_start() {
	echo "starting Wireguard VPN Cloud Tenant ${WGIF}"
	incus exec ${WGIF}-router01 /root/wg-tenant start
}

tenant_stop() {
	echo "stopping Wireguard VPN Cloud Tenant ${WGIF}"
	incus exec ${WGIF}-router01 /root/wg-tenant stop
}

tenant_restart() {
	echo "restarting Wireguard VPN Cloud Tenant ${WGIF}"
	incus exec ${WGIF}-router01 /root/wg-tenant restart
}

tenant_backup() {
	echo "Backup Config-Data Wireguard VPN Cloud Tenant ${WGIF}"

	[ ! -d "/root/${WGIF}" ] && mkdir /root/${WGIF}
	incus exec ${WGIF}-router01 /root/wg-tenant backup ${BACKUPFILE}
	incus file pull ${WGIF}-router01/etc/wireguard/${BACKUPFILE} /root/${WGIF}/
	incus exec ${WGIF}-router01 rm /etc/wireguard/${BACKUPFILE}
	cp /root/${WGIF}/${BACKUPFILE} /root/${WGIF}/${WGIF}-db.tar
}

tenant_restore() {
	echo "Restore Config-Data Wireguard VPN Cloud Tenant ${WGIF}"

	incus file push /root/${WGIF}/${WGIF}-db.tar  ${WGIF}-router01/etc/wireguard/
	incus exec ${WGIF}-router01 /root/wg-tenant restore ${WGIF}-db.tar 
}

host_install() {
	echo "installing software packages"
	apt-get update
	apt-get -y upgrade
	apt install -y net-tools wget nano nala curl ufw
	apt  install -y iptables-persistent
	systemctl enable netfilter-persistent.service
	systemctl start netfilter-persistent.service

	host_inst-incus
	host_inst-caddy
}

host_inst-incus() {
	# add the Incus 'Stable' repository
sh -c 'cat <<EOF > /etc/apt/sources.list.d/zabbly-incus-stable.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc

EOF'
        apt update

	# Install Incus
	apt install incus

        # Make current $USER an incus admin
        adduser $USER incus
        adduser $USER incus-admin

        # Initialze (ie configure Incus)
	incus admin init
	incus list
	incus network list
}

host_inst-caddy() {
	# caddy web-proxy installation
	apt install -y debian-keyring debian-archive-keyring apt-transport-https -y
	curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
	curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
	apt-get update
	apt-get install caddy -y
	systemctl enable --now caddy

	cat << EOF > /etc/caddy/Caddyfile
{
  # Used for automatic HTTPS
  email dont@wana.tell.us
}

${WGUIFQDN} {
   
   # config must be changed after installation test
   root * /var/www/html/

#  handle /wg21* {
#        reverse_proxy 10.21.0.2:5000
#	}

#  handle /wg22* {
#        reverse_proxy 10.22.0.2:5000
#	}

#  handle /wg31* {
#        reverse_proxy 10.31.0.2:5000
#	}

#  handle /wg32* {
#        reverse_proxy 10.32.0.2:5000
#	}

# follow this pattern ... 

}

# Refer to the Caddy docs for more information:
# https://caddyserver.com/docs/caddyfile	
EOF

	mkdir -p /var/www/html
	cat << EOF > /var/www/html/index.hml
<!DOCTYPE html>
<html>
<head>
<title>Wireguard VPN Cloud Service</title>
</head>
<body>
<h1 style="font-family: sans-serif">service is up and running ...</h1>
</body>
</html>
EOF

	systemctl start caddy
	systemctl status caddy
	echo "# webproxy started"
	echo "# check https://${WGUIFQDN}"
	echo ""
}

status() {
	incus list
	incus network list
	netstat -tulpn
	systemctl status netfilter-persistent.service
	systemctl status caddy

}

help() {
	echo ""
	case $1 in
	1)
		echo "Usage: ./wg-cloud  [ host   ] [ install    ] [ cloud-fqdn ] = installs all necessary software to build up the Wireguard VPN Cloud service"
		echo "                   [ status ]                               = shows the status of all Wireguard VPN Cloud service tenants"
		echo "                   [ help   ]                               = shows all options in detail"
		echo ""
		echo "       ./wg-cloud  [ tenant ] [ id ] [ add       ] [ cloud-fqdn ] = adds a new tenant to the Wireguard VPN Cloud service"
		echo "                   [ tenant ] [ id ] [ del       ]                = deletes an existing tenant from the Wireguard VPN Cloud service"
		echo "                   [ tenant ] [ id ] [ status    ]                = shows the status of a Wireguard VPN Cloud tenant"
		exit 1
		;;
	*)
		echo "Usage: ./wg-cloud  [ host   ] [ install    ] [ cloud-fqdn ] = installs all necessary software to build up the Wireguard VPN Cloud service"
		echo "                   [ host   ] [ inst-caddy ] [ cloud-fqdn ] = installs web-proxy to build up the Wireguard VPN Cloud service"
		echo "                   [ status ]                               = shows the status of all Wireguard VPN Cloud service tenants"
		echo "                   [ help   ]                               = shows all options in detail"
		echo " "
		echo "       ./wg-cloud  [ tenant ] [ id ] [ add       ] [ cloud-fqdn ] = adds a new tenant to the Wireguard VPN Cloud service"
		echo "                   [ tenant ] [ id ] [ del       ]                = deletes an existing tenant from the Wireguard VPN Cloud service"
		echo "                   [ tenant ] [ id ] [ install   ] [ cloud-fqdn ] = installs all necessary software to build up the tenant"
		echo "                   [ tenant ] [ id ] [ prep-inst ] [ cloud-fqdn ] = creates enviroment file for software installation"
	        echo "                   [ tenant ] [ id ] [ incus | net ] [ add | del  ] = adds/deletes containter/network infrastructure for a tenant"   
		echo "                   [ tenant ] [ id ] [ start | stop | restart   ] = starts/stops Wireguard VPN Cloud tenant"
		echo "                   [ tenant ] [ id ] [ backup | restore         ] = backup/restore config-data of Wireguard VPN Cloud tenant"
		echo "                   [ tenant ] [ id ] [ status    ]                = shows the status of a Wireguard VPN Cloud tenant"
		;;
	esac
	echo ""
}

case $1 in
tenant)
	WGUIFQDN=$4
	case $2 in
	'')
		help 1
		;;
	*)
		case $3 in
		add|install|prep-inst)
			case $4 in
			'')
				help 1
				;;
			*)
				$1_$3
				;;
			esac
		;;
		del|status|start|stop|restart|backup|restore)
			$1_$3
			;;
		incus|net)
			case $4 in
			add|del)
				$1_$3_$4
				;;
			*)
				help 1
				;;
			esac	
			;;
		esac
		;;
	*)
		help 1
		;;
	esac
	;;
host)
	WGUIFQDN=3
	case $2 in
	install|inst-caddy)
		case $3 in
		'')
			help 1
			;;
		*)
			$1_$2
			;;
		esac
		;;
	*)
		help 1
		;;
	esac
	;;
status|help)
	$1	
	;;
*)
	help 1
	;;
esac

exit 0
