# wg-cloud
build a multi tenant cloud based on ubuntu lxc containers

## prerequisits


## usage

       ./wg-cloud  [ host   ] [ install    ] [ cloud-fqdn ] = installs all necessary software to build up the Wireguard VPN Cloud service
                   [ host   ] [ inst-caddy ] [ cloud-fqdn ] = installs web-proxy to build up the Wireguard VPN Cloud service
                   [ status ]                               = shows the status of all Wireguard VPN Cloud service tenants
                   [ help   ]                               = shows all options in detail

       ./wg-cloud  [ tenant ] [ id ] [ add       ] [ cloud-fqdn ] = adds a new tenant to the Wireguard VPN Cloud service
                   [ tenant ] [ id ] [ del       ]                = deletes an existing tenant from the Wireguard VPN Cloud service
                   [ tenant ] [ id ] [ install   ] [ cloud-fqdn ] = installs all necessary software to build up the tenant
                   [ tenant ] [ id ] [ prep-inst ] [ cloud-fqdn ] = creates enviroment file for software installation
                   [ tenant ] [ id ] [ lxc | net ] [ add | del  ] = adds/deletes containter/network infrastructure for a tenant
                   [ tenant ] [ id ] [ status    ]                = shows the status of a Wireguard VPN Cloud tenant


