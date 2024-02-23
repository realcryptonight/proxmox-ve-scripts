#!/bin/bash
#	
#	MIT License
#	
#	Copyright (c) 2023 realcryptonight
#	
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#	
#	The above copyright notice and this permission notice shall be included in all
#	copies or substantial portions of the Software.
#	
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#	SOFTWARE.

if [ -z "$1" ]; then
	pvesubscription set $1
	pvesubscription update -force
else
	sed -i 's\deb\#deb\g' /etc/apt/sources.list.d/pve-enterprise.list
	echo "# Proxmox VE pve-no-subscription repository provided by proxmox.com," >> /etc/apt/sources.list.d/pve-no-subscription.list
	echo "# NOT recommended for production use" >> /etc/apt/sources.list.d/pve-no-subscription.list
	echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list.d/pve-no-subscription.list
fi

apt update
apt -y upgrade
apt install -y figlet vim nala

echo "" >> /root/.bashrc
echo "# Use nala instead of APT as package manager" >> /root/.bashrc
echo "apt() {" >> /root/.bashrc
echo "  command nala \"\$@\"" >> /root/.bashrc
echo "}" >> /root/.bashrc
echo "sudo() {" >> /root/.bashrc
echo "  if [ \"\$1\" = \"apt\" ]; then" >> /root/.bashrc
echo "    shift" >> /root/.bashrc
echo "    command sudo nala \"\$@\"" >> /root/.bashrc
echo "  else" >> /root/.bashrc
echo "    command sudo \"\$@\"" >> /root/.bashrc
echo "  fi" >> /root/.bashrc
echo "}" >> /root/.bashrc

rm /etc/motd
mv ./files/00-header /etc/update-motd.d/
mv ./files/10-sysinfo /etc/update-motd.d/
mv ./files/10-uname /etc/update-motd.d/
mv ./files/90-footer /etc/update-motd.d/
chmod 777 /etc/update-motd.d/*

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
service sshd restart

#serverhostname=$(dig -x $(hostname -I | awk '{print $1}') +short | sed 's/\.[^.]*$//')
#echo "webauthn: rp=$serverhostname,origin=https://$serverhostname:8006,id=$serverhostname" >> /etc/pve/datacenter.cfg

pvesm set local --content snippets,iso,backup,vztmpl
pvesm set local-lvm --content images,rootdir

while [ ! -d "/var/lib/vz/snippets" ]; do
	echo "No snippets dir yet. Waiting for 5 seconds..."
    sleep 5s
done

mv ./snippets/standard.yaml /var/lib/vz/snippets/standard.yaml
mv ./snippets/directadmin.yaml /var/lib/vz/snippets/directadmin.yaml

mkdir /custom-scripts/
mv ./custom-scripts/create_templates.sh /custom-scripts/create_templates.sh
mv ./custom-scripts/backup_upload.sh /custom-scripts/backup_upload.sh
chmod 755 /custom-scripts/create_templates.sh
chmod 755 /custom-scripts/backup_upload.sh

/custom-scripts/create_templates.sh
echo "0 5    * * *   root    /custom-scripts/create_templates.sh" >> /etc/crontab