#!/bin/bash
PORT=22
DOMAINS=(
  ssh-mobile-v4.555606.xyz
  ssh-mobile-v6.555606.xyz
  ssh-vps-v4.555606.xyz
  ssh-vps-v6.555606.xyz
)

# 清理旧规则链
iptables -F SSH_RULES 2>/dev/null
ip6tables -F SSH_RULES 2>/dev/null
iptables -X SSH_RULES 2>/dev/null
ip6tables -X SSH_RULES 2>/dev/null

iptables -N SSH_RULES
ip6tables -N SSH_RULES

for d in "${DOMAINS[@]}"; do
  # IPv4
  for ip in $(dig +short A $d); do
    iptables -A SSH_RULES -p tcp -s $ip --dport $PORT -j ACCEPT
    echo "允许 IPv4 $ip ($d)"
  done
  # IPv6
  for ip in $(dig +short AAAA $d); do
    ip6tables -A SSH_RULES -p tcp -s $ip --dport $PORT -j ACCEPT
    echo "允许 IPv6 $ip ($d)"
  done
done

# 默认 DROP
iptables -A SSH_RULES -j DROP
ip6tables -A SSH_RULES -j DROP

# 应用到 INPUT 链
iptables -D INPUT -p tcp --dport $PORT -j SSH_RULES 2>/dev/null
ip6tables -D INPUT -p tcp --dport $PORT -j SSH_RULES 2>/dev/null
iptables -I INPUT -p tcp --dport $PORT -j SSH_RULES
ip6tables -I INPUT -p tcp --dport $PORT -j SSH_RULES
