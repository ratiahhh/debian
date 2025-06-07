#!/bin/bash

# Membersihkan layar
clear

# ====== Tambahkan ASCII Art di sini ======
echo -e "\033[1;36m" # Warna Cyan
echo "██████╗░░█████╗░████████╗██╗░█████╗░██╗░░██╗"
echo "██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗██║░░██║"
echo "██████╔╝███████║░░░██║░░░██║███████║███████║"
echo "██╔══██╗██╔══██║░░░██║░░░██║██╔══██║██╔══██║"
echo "██║░░██║██║░░██║░░░██║░░░██║██║░░██║██║░░██║"
echo "╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝"
echo -e "\033[0m" # Mengembalikan warna default

# Warna untuk output
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
RED='\033[1;31m'
NC='\033[0m'

# Fungsi untuk pesan sukses dan gagal
success_message() { echo -e "${GREEN}$1 berhasil!${NC}"; }
error_message() { echo -e "${RED}$1 gagal!${NC}"; exit 1; }

# Otomasi Dimulai
echo -e "${BLUE}Otomasi Dimulai${NC}"

# Menambahkan Repository
echo -e "${YELLOW}${PROGRES[0]}${NC}"
REPO="http://kartolo.sby.datautama.net.id/debian/"                                 
if ! grep -q "$REPO" /etc/apt/sources.list; then
    cat <<EOF | sudo tee /etc/apt/sources.list > /dev/null
deb http://kartolo.sby.datautama.net.id/debian/ buster main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian/ buster-updates main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian-security/ buster/updates main contrib non-free 
EOF

# Update Paket
echo -e "${YELLOW}${PROGRES[1]}${NC}"
sudo apt update -y > /dev/null 2>&1 || error_message "${PROGRES[1]}"

# Konfigurasi IP
echo -e "${YELLOW}${PROGRES[2]}${NC}"
cat <<EOT | sudo tee  /etc/network/interface* > /dev/null

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface (enp0s3) with static IP
auto enp0s3
iface enp0s3 inet static
    address 172.17.20.2
    netmask 255.255.255.0
    gateway 172.17.20.1

# The secondary network interface (enp0s8) with static IP
auto enp0s8
iface enp0s8 inet static
    address 10.10.20.1
    netmask 255.255.255.0
EOF

echo "Mengaktifkan Interface"
ip link set enp0s3 up
ip link set enp0s8 up

echo "✅ IP address sudah dikonfigurasi."
EOT
systemctl restart networking > /dev/null 2>&1 || error_message "${PROGRES[2]}" 

# cek ip
ip a 
# cek interenet 
echo "Mari Cek Koneksi Internet" 
ping 8.8.8.8

# Konfigurasi DHCP Server
echo -e "${YELLOW}${PROGRES[3]}${NC}"
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf' << EOF > /dev/null
subnet 10.10.20.0 netmask 255.255.255.0 {
  range 10.10.20.21 10.10.20.100;
  option domain-name-servers 10.10.20.1;
  option subnet-mask 255.255.255.0;
  option routers 10.10.20..1;
  option broadcast-address 10.10.20.255;
  default-lease-time 600;
  max-lease-time 7220;

  host Ban {
    hardware ethernet 08:00:27:78:B9:41;  
    fixed-address 10.10.20.10;
  }
}
EOF
echo 'INTERFACESv4="enp0s8"' | sudo tee /etc/default/isc-dhcp-server > /dev/null
sudo systemctl restart isc-dhcp-server > /dev/null 2>&1 || error_message "${PROGRES[3]}"

# Aktifkan IP Forwarding
echo -e "${YELLOW}${PROGRES[4]}${NC}"
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p > /dev/null 2>&1 || error_message "${PROGRES[4]}"

# Konfigurasi Masquerade dengan iptables
echo -e "${YELLOW}${PROGRES[5]}${NC}"
sudo /sbin/iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE > /dev/null 2>&1 || error_message "${PROGRES[5]}"
sudo echo 1 > /proc/sys/net/ipv4/ip_forward > /dev/null 2>&1 || error_message "${PROGRES[5]}"

# Instalasi iptables-persistent dengan otomatisasi
echo -e "${YELLOW}${PROGRES[6]}${NC}"
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections > /dev/null 2>&1
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections > /dev/null 2>&1
sudo apt install -y iptables-persistent > /dev/null 2>&1 || error_message "${PROGRES[6]}"

# Menyimpan Konfigurasi iptables
echo -e "${YELLOW}${PROGRES[7]}${NC}"
sudo sh -c "iptables-save > /etc/iptables/rules.v4" > /dev/null 2>&1 || error_message "${PROGRES[7]}"
sudo sh -c "ip6tables-save > /etc/iptables/rules.v6" > /dev/null 2>&1 || error_message "${PROGRES[7]}"

# Instalasi Expect
echo -e "${YELLOW}${PROGRES[8]}${NC}"
if ! command -v expect > /dev/null; then
    sudo apt install -y expect > /dev/null 2>&1 || error_message "${PROGRES[8]}"
    success_message "${PROGRES[8]} berhasil"
else
    success_message "${PROGRES[8]} sudah terinstal"
fi


# ====== Tambahkan ASCII Art Penutup di sini ======
echo -e "\033[1;36m" # Warna Cyan
echo "==============================================="
echo "             Konfigurasi Selesai!              "
echo "==============================================="
echo -e "\033[0m" # Mengembalikan warna default
