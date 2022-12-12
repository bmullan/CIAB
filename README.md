# wg_cloud
build a multi tenant cloud based on ubuntu lxc containers

Usage: ./wg_cloud  [ host   ] [ install ] = installs all necessary software to build up the Wireguard VPN Cloud service
                   [ status ]             = shows the status of all Wireguard VPN Cloud service tenants
                   [ help   ]             = shows all options in detail

       ./wg_cloud  [ tenant ] [ id ] [ add       ] [ WG-FQDN   ] = adds a new tenant to the Wireguard VPN Cloud service
                   [ tenant ] [ id ] [ del       ]               = deletes an existing tenant from the Wireguard VPN Cloud service
                   [ tenant ] [ id ] [ install   ] [ WG-FQDN   ] = installs all necessary sortware to build up the tenant
                   [ tenant ] [ id ] [ lxc | net ] [ add | del ] = adds/deletes containter/network infrastructure for a tenant
                   [ tenant ] [ id ] [ status    ]               = shows the status of a Wireguard VPN Cloud tenant
