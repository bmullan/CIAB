====================================={ Not Ready for Use }=====================================   
  
# CIAB MANO  
## Cloud in a Box, Management & Orchestration    
<center> Brian Mullan (bmulla.mail@gmail.com) May 2025</center>  

<center>
![ciab-logo](https://user-images.githubusercontent.com/1682855/51850975-ea4e3480-22f0-11e9-9128-d945e1e2a9ab.png?classes=float-left)
</center>
<br>
### Architecture Description  
   
CIAB MANO's use-case is to enable deployment of an Architecture that is:    
> - **Multi-Tenant**    
> - **Multi-Cloud**   
> - **Multi-Node/Host** (re Servers/VMs)       

where all **Tenant** ***compute resources*** consist of **Incus 'System'** or **'Application'** (re OCI/Docker) **Containers** & **VMs**.   
   
**Reference:**    
**[https://linuxcontainers.org/incus/docs/main/](https://linuxcontainers.org/incus/docs/main/)**   

### Prerequisites
- Create/update/upgrade the Servers/Hosts (Cloud or VM) that will be CIAB Nodes in the Mesh Network.    
- ***Install & Initialize Incus***  (*incus admin init*) on *all Servers/Hosts for Tenant Compute Resources*.    

When **incus admin init** is executed for the following Questions answer as indicated:   
> What IPv4 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]:   
> What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]:   
> Would you like the server to be available over the network? (yes/no) [default=no]: **yes**  
> Address to bind to (not including port) [default=all]: 
> Port to bind to [default=8443]: **8444**
  
**Change the  default Port for Incus remote server support** from **8443** to **8444** to prevent future conflict   
with Docker & other environments later be installed on any of the Incus Host servers as many of those  
applications which often default to use of Port 8443.  


### MANO CLI commands:  

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


