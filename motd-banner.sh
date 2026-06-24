#!/bin/bash
# /etc/update-motd.d/01-gi-banner

R='\033[1;31m'   # bright red
B='\033[1m'      # bold
D='\033[2m'      # dim
C='\033[36m'     # cyan
N='\033[0m'      # reset

printf "\n"
printf "  ${R}     ██████╗ ██╗     ${N}  ${B}Fundacja Generacja Innowacja${N}\n"
printf "  ${R}    ██╔════╝ ██║     ${N}\n"
printf "  ${R}    ██║  ███╗██║     ${N}\n"
printf "  ${R}    ██║   ██║██║     ${N}  ${D}%s${N}\n" "$(hostname -f 2>/dev/null || hostname)"
printf "  ${R}    ╚██████╔╝██║     ${N}\n"
printf "  ${R}     ╚═════╝ ╚═╝     ${N}  ${C}NetBird peer active${N}\n"
printf "\n"
printf "  ${D}Kernel:${N}  $(uname -r)\n"
printf "  ${D}Uptime:${N}  $(uptime -p 2>/dev/null || uptime)\n"

NB_IP=$(ip addr show wt0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
NB_FQDN=$(netbird status 2>/dev/null | grep -i 'FQDN\|fqdn' | awk -F': ' '{print $2}' | tr -d '[:space:]')

if [ -n "$NB_IP" ]; then
  printf "  ${D}Your public IP:${N}   ${C}%s${N}\n" "$NB_IP"
fi
if [ -n "$NB_FQDN" ]; then
  printf "  ${D}Your public URL:${N}  ${C}%s${N}\n" "$NB_FQDN"
fi

printf "\n"
