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

# Instalasi ISC DHCP SERVER
echo -e 

# ====== Tambahkan ASCII Art Penutup di sini ======
echo -e "\033[1;36m" # Warna Cyan
echo "==============================================="
echo "             Konfigurasi Selesai!              "
echo "==============================================="
echo -e "\033[0m" # Mengembalikan warna default
