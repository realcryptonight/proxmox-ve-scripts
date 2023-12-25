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

git clone https://github.com/realcryptonight/debian-install-scripts.git
cd debian-install-scripts/
chmod 755 setup-standard.sh
./setup-standard.sh
cd ../

serverhostname=$(dig -x $(hostname -I | awk '{print $1}') +short | sed 's/\.[^.]*$//')
echo "webauthn: rp=$serverhostname,origin=https://$serverhostname:8006,id=$serverhostname" >> /etc/pve/datacenter.cfg

mv ./snippets/standard.yaml /var/lib/vz/snippets/standard.yaml
mv ./snippets/directadmin.yaml /var/lib/vz/snippets/directadmin.yaml

mkdir /custom-scripts/
mv ./custom-scripts/create_templates.sh /custom-scripts/create_templates.sh
chmod 755 /custom-scripts/create_templates.sh

/custom-scripts/create_templates.sh
echo "0 3    1 * *   root    /custom-scripts/create_templates.sh" >> /etc/crontab