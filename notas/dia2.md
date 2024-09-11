Introducción a kubernetes
- Contenedores
    Se crean desde imágenes de contenedor.
    Las imágenes se sacan de Registros de Repositorios de Imagenes de Contenedor
- Pod
- Apto para entornos de producción (HA/Escalalibilidad)
- Usamos lenguaje declarativo (ficheros YAML) pra configuraciones.
- Introducción arquitectura/componentes de kubernetes

Instalación de kubernetes
- Paso1: Preparar sistema:
        - Desactivar swap
        - Configuraciones requeridas por el gestor de contenedores:
            - Activar 2 módulos del kernel de Linux y configurarlos
        - Instalar un gestor de contenedores: CRIO | Containerd
- Paso2: Instalar las herramientas base de kubernetes en el primer/único nodo maestro:
    - kubelet: Es un servicio (instalado a hierro) en todos los nodos del cluster
               Permite a kubernetes gestionar los gestores de contenedores de cada nodo: CRIO / CONTAINERD   
               Se configura con arranque automatico en los servidores
    - kubeadm: Gestiona clusters: Permite crear/borrar/configurar | Agregar/quitar nodos al cluster
    - kubectl: Cliente para mandar ORDENES (IMPERATIVO) a un cluster (API SERVER)
               Alternativa es Kubernetes Dashboard (Tratamos de no usarlo mucho)
- Paso 3: Crear un cluster (de un nodo): kubeadm init
    - Se crean montón de contenedores con los programas base de kubernetes (PLANO DE CONTROL):
        - Api server
        - Etcd
        - CoreDNS
        - Scheduller
        - Control Manager
        - ...
- Paso 3.5: Disponer de un cliente con el que conectar al cluster -> Ya lo tenemos kubectl
            Hay que configurarlo para acceso a nuestro cluster
- Paso 4: Montar una red virtual. 
          Esa red se crea mediante programas que se instalan dentro del cluster como contenedores
- Paso 5: Disfrutar de kubernetes
          En la práctica, montamos muchas más cosas... Lo completamos con "plugins"
          Montamos programas que vayan aumentando la funcionaldiad del cluster:
            - Dashboard
            - Metric server
            - Prometheus/Grafana (monitorización)
            - CertManager (Generar certificados SSL públicos)
            - ISTIO (Generar certificados SSL privados y securizar completamente un cluster)
            - ...
---

# Registros de Repositorios de Imagenes de Contenedor

El más famoso es Docker Hub
Microsoft Container Registry
Oracle Container registry
Quay.io (Redhat)

---

Prometheus      /   Grafana
   ||                 ||
ElasticSearch   /   Kibana


Son herramientas un poco alternativas... aunque llevan enfoques algo diferentes.
Elastic se unió después a la fiesta! Prometheus/Grafana llevan más años en el mercado.
Posiblemente Elastic es más potente... pero prometheus / grafana está más implantado.

En concreto para monitorizar clusters de kubernetes y herrmamientas internas: Prometheus/Grafana

Para monitorizaciones más customizadas (particulares/personalizadas) solemos usar Elastic + Kibana + Logstash + Agente Beats:
    - Métricas
    - Logs de forma muy avanzada
Pero para monitorizar métricas de productos comerciales, suele usarse más Prometheus

---

El fabricante siempre ma da una IMAGEN DE CONTENEDOR (Producto, el programa).

Pero... una cosa es el programa y otra, una instalación en un entorno productivo, que requiere de:
 - dependencias
 - volumenes
 - balanceadores de carga
 - proxy reversos
 - autoescaladores
 - SISTEMAS DE MONITORIZACION (Integración con prometheus grafana)
 - ...

> EJEMPLO PRACTICO: INSTALACION DE NEXTCLOUD

El fabricante me da la imagen de NEXTCLOUD: Básicamente es un ZIP(tar) que lleva dentro:
- una instalación de APACHE HTTPD Server
- Soporte para lenguaje PHP
- los programas php de Nextcloud

PERO, para instalar eso en producción, necesito decenas de cosas más a tener en cuenta:
- BBDD - MariaDB (Replicación, cluster activo/activo / Standalone????)
- Volumenes:
    - Nextcloud
    - BBDD
- Configuración concreta de mi instancia de nextcloud (servidor de corro, logs)
- Politica de escalado (1 instancia... 10 instancias)
- Reglas de red de firewall
- Balanceador de carga
- Proxy reverso
- Monitorización
- ...

ESTO ES LO QUE LOS FABRICANTES METEN EN LOS CHARTS DE HELM: Plantillas de despliegues

Los charts de helm, los encontramos en: https://artifacthub.io/

---

HOY EN DIA, TODO ESTA MUY AUTOMATIZADO... poco trabajo manual hay que hacer ya: DEVOPS!

Kubernetes
    Prometheus/Grafana
    Programas < - Charts de HELM
                        ^
                        |
                    Playbooks de Ansible
                        ^
                        |
    AWX - Ansible Tower (versión opensource gratuita)
      ^
      |
    JENKINS
        Formulario en Jenkins < - Certificado
        

Backups!
Actualización a una nueva versión de Nextcloud y cualquier otro programa


AWX lo que hace es lanzar trabajos (procesos ansible) en segundo plano.
- En que ENTORNO se ejecutan esos trabajos. Si lo tienes montado a hierro, es la misma máquina donde se ejcutan los procesos Ansible.
- Si uno se queda colgao... A tomar por culo el chiringuito

AWX al instalarse en Kubernetes (que es la UNICA FORMA SOPORTADA HOY EN DIA), cada trabajo lo ejecuta dentro de un 
contenedor(POD) creado adhoc para ese trabajo... que es eliminado tan pronto el trabajo finaliza.

JENKINS hace lo mismo al estar en un kubernetes.

---

Opciones para vosotros:

OPCION I:
    
    1- Cluster de Kubernetes propio de Sistemas
        Prometheus/Grafana
        Elastic ELK
        AWX (Ansible Tower). ---------------->     Máquinas que tenga fuera del cluster (solo tiene que haber una regla adecuada)
        JENKINS
        Keycloak    ------------------------->     ActiveDirectory
            - Nextcloud
            - VPN
        
    2- Cluster para aplicaciones I
        Nextcloud
        Jitsi
        ...
    
    3- Cluster para aplicaciones II
        Openproject
        ...

OPCION II:
    
    1- Cluster de Kubernetes para todo
        Prometheus/Grafana
        Elastic ELK
        AWX (Ansible Tower). ---------------->     Máquinas que tenga fuera del cluster (solo tiene que haber una regla adecuada)
        JENKINS
        Keycloak    ------------------------->     ActiveDirectory
            - Nextcloud
            - VPN
        Nextcloud
        Jitsi
        Openproject
        ...
        
---

Vosotros ahora mismo teneis Active Directory de Microsoft en un servidor (en varios) que no están en kubernetes
Y también teneís KeyCloak... dentro de kubernetes... que se comunica con esos ActiveDirectory

---

Una de las grandes ventajas de montar un cluster de kubernetes es la optimización de recursos (HARDWARE)

Antaño, si quería montar HA / escalabilidad para una app:
- Cluster App1
    - Máquina 1 - App1 - 45% CPU    \
    - Máquina 2 - App1 - 55% CPU    / BALANCEADOR DE CARGA
    - Máquina 3 
    Necesito otra máquina o estoy bien? Si una máquina se cae... la otra no es capaz de absorber toda la carga de trabajo-.
    - Máquina 1 - App1 - 33% CPU    \
    - Máquina 2 - App1 - 33% CPU    / BALANCEADOR DE CARGA
    - Máquina 3 - App1 - 33% CPU

    Tengo 3 máquinas al 33%... Vaya despilfarro.
    - Máquina 1 - App1 - 5% CPU
    - Máquina 2 - App1 - 5% CPU
    Tengo 2 máquinas al 33%... Vaya despilfarrón!!!

Y ahora multiplica por 20 apps. Donde cada app tiene sus máquinas de reserva para conseguir la HA

En un entorno kubernetes:
Cluster 20 nodos y dejo 2 nodos de reserva (3 nodos...)

Qué probabilidad hay de que 3 máquinas tengan a la vez problemas!
Esas máquinas las dejo de comodín para TODAS LAS APLCIACIONES.
Si se cae la máquina donde está app1 -> máquina de reserva
Si se cae la máquina donde está app17 -> misma máquina de reserva

Las máquinas de reserva son compartidas.

---

Apps para intranet - Cluster 1
Apps para internet - Cluster 2

Teneís apps mixtas? Cuando digo mixtas, no me refiero a que tenga 2 instalaciones independientes.
Me refiero a que tenga acceso desde internet e intranet

---
Mover cosas de un cluster 1 a un cluster2:
2 opciones:
Opción 1:
- Reinstalar la app en el cluster contrario.
  El concepto de mover es un concepto mentiroso. No existe realmente el concepto MOVER. 
    Los conceptos que existen son: BORRAR y CREAR

- Ejecutar playbook.
Opción 2:
- Kubernetes no la soporta de forma nativa... aunque hay addons que lo permiten.
- Pero hay distribuciones de kubernetes (que teneis que empezar a explorar) que si:
    - CLUSTERS FEDERADOS, que me permiten hacer movimiento de recursos en automático de un cluster a otro.

Distribuciones de kubernetes: KUBERNETES tampoco es ni un programa, ni una colacción de programas.
ES UN ESTANDAR!

Y hay muchas implementaciones de ese estandar:
- K8S: Es una implementación completa de kubernetes OPENSOURCE y GRATUITA
- K3S: Es una implementación en miniatura de kubernetes.. para usos concretos (IoT)
- Openshift: Distro de Kubernetes de REDHAT (que amplia muchisisismo las funcionales de Kubernetes)
- Tamzu!
 
Sabeís qquien es la empresa má famosa a nivel mundial por la calidad de las imagenes de contenedor y 
las plantilals de despliegue (charts de helm) que produce: BITNAMI

BITNAMI es una empresa de SEVILLA!!! que se han vuelto millonarios!
En su momento le metió pasta VMWARE.
Hoy en día la han comprado... por un dineral!

Al montar un cluster de kubernetes con TAMZU, lo que ocurre es que hay integración directa entre el cluster y VMWare.
En un momento puedo escalar el cluster y en automático se toman máquinas de VMWare virtuales a las que se les instala SO, Kubernetes... 
se configuran y se integran al cluster a golpe de BOTON DERECHO.
Y también permite el definir clusters paralelos, pero federados.

Esa misma funcionalidad se puede conseguir a mano... gratis... pero con horas de trabajo!

---

Metodologías ágiles!
Va en contra de las metodologías tradicionales!

Antaño, el día 1 nos comíamos mucho la cabeza, con la mejor decisión posible!

---

CLUSTER INTERNO
    |
    v
    Buscar una forma de automatizar este trabajo de migrar cosas de uno a otro.
    ^
    |
CLUSTER EXTERNO

---

OpenStack : CLOUD PRIVADO:
    - Montar MV (como en VMWare)
    - Montar unidades de almacenamiento compartidas en red (Ficheros, Bloques) (como en VMWare)
    
    Alternativa a VMWare ... pero más potente

Openstack se integra con kubernetes: BIDIRECCIONALMENTE
Puedo montar un cluster Openstack sobre kubernetes
O puedo montar un cluster de kubernetes sobre Openstack

---

Kubectl es un cliente de kuberntes.
NO NECESITA ESTAR INSTALADO EN EL CLUSTER
Lo puedo instalar en cualquier máquina fuera del cluster.
Lo único que necesito es hacer llegar a esa máquina (copiar) el fichero de config de la conexión: .kube/config

---

Al trabajar con servidores virtuales, los servidores virtuales son algo que creamos y mantenemos mucho en el tiempo.
Creo un servidor... y ahí se queda hasta que dentro de 5 años, ya no haga falta.

Con los pods (contenedores) el concepto cambia mucho.
De entrada cuantos pods pensaís que nosotros vamos a crear en kubernetes? NINGUNO
Nosotros no creamos PODs. Los PODS los crea Kubernetes.
Nosotros SI CREAMOS MAQUINAS VIRTUALES
Nosotros lo que haremos será decirle a Kubernetes: Quiero en todo momento de 2 a 5 pods con ésta configuración.
Kubernetes será quien vaya CREANDO o BORRANDO pods... O "moviendolos" entre máquinas a su conveniencia.
Y Kubernetes crea y borra pods con una alegria pasmosa.
