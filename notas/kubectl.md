# SINTAXIS 

$ kubectl VERBO TIPO-DE-OBJETO <args-opcionales>

## VERBO
- create
- delete
- logs
- apply
- get
- watch

## TIPO DE OBJETO

### Que es eso del tipo de objeto?

Hemos dicho que con Kubernetes hablamos lenguaje DECLARATIVO. 
Básicamente le damos cómo queremos que se encuentre nuestro entorno de producción.
Eso se hace mediantes Objetos de configuración.
Cargamos en kubernetes Objetos de configuración.

Kubernetes de serie trae como 20-25 tipos de objetos: Tipos de configuraciones que podemos cargar.
(hay formas de añadir nuevos TIPOS DE OBJETOS que amplien la funcionalidad del cluster. YA HABLAREMOS DE ELLO!)
                                
                                ALIAS   DESCRIPCION
- Namespace                     ns      Es una entorno aislado en el cluster con administración propia.
                                        Normalmente, cada app la montamos en un ns
                                        Podemos crear usuarios en kubernetes que solo puedan trabajar contra un ns
                                            EJ: namespace:  Nextcloud
                                                            Keycloak
                                                            OpenProject
                                        Por defecto, Kubernetes deja que las apps de un namespace hablen con las de otro ns.
                                        Pero eso se puede cortar... o limitar: NETWORK POLICY: Reglas de firewall internas al cluster

- Pod                                   Es un conjunto de contenedores... con algunas particularidades.
                                        Lo podeis ver como el equivalente a un servidor virtual... que ejecuta UNA APLICACION.
                                        Solo que ya dijimos que es MUCHO MAS LIGERO que un servidor, ya que no tiene un Sistema Operativo 
                                        Los POD tiene stestricciones de CPU, RAM, ALMACENAMIENTO
                                        Nostros nunca creamos PODS. Le damos a kubernetes PLANTILLAS de pods
                                        En base a esas plantillas, KUBERNETES va creando y borrando pods.
                                        OJO: Una plantilla de POD no es una imágen de contenedor.
                                        Una imagen de contenedor era un comprimido (tar) que lleva dentro unos programas PREINSTALADOS por el fabricante del software
                                        Pero... eso (ese PREINSTALADO) hay que adaptarlo a mi escenario:
                                            - Si tengo una BBDD, le tendré que dar mi usuario que quiero, mi password, mi nombre de BBDD
                                            - Los datos de la BBDD los quiero en éste VOLUMEN
Cómo definimos plantillas de PODs:
- Deployment                            Una plantilla de POD + Número inicial de Replicas
- Statefulset                           Un concepto un poco evolucionado de los deployments:
                                        Una plantilla de POD + Una o más plantillas de PETICIONES DE VOLUMEN + número inicial de replicas
- DaemonSet                             Una plantilla de POD de la que kubernetes hace 1 replica en cada nodo del cluster.
                                           No los usamos mucho (se usan para cosas internas de kubernetes: Monitorización, )
                                        
La decisión entre Statefulset / deployment viene marcada por el tipo de software que instalamos.

Kubernetes permite gestionar volumenes de almacenamiento con mucha FLEXIBILIDAD:
- PersistentVolume
- PersistentVolumeClaim
- ConfigMap
- Secret

Comunicaciones en un cluster de kubernetes (ES UNA LOCURA !!!!!)
- Service
- NetworkPolicy
- Ingress


- Job
- CronJob
- ResourceQuota
- LimitRange
- HorizontalPodAutoScaler

El opbjetivo es comenzar a entender la NOMMENCLATURA DE KUBERNETES, qué significan esas cosas.


## args-opcionales

-n  --namespace     NAMESPACE       Limita el comando a un namespace concreto
-A  --all-namespaces                Aplica el comando a todos los namespaces que el usuario que conecta tenga acceso


---

# Deployments / Statefulsets

## Nextcloud
    
    MARIADB1    \                  /    Instancia 1 nextcloud:                              \
                 \                /         Apache httpd + php + programas de nextcloud      \
    MARIADB2      - BALANCEADOR <                                                             -     BALANCEADOR  > PROXY REVERSO
                 /               \      Instancia 2 nextcloud:                               /
    MARIADB3    /                 \         Apache httpd + php + programas de nextcloud     /
                    
Preguntas:
- Donde guardan los MariaDBs los ficheros de la BBDD? En un volumen de almacenamiento
- Donde guardan los Nextcloud los ficheros que subimos a nextcloud? En otro volumen de almacenamiento

Ahora bien... tengo:
3 MariaDB: Cada mariaDB tiene su volumen o comparten uno entre todas las instancias? CADA UNO EL SUYO
    -> STATEFULSET: PLANTILLA DE POD + número de replicas + PLANTILLAS DE PETICIONES DE VOLUMENES. 
            Porque al crear cada POD(instancia), kubernetes necesita crear también un VOLUMEN adhoc para ese pod concreto... 
            Por eso que hay que dar una PLANTILLA DE VOLUMEN
2 Instancias de Nextcloud: Cada nextcloud tiene un un volumen propio o comparten todos el mismo volumen? COMPARTIDO OBLIGATORIO
    -> DEPLOYMENT: PLANTILLA DE POD (podré poner 1 volumen, o 17, que serán compartidos entre todos los pods) + número de instancias 

En todos los programas(aplicativos) que guarden datos como: BBDD, indexadores(elastic), sistemas de mensajería (KAFKA) cada instancia requiere su volumen.
Las aplciaciones web, servicios web.,.. etc. Comparten volumen entre todas sus instancias.

> Ejemplo de configuración en kubernetes, pero en lenguaje humano, tal y como se lo pedría a Vicente!
- Kubernetes, quiero de 2 a 4 instancias de Nextcloud, que usen el volumen 001982837 de la cabina para guardar los ficheros.
- Kubernetes, quiero de 3 a 5 instancias del MariaDB, donde cada instancia tenga un volumen de 8Gbs en la cabina.
                                                                                            ---------------------
                                                                                             PLANTILLA DE VOLUMEN
                                                                                             
# Volúmenes en kubernetes:
(Para cada uno de esos usos, kubernetes define distintos tipos de volumenes / OBJETOS de CONFIGRUACION)

Para qué usan los contenedores VOLUMENES DE ALMACENAMIENTO?
- Para poder compartir datos con otros contenedores:            NGINX -> access.log <- AGENTE BEATS de monitorización       EMPTYDIR
                                                                 C1                      C2

- Para inyectar ficheros al contenedor: 
    - Archivos de configuración                                                                                             CONFIGMAP
    - Certificado                                                                                                           SECRET

- Para guadar persistentemente los datos de una app             MARIADB -> Ficheros de la BBDD                              PERSISTENT VOLUME CLAIM pvc
    Aquí se complica la paleleta.... MUCHO !                                                                                PERSISTENT VOLUME       pv

Los datos persistentes, se guardarán en un volumen que esté donde?
- CABINA NFS
- CABINA FIBRE CHANNEL
- CLOUD
- ISCSI
- ... hay muchos soportes físicos donde tener al final un volumen

Kubernetes está pensado para que sea usado por múltiples TIPOS de usuarios.
Imaginad este escenario. Os llega un equipo ajeno a vosotros... y os dice: 

> Queremos instalar una app en vuestro cluster. 
1. Les creo un Namespace propio para desarrollo y producción para ellos.
2. Les creo un usuario para ellos
3. Ellos querrán montar por ejemplo una BBDD... y para ello necesitarán un VOLUMEN de almacenamiento.
   Qué tipo de información me darán?
   - Quiero que tenga 50Gbs
   - Quiero almacenamiento redundante / o no... es para datos de mierda.. y no vamos a usar tanto disco
   - Quiero un volumen ENCRIPTADO
   Pregunta... ellos me van a decir, que el volumen debe estar en una cabina o en otra? NOMMENCLATURA
   O que el volumen debe estar montado por icsi o por fibrechannel? NI DE COÑA
   Es más... ellos necesitan saber el ID del volumen en la cabina? NO. NI DEBEN SABERLO !
   O si la cabina necesita contraseña para dejar acceder al volumen
   
   Tenemos un problema de división de RESPONSABILIDADES
   
   Para ello Kubernetes tiene 2 tipos de OBJETOS DE CONFIGURACION:
   - PERSISTENT VOLUME CLAIM: Peticion de volumen persistente
        Aquí se configura una PETICION:PVC11111                    (ESTO ES RESPONSABILIDAD DE QUIEN CONFIGURA LA APLICACION A DESPLEGAR)
            - Quiero 50 Gbs         
            - Rapiditos y redundantes
   - PERSISTENT VOLUMEN: Volumen persistente (referencia a un volumen físico existente en algún sitio, p ej. cabina)
        Aquí se configura UN VOLUMEN CONCRETO:    
            Volumen 001928 -> Cabina Huawei: 192.168.10.20, con el ID 10292837298274
        Quién tiene potestad para hacer o crear esta configuración (ADMINISTRADOR DEL CLUSTER de KUBERNETES = VOSOTROS)
        Aquí también se define que características que tiene ese volumen:
            El volumen 001928 es de 100Gbs rapiditos y redundantes

    Y KUBERNETES HACE MATCH... es el tinder de los volumenes.
    
    Kubernetes se pregunta... ummm. Tengo a un tio pidiendo un volumen de 50Gbs rapidito y redundante
        No tendré por ahí que me hayan configurado algún volumen real que satisfaga esa necesidad?
        
        En este caso, encuentra match? SI!
        Se asocia esa petición de volumen: PVC11111 <-> volumen 001928
        
        A esa persona se le entregan 100Gbs... No 50!
        
        Yo kubernetes, ese volumen 001928 ya te lo he entregado a ti... y ya no se lo entego a nadie más. QUEDA CONSUMIDO!
    
    Otra cosa, es, que haces tu, usuario que quiere montar una app en mi cluster con ese volumen...
    Quizás quieres compartirlo entre 5 PODs. Lo que asocias a los 5 PODS es la PETICION DE VOLUMEN
    
    PLANTILLA DE POD <-> PETICION DE VOLUMEN <-> VOLUMEN
          |
          v
        Pod 1 \ 
        Pod 2  -> PETICION DE VOLUMEN <-> VOLUMEN
        Pod 3 / 
        
    Imaginad que el día de mañana, creamos un pod nuevo:
        Pod 4 -> PETICION DE VOLUMEN <-> VOLUMEN
    
> Ejemplo en humano:
Oye, que quiero montar un nextcloud.
 (Necesito un volumen de 50 Gbs= PETICION) ---> (Internamente eso se asociará a un VOLUMEN)
A todas las instancias que me generes del nexcloud (entre 2 y 10, en base a la carga de trabajo) asociales ese volumen que me has dado.


> Oye voy a instalar Nextcloud y mariab
>> Quiero un volumen de tipo A: 50Gbs rapiditos y encriptados
>> Quiero un volumen de tipo B: 10 Gbs rapiditos
>> Montame 4 maquinas virtuales para nextcloud, a las que les pones el volumen de tipo A
>> Montame 3 Maquinas virtuales para marioadb... a cada una le pones un volumen de tipo B

Los volumenes quien los crea hemos dicho? El administrador de sistemas... 
Pero esto no se trataba de AUTOMATIZAR? Que coñazo... andar creando volumenes... uff que pereza!

Aquí entra otro concepto: PROVISIONADOR DINAMICO DE VOLUMENES 

Dentro de un cluster, siempre se monta al menos UN provisionador dinamico de volumenes. En vuestro caso teneís un provisionador llamado: NFS-subdir-provisioner
Cada vez que alguien hace una PETICION DE VOLUMEN, el provisionador CREA en automático un volumen que satisface los detalles de esa petición. 
Eso se hace bajo demanda, en automático... 
El que teneis vosotros, lo que hace es en la caprta que compartís por nfs, crea un subdirectorio y monta en el pod que haya hecho la petición la subcarpeta del NFS.
En vuestra cabina teneis un solo volumen para PRODUCCION.
Pero dentro hay muchas subcarpetas: 
- mariadb
- nextcloud
- keycloak
- ...

Kubernetes solo le deja ver a cada pod su SUBCARPETA! nada más.

De forma que el administrador de sistemas no va creando VOLUMENES... su trabajo fue configurar un PROVISIONADOR DE VOLUMENES

# COMUNICACIONES EN UN CLUSTER DE KUBERNETES
    
                                                                                 
        192.168.20.10:80->  192.168.20.131:30001 | 192.168.20.132:30001 | 192.168.20.133:30001
                |                                                                                            
            BALANCEADOR DE CARGA                            nextcloud=192.168.20.10                      Chrome: http://nextcloud (1)
                |                                            |                                             |
            192.168.20.10                                   DNS EXTERNO                                  JOSERRA_PC
                |                                            |                                             |
+---------------+--------------------------------------------+---------------------------------------------+------ red : 192.168.20.0/16
|
+== 192.168.20.131 - Maquina 1 - Maestro
||                       |
||                       +- Netfilter (Programa del kernel de linux que controla cada paquete que pasa por cualquier red en esa máquina)
||                       |      Regla: 10.10.10.1 -> 10.10.0.2
||                       |      Regla: 10.10.10.2 -> 10.10.0.1 ... y el resto de pods de nginx que haya en cada momento
||                       |      Regla: 10.10.10.3 -> 10.10.0.3 ... y el resto de pods de nextcloud que haya en cada momento
||                       |      Regla: 192.168.20.131:30001 -> 10.10.10.2:80 
||                       |       ^^^
||                       |- KubeProxy
||                       +- 10.10.1.100 - CoreDNS
||                                          mariadb   => 10.10.10.1 (ESTO ES UNA IP DE BALANCEO GENERADA POR KUBERNETES)
||                                          nginx => 10.10.10.2 (ESTO ES UNA IP DE BALANCEO GENERADA POR KUBERNETES)
||                                          nextcloud => 10.10.10.3 (ESTO ES UNA IP DE BALANCEO GENERADA POR KUBERNETES)
||
+== 192.168.20.132 - Maquina 2 - Nodo reservado para nextcloud
||                       |
||                       +- Netfilter (Programa del kernel de linux que controla cada paquete que pasa por cualquier red en esa máquina)
||                       |      Regla: 10.10.10.1 -> 10.10.0.2
||                       |      Regla: 10.10.10.2 -> 10.10.0.1 ... y el resto de pods de nextcloud que haya en cada momento
||                       |      Regla: 192.168.20.132:30001 -> 10.10.10.2:80 
||                       |      Regla: 10.10.10.3 -> 10.10.0.3
||                       |       ^^^
||                       |- KubeProxy
||                       +- 10.10.0.1 - Pod Proxy REVERSO - INGRESS CONTROLLER: nginx
||                       |                      Regla de proxy reverso: INGRESS
||                       |                          Cuando se haga una petición usando como nombre: nextcloud (1), redirige a : nextcloud:08
||                       +- 10.10.0.3 - Pod NC - Contenedor de Nextcloud
||                                                   Apache 10.10.0.1:80
||                                                       nextcloud.conf (BBDD_URL = mariadb:3306)
||
+== 192.168.20.133 - Maquina 3 - Nodo reservado para mariadb
|                       |
|                       +- Netfilter (Programa del kernel de linux que controla cada paquete que pasa por cualquier red en esa máquina)
|                       |      Regla: 10.10.10.1 -> 10.10.0.2
|                       |      Regla: 10.10.10.3 -> 10.10.0.3
|                       |      Regla: 10.10.10.2 -> 10.10.0.1 ... y el resto de pods de nextcloud que haya en cada momento
|                       |      Regla: 192.168.20.133:30001 -> 10.10.10.2:80 
|                       |       ^^^
|                       |- KubeProxy
|                       +- 10.10.0.2 - Pod BBDD - Contenedor de MariaDB
|                                                   Servidor mariadb 10.10.0.2:3306


En el fichero de configuración de nextcloud (nextcloud.conf) pondremos la ruta a la BBDD, para que NC pueda conectar con MariaDB
Qué pongo?
    BBDD_URL = 10.10.0.2:3306 ? Funcionaría? SI
                                Lo haría alguna vez en la vida? NI DE COÑA !!! NUNCA JAMÁS
                                Problemas de esta configuración?
                                - Y si añado más BBDD? problemón
                                - Y si Kubernetes decide que ese pod de mariadb lo tiene que mover a otra máquina porque el servidor 3 se ha caído?
                                    Kubernetes crea un nuevo pod... pero con otra IP = RUINA !
                                - A priori se que IP le va a poner Kubernetes a ese Pod de MariaDB? NO... Follón:
                                        Entonces, tengo que desplegar primero el MAriaDB, ver su IP,... y luego configurar el nextcloud y luego desplegarlo? VAYA TELA !
                                        
Lo primero, necesito ser capaz de llamar desde el nextcloud a la BBDD mediante un fqdn (resoluble por DNS):
    nextcloud.conf
        BBDD_URL = mariadb:3306
        
Nos hace falta un BALANCEO DE CARGA: En kubernete spodemos crear una IP DE BALANCEO... OJO CUIDADO NOTA IMPORTANTE!!!!!
    No es un balanceador de carga al uso (un nginx... un apache... un haproxy...) TAN SOLO ES UNA IP DE BALANCEO
    Le puedo pedir a kubernetes una IP de balanceo, asociada a ese nombre DNS... que la genere él.
        Kubernetes dice: En el DNS doy de alta: mariadb: 10.10.10.1
    Esa IP la registra automaticamente kubernetes en cada host(nodo del cluster)... el su netfilter.
    Cómo hace eso? Kube-proxy
    
Para hacer este trabajo, definimos en Kubernetes un SERVICE:
Un service de kubernetes es:    UNA IP DE BALANCEO INTERNA GENERADA POR KUBERNETES y exportada a los netfilter de cada nodo por kube-proxy 
                                + ENTRADA EN EL DNS DE KUBERNETES apuntando a esa IP
                                Y kubernetes se encarga de ir actualizando la regla de los netfilter añadiendo 
                                las IPS de todos los PODs que se vaya creando de un determinado TIPO
                                
Kubernetes ofrece 3 tipos de servicio:
- CLUSTER IP = (lo que os había contado arriba)  UNA IP DE BALANCEO INTERNA GENERADA POR KUBERNETES y exportada a los netfilter de cada nodo por kube-proxy 
                                                + ENTRADA EN EL DNS DE KUBERNETES apuntando a esa IP
- NODE PORT = CLUSTER IP + Exposición de la IP DE BALANCEO en un puerto por encima del 30000 en cada nodo del cluster

- LOAD BALANCER = NODE PORT + Configuración automática de un balanceador de carga externo COMPATIBLE con Kubernetes
                    Si contrato un kubernetes en cualquier CLOUD: AWS, GOOGLE, AZURE... me regalan un balanceador compatible con kubernetes
                    Pero no es nuestro caso. Donde el cluster lo estamos montando on premise (en nuestras instalaciones) desde cero.
                    Y solo hay 1 balanceador compatible con kubernetes: METAL LB


PROBLEMA: Quien se come la configuración del BALANCEADO EXTERNO? y DEL DNS EXTERNO? Nosotros a manita!
Y esto no iba de AUTOMATIZAR? Aquñi entra el TERCER TIPO DE SERVICIO

Hay una cosa aún que estamos haciendo a mano: La configuración del DNS Externo.
Kubernetes no trae nada para ello..
Pero hay un proyecto oficial que nos lo permite gestionar contra una serie de servidores DNS comerciales

---

En un cluster tipo de kubernetes, cuánto servicos de cada tipo pensais que vamos a tener (%)

                            %
    CLUSTER_IP              TODOS           Comunicaciones internas
    NODE_PORT               0               Comunicaciones externas
    LOAD_BALANCER           1               Comunicaciones externas (config automatica del BC externo)
    
    