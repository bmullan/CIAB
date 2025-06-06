#!/bin/bash
. /root/wg-tenant.env
WGIF=wg${IFID}
WGUIUSER=admin
WGUIPORT=200${IFID}
VERSION=0.2

install() {
	apt-get update
	apt-get -y upgrade
	apt install -y net-tools wget nano nala ufw
	apt install -y wireguard curl tar

WGUIPASSWD=$( /usr/bin/wg genkey )

	echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	sysctl -p


	systemctl stop wgui.{path,service} wg-quick@wg0.service wgui-web.service
	systemctl disable wgui.{path,service} wg-quick@wg0.service wgui-web.service
	rm -r /etc/wireguard

	mkdir /etc/wireguard

	cat <<EOF > /etc/wireguard/start-wgui.sh
#!/bin/bash
cd /etc/wireguard
./wireguard-ui -bind-address 0.0.0.0:5000 -base-path=/${WGIF}
EOF
chmod +x /etc/wireguard/start-wgui.sh

cat <<EOF > /etc/wireguard/wgui-web.env
WGUI_USERNAME=${WGUIUSER}
WGUI_PASSWORD=${WGUIPASSWD}
WGUI_ENDPOINT_ADDRESS=${WGUIFQDN}
WGUI_CONFIG_FILE_PATH=/etc/wireguard/wg0.conf
WGUI_SERVER_INTERFACE_ADDRESSES=10.0.0.1/24
WGUI_SERVER_LISTEN_PORT=${WGUIPORT}
WGUI_FORWARD_MARK=
WGUI_SERVER_POST_UP_SCRIPT=iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
WGUI_SERVER_POST_DOWN_SCRIPT=iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

	cat <<EOF > /etc/systemd/system/wgui-web.service
[Unit]
Description=WireGuard UI
 
[Service]
Type=simple
EnvironmentFile=/etc/wireguard/wgui-web.env
WorkingDirectory=/etc/wireguard
ExecStart=/etc/wireguard/start-wgui.sh

User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

	cat <<EOF > /etc/wireguard/wg-ui-update.sh
#!/bin/bash

VER=\$(curl -sI https://github.com/ngoduykhanh/wireguard-ui/releases/latest | grep "location:" | cut -d "/" -f8 | tr -d '\r')

echo "downloading wireguard-ui \$VER"
curl -sL "https://github.com/ngoduykhanh/wireguard-ui/releases/download/\$VER/wireguard-ui-\$VER-linux-amd64.tar.gz" -o wireguard-ui-\$VER-linux-amd64.tar.gz

echo -n "extracting "; tar xvf wireguard-ui-\$VER-linux-amd64.tar.gz

echo "restarting wgui-web.service"
systemctl restart wgui-web.service
EOF

	chmod +x /etc/wireguard/wg-ui-update.sh
	cd /etc/wireguard; ./wg-ui-update.sh


	cat <<EOF > /etc/systemd/system/wgui.service
[Unit]
Description=Restart WireGuard
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/systemctl restart wg-quick@wg0.service

[Install]
RequiredBy=wgui.path
EOF



	cat <<EOF > /etc/systemd/system/wgui.path
[Unit]
Description=Watch /etc/wireguard/wg0.conf for changes

[Path]
PathModified=/etc/wireguard/wg0.conf

[Install]
WantedBy=multi-user.target
EOF


	cat <<EOF > /etc/wireguard/status.sh
systemctl status wgui.path wgui.service wg-quick@wg0.service wgui-web.service
EOF
	chmod +x /etc/wireguard/status.sh

systemctl enable wgui.path wgui.service wg-quick@wg0.service wgui-web.service
systemctl start wgui.path wgui.service wg-quick@wg0.service wgui-web.service
add_test_client

        echo "===\{ Wireguard Client ${IFID} set up \}=================="
	echo " "
	echo " Wireguard client ${IFID} set up"
	echo " "
	echo " VPN client setup via Wireguard UI"
	echo " url:      https://${WGUIFQDN}/${WGIF}/login?next=/${WGIF}"
	echo " user:     ${WGUIUSER}"
	echo " password: ${WGUIPASSWD}"
	echo " "
	echo " Configuration of container ${WGIF}-router01"
	echo " ssh -p 200${IFID} ${WGIF}@${WGUIFQDN}"
	echo " "
	echo " Note:   RAS Public Key required!!"
	echo " "
        echo "========================================================"
	echo " "


}

add_test_client() {

cat <<EOF > /etc/wireguard/db/clients/ceblve46e0e9hmj6d8a0.json 
{
	"id": "ceblve46e0e9hmj6d8a0",
	"private_key": "AK59H3sS75x7jZvLCBnKlt5qYtZvdUZCC9fTXLSt/mQ=",
	"public_key": "VO+typWLn/fr/rqwLj7z4EMSTBtF2s8mxot0Thm/iVU=",
	"preshared_key": "FQxBWQFpDeS/Uz02MYgdpEcAHAH1Y1sIo9YWdCwUtro=",
	"name": "Mandant ${WGIF} Test",
	"email": "nach dem Test UNBEDINGT löschen",
	"allocated_ips": [
		"10.0.0.2/32"
	],
	"allowed_ips": [
		"0.0.0.0/0"
	],
	"extra_allowed_ips": [],
	"use_server_dns": true,
	"enabled": true,
	"created_at": "2022-12-12T17:07:04.177006662Z",
	"updated_at": "2022-12-12T17:07:04.177006662Z"
}
EOF
	systemctl restart wgui-web.service

}

start() {
	echo ""
	echo "starting Wireguard VPN Cloud "${WGIF}" Tenant"
	echo ""
	systemctl start wgui.path wgui.service wg-quick@wg0.service wgui-web.service
}

stop() {
	echo ""
	echo "stopping Wireguard VPN Cloud "${WGIF}" Tenant"
	echo ""
	systemctl stop wgui.path wgui.service wg-quick@wg0.service wgui-web.service 
}

restart() {
	stop
	start
}

backup() {
	echo ""
	echo "backing up  Wireguard VPN Cloud "${WGIF}" Tenant"
	echo ""
	if [ -z "$1" ]; then
		BACKUPFILE1=$( date +%Y%m%d%H%M )-${WGIF}-db.tar
	else
		BACKUPFILE1=$1
	fi

	cd /etc/wireguard
	tar cf ${BACKUPFILE1} db/
	echo ${BACKUPFILE1}" successfully created"
}

restore() {
	echo ""
	echo "restoring  Wireguard VPN Cloud "${WGIF}" Tenant"
	echo ""

	if [ -z "$1" ]; then
		BACKUPFILE2=${WGIF}-db.tar
	else
		BACKUPFILE2=$1
	fi

	cd /etc/wireguard
	if [ -f "${BACKUPFILE2}" ]; then
		stop
		backup
		rm -r db/
		tar xvf ${BACKUPFILE2} db/
		start
		echo "/etc/wireguard/${BACKUPFILE2} successfully restored"
	else
		echo "unable to restore /etc/wireguard/${BACKUPFILE2}"
		echo "file does not exist"
	fi
}

status() {
	echo ""
	echo "Wireguard VPN Cloud "${WGIF}" Tenant"
	echo ""
	/etc/wireguard/status.sh
	netstat -tulpn
	wg show
}

version() {
	echo $0" "${VERSION}" Tenant:"${WGIF}
}

help() {
	echo ""
	echo "Wireguard VPN Cloud "${WGIF}" Tenant"
	echo ""
	echo "Usage wg-tenant [ install | update       ]"
	echo "      wg-tenant [ start | stop | restart ]"
	echo "      wg-tenant [ backup | restore       ] { file }" 
	echo "      wg-tenant [ status                 ]"
	echo "      wg-tenant [ version | help         ]"
	echo ""
}

case ${IFID} in
'')
	help 1
	;;
*)
	case $1 in
	start|stop|restart|backup|restore|install|status|version|help)
		$1 $2
		;;
	*)
		help 1
		;;
	esac
	;;
esac
exit 0




