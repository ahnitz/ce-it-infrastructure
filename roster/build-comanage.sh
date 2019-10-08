#!/bin/bash -vx

git clone https://github.com/Internet2/comanage-registry-docker.git
pushd comanage-registry-docker

export COMANAGE_REGISTRY_VERSION=3.2.2
export COMANAGE_REGISTRY_BASE_IMAGE_VERSION=1

pushd comanage-registry-base
TAG="${COMANAGE_REGISTRY_VERSION}-${COMANAGE_REGISTRY_BASE_IMAGE_VERSION}"
docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
  -t comanage-registry-base:${TAG} .
popd

export COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION=1

pushd comanage-registry-shibboleth-sp-base
TAG="${COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION}"
docker build \
    -t comanage-registry-shibboleth-sp-base:$TAG . 
popd

export COMANAGE_REGISTRY_SHIBBOLETH_SP_IMAGE_VERSION=1

pushd comanage-registry-shibboleth-sp
TAG="${COMANAGE_REGISTRY_VERSION}-shibboleth-sp-${COMANAGE_REGISTRY_SHIBBOLETH_SP_IMAGE_VERSION}"
docker build \
    --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
    --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} \
    --build-arg COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION} \
    -t comanage-registry:$TAG .
popd

docker swarm init --advertize-addr $(hostname --ip-address)

echo "badgers" | docker secret create mariadb_root_password - 
echo "badgers" | docker secret create mariadb_password - 
echo "badgers" | docker secret create comanage_registry_database_user_password - 

cat /etc/grid-security/igtf-ca-bundle.crt /etc/grid-security/hostcert.pem > fullchain.cert.pem
CERT_DIR=$(mktemp -d)
sudo cp -a /etc/shibboleth/sp-encrypt-cert.pem ${CERT_DIR}
sudo cp -a /etc/grid-security/hostkey.pem ${CERT_DIR}
sudo cp -a /etc/shibboleth/sp-encrypt-key.pem ${CERT_DIR}
sudo chown ${USER} ${CERT_DIR}/*.pem
mv ${CERT_DIR}/*.pem .
sudo rmdir ${CERT_DIR}

docker secret create https_cert_file fullchain.cert.pem
docker secret create https_privkey_file hostkey.pem
docker secret create shibboleth_sp_encrypt_cert sp-encrypt-cert.pem
docker secret create shibboleth_sp_encrypt_privkey sp-encrypt-key.pem

