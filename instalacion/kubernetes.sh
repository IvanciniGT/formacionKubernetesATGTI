# Preparativos

## Desinstalar Docker ya que, en este caso, viene preinstalado en el sistema
sudo apt purge docker-ce -y
sudo apt purge containerd.io -y
sudo apt autoremove -y
## Desactivar la swap. Kubernetes no admite el uso de swap.
sudo swapoff -a # Desactivamos la swap en la sesión actual.
### Al reiniciar la máquina, la swap volvería a activarse. Para evitarlo, deshabilitamos su configuración en el fichero fstab, que es el que declara la activación de la swap durante el arranque del sistema.
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
## La máquina que nos proporciona AWS tiene un disco duro (HDD) muy pequeño por defecto, por lo que necesitamos expandir su tamaño.
sudo growpart /dev/nvme0n1 1
sudo resize2fs /dev/nvme0n1p1
## Instalamos el gestor de contenedores que Kubernetes usará: CRIO.
### CRIO tiene dependencias que deben instalarse previamente.
sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y
### CRIO requiere que ciertos módulos de kernel estén activos, necesarios para el manejo de la red virtual de los contenedores.
sudo su -
echo "overlay" > /etc/modules-load.d/k8s_crio.conf 
echo "br_netfilter" >> /etc/modules-load.d/k8s_crio.conf
### Instalamos CRIO. El primer paso es dar de alta los repositorios de CRIO en Ubuntu para apt.
### Definimos las versiones de CRIO y Kubernetes que queremos utilizar.
export OS=xUbuntu_22.04
export CRIO_VERSION=1.27
export kubernetes_version=1.30.0

### Añadimos los repositorios y las claves necesarias para instalar CRIO.
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list
apt update # Actualizamos la lista de repositorios para que apt reconozca el nuevo software.

### Ahora estamos listos para instalar CRIO.
apt install cri-o cri-o-runc -y
apt install cri-tools -y

### Creamos un fichero de configuración para CRIO, donde configuramos las reglas necesarias para la red virtual de los contenedores.
echo "net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-ip6tables=1" > /etc/sysctl.d/k8s_crio.conf
sysctl -p /etc/sysctl.d/k8s_crio.conf # Aplicamos la configuración del sistema de red.

### Reiniciamos y activamos el servicio de CRIO, luego verificamos que esté funcionando correctamente.
systemctl enable crio
systemctl restart crio
### Verificamos el estado del servicio para confirmar que todo está funcionando correctamente.
crictl info
### Salimos del usuario root para continuar con el siguiente paso.
exit

# Instalación de Kubernetes
## Vamos a instalar tres componentes principales: kubelet, kubeadm y kubectl.
## Lo primero es añadir los repositorios necesarios para la instalación.
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update

## Instalamos Kubernetes.
sudo apt install kubelet kubeadm kubectl -y

## NOTA: Hasta este punto, estos pasos se repetirían en todas las máquinas del clúster que queramos crear.

# Creación de un clúster de Kubernetes: Esto se ejecuta solo en un nodo que tendrá el rol de control-plane (nodo maestro).
sudo kubeadm init --pod-network-cidr "10.10.0.0/16" --upload-certs

## Copiamos el archivo de configuración del clúster a nuestra carpeta de usuario para que kubectl lo detecte y podamos comenzar a interactuar con el clúster.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instalación de componentes adicionales

## Instalamos el controlador de red para los pods. En este caso, elegimos Calico como solución de red.
wget https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
kubectl apply -f calico.yaml

## En un entorno de producción real, no deberíamos hacer lo siguiente:
# Kubernetes no permite que los nodos que albergan el control-plane ejecuten otros tipos de cargas de trabajo (programas).
# En este caso, solo tenemos un nodo. Si no permitimos que el control-plane ejecute otros programas, no podríamos alojar cargas en él, ya que no tenemos más nodos.
kubectl taint node --all node-role.kubernetes.io/control-plane-

## Instalamos el dashboard gráfico de Kubernetes, que es una herramienta oficial pero que no se despliega automáticamente.
### Esta herramienta es útil para monitorear el estado del clúster. Sin embargo, nunca debemos usarla para hacer cambios en un entorno de producción.

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Añadimos el repositorio del dashboard de Kubernetes.
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

# Editamos el servicio del dashboard para convertirlo en un servicio de tipo NodePort y permitir que se pueda acceder desde fuera del clúster.
kubectl -n kubernetes-dashboard edit service/kubernetes-dashboard-kong-proxy

# Desplegamos una release de Helm para el dashboard de Kubernetes.
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

## Creamos un usuario para acceder al dashboard.
kubectl apply -f curso/instalacion/usuario-dashboard.yaml

## Obtenemos el token (contraseña) generado automáticamente para el usuario que hemos creado:
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d

## Instalamos el servidor de métricas (Metric Server), un componente oficial de Kubernetes que captura métricas de uso de CPU y RAM de los pods y contenedores.
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl apply -f components.yaml
