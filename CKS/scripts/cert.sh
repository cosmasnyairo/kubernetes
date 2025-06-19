set -x

generateCACert(){
  # generate dir
  mkdir -p $1

  # generate key
  openssl genrsa -out $1.key 2048

  # generate csr
  openssl req -new -config $2 -keyout $1.key -out $1.csr

  # verify csr
  openssl req -text -noout -verify -in $1.csr

  # sign csr and generate certificate
  openssl x509 -req -in $1.csr -signkey $1.key -out $1.crt -days 365

  # view generated certificate
  openssl x509 -in $1.crt -text -noout

  # store certs in dir
  mv $1.crt $1.csr $1.key $1/

}

generateCert(){
  # generate dir
  mkdir -p $1

  # generate key
  openssl genrsa -out $1.key 2048
  
  # generate csr
  openssl req -new -config $2 -keyout $1.key -out $1.csr
  
  if [ $5 == "true" ]; then
    # use generated ca in above section and generate certificate
    openssl x509 -req -in $1.csr -CA $3 -CAkey $4 -out $1.crt  -extensions v3_req -extfile $2 -days 365
  else
    openssl x509 -req -in $1.csr -CA $3 -CAkey $4 -out $1.crt -days 365
  fi

  # view generated certificate
  openssl x509 -in $1.crt -text -noout
  
  # verify certificate
  openssl verify -CAfile $3 $1.crt

  # store certs in dir
  mv $1.crt $1.csr $1.key $1/
}
  
generateCACert cert-authority config/cert-authority.cnf

generateCert etcd config/etcd.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key true

generateCert k8sClient config/k8sClient.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key false

generateCert kube-apiserver-etcd config/kube-apiserver-etcd.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key false

generateCert kube-apiserver config/kube-apiserver.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key true

generateCert service-account config/service-account.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key true

generateCert testUser config/testUser.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key true
