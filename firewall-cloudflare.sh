#!/bin/bash
# Configura firewall para solo Cloudflare + Docker

# IP de tu servidor Hetzner
HETZNER_IP="65.21.152.95"

# Limpiar reglas
iptables -F && iptables -X
iptables -t nat -F && iptables -t nat -X

# Políticas
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Conexiones establecidas y loopback
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

# SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# PERMITIR CLOUDFLARE (IPv4)
for ip in $(curl -s https://www.cloudflare.com/ips-v4); do
    iptables -A INPUT -p tcp -s $ip --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp -s $ip --dport 443 -j ACCEPT
done

# PERMITIR DOCKER INTERNO
iptables -A INPUT -s 172.16.0.0/12 -d $HETZNER_IP -j ACCEPT
iptables -A INPUT -s 192.168.0.0/16 -d $HETZNER_IP -j ACCEPT

echo "Firewall configurado. Solo Cloudflare en puertos 80/443"
echo "IPs de Cloudflare permitidas"

# Guardar
apt-get install -y iptables-persistent 2>/dev/null
iptables-save > /etc/iptables/rules.v4
