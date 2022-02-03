sudo -i 
yum install -y git yum-utils wget openssl
git clone https://github.com/lscalabrini/deploy-harbor.git
cd deploy-harbor
yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce
systemctl enable --now docker
curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose

## Change the version accordingly
wget https://github.com/goharbor/harbor/releases/download/v1.10.10/harbor-online-installer-v1.10.10.tgz
#
## Extract the downloaded file
tar xvf harbor-online-installer-v1.10.10.tgz

# GENERATE CERTIFICATES
# 1. Generate CA private key
openssl genrsa -out ca.key 4096

# 2. Generate CA certificate (Change the values accordingly)
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Colombo/L=Colombo/O=Organization/OU=Personal/CN=harbor-registry.com" \
 -key ca.key \
 -out ca.crt
 
# 3. Generate server certificate(Change the values accordingly)
openssl genrsa -out harbor-registry.com.key 4096

# 4. Generate certificate signing request(Change the values accordingly)
openssl req -sha512 -new \
    -subj "/C=CN/ST=Colombo/L=Colombo/O=Organization/OU=Personal/CN=harbor-registry.com" \
    -key harbor-registry.com.key \
    -out harbor-registry.com.csr
    
# 5. Generate an x509 v3 extension file.(Change the values accordingly)
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=harbor-registry.com
DNS.2=harbor-registry
DNS.3=host-name
EOF

# 6. Use above file to generate certificate.(Change the values accordingly)
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in harbor-registry.com.csr \
    -out harbor-registry.com.crt

# 7. Provide the certificates for Harbor.
mkdir -p /data/cert
cp harbor-registry.com.crt /data/cert/
cp harbor-registry.com.key /data/cert/

# 8. For docker to use this cert we need to convert .crt to .cert. Then we need to move them to the appropriate folder.
openssl x509 -inform PEM -in harbor-registry.com.crt -out harbor-registry.com.cert
mkdir -p /etc/docker/certs.d/harbor-registry.com
cp harbor-registry.com.cert /etc/docker/certs.d/harbor-registry.com/
cp harbor-registry.com.key /etc/docker/certs.d/harbor-registry.com/
cp ca.crt /etc/docker/certs.d/yourdomain.com/

# 9. Restart docker
systemctl restart docker

# DEPLOY HARBOR
cd harbor
modificar config.yaml

./prepare

docker-compose up -d











