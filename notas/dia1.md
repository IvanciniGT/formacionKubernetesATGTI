# Kubernetes

Es una herramienta que controla entornos de producción.
Hace toda la operación de un entorno de producción con HA / Escalabilidad.

## HA: Alta disponibilidad

Tratar de garantizar un determinado tiempo de actividad.

## Escalabilidad

Capacidad de ajustar la infra para las necesidades de la aplicación en cada momento.


Tradicionalmente la operación de los entornos de producción se hacía de forma manual, por los administradores de sistemas.
Hoy en día, Kubernetes es la herramienta más popular para hacer esto de forma automatizada.

Difiere mucho de herramientas como VMWare, que es una herramienta a través de la cual nosotros hacemos operaciones:
- Crear un servidor
- Arrancar o parar un servidor
- Crear una red

Kubernetes es muy diferente... porque es él quien se encarga de hacer esas cosas.
Kubernetes es quien se encarga de:
- Crear un contenedor(el equivalente a un servidor)
- Arrancar o parar un contenedor
Como administradores de sistemas, lo que le damos a kubernetes son INSTRUCCIONES acerca de cómo queremos que se comporte nuestro entorno de producción.

Pensar en Kubernetes como si fuera un compañero más del equipo.
Un compañero que trabaja 24x7.
Y hará lo necesario ( o hará su mejor esfuerzo) para conseguir que el entorno de producción cumpla con las instrucciones que le hemos dado.

Con KUBERNETES hablamos usando un lenguaje DECLARATIVO.... a diferencia de otras herramientas con las que usamos un lenguaje IMPERATIVO.

### Lenguaje imperativo vs Lenguaje declarativo

-> Federico, pon una silla debajo de la ventana. ESTO ES UNA FRASE EN IMPERATIVO

Todos los comandos de linux/windows son imperativos: SON ORDENES que damos a la computadora.
- cd : change directory. ESTO ES IMPERATIVO
- mkdir: make directory. ESTO ES IMPERATIVO

Estamos muy acostumbrados a usar lenguaje imperativo con las computadoras.
- A VMWare le digo: ARRANCA UN SERVIDOR... Apretando un botón en la consola de VMWare.
Pero... nos hemos dado cuenta que hablar así tiene muchos inconvenientes... Y LO ESTAMOS DESCARTANDO en el mundo de la informática.
Qué problemas tenemos al hablar así:

Imaginad que le pido a Federico que ponga una silla debajo de la ventana... 
Y ya hay una silla. Federico contesta: 
- ERROR 
- EXIT CODE 127
- HTTP STATUS 400

Esto nos obliga a controlar lo que Federico (la computadora) debe hacer con mucha pecisión... y es cuando el lenguaje imperativo se vuelve un lenguaje muy incómodo.

Federico:
- SI hay algo que no es una silla debajo de la ventana
  - Lo quitas.
- SI no hay una silla, debajo de la ventana (IF condicionales):
  - Si no hay sillas:
    - Vete al ikea y compra una silla.
  - Pon una silla debajo de la ventana

El lenguaje declarativo es otra forma de expresarnos:
    Federico, debajo de la ventana ha de haber una silla. -> ESTO YA NO ES IMPERATIVO, ES DECLARATIVO
No le doy una orden a Federico. Me limito a decirle COMO QUIERO LAS COSAS.
Y delego en él la responsabilidad de hacer lo necesario para que las cosas estén como yo quiero.

Esta es la forma en la que hablamos con Kubernetes.
También es la forma en al que hablamos con Ansible... y muchos más.

Casi todo el software moderno está hecho para hablar en lenguaje declarativo.

A kubernetes, lo que le vamos a explicar! es cómo queremos que esté nuestro entorno de producción.
Le diré cosas como:
- Quiero tener instalado en el cluster Nextcloud, con una determinada configuración.
   Y kubernetes es quien se encarga de instalarlo, configurarlo y **mantenerlo funcionando**. 
   Si en un momento dado, nuestra instancia (la que kubernetes ha instalado) se cae, kubernetes se encargará de volver a levantarla en el mismo nodo del cluster o en otro.
   Si hay algún cambio en la configuración de la instancia, kubernetes se encargará de restaurar la configuración que nosotros le hemos dado.
- Quiero tener entre 1 y 4 instancias de tal programa... en base a la carga que haya en el cluster.
- Quiero que tal programa pueda ser accesible desde fuera del cluster

---

El tema es cómo le damos esas instrucciones a kubernetes. 
Cómo le explico que quiero mi entorno de producción de una determinada forma concreta.

Cualquier comunicación con kubernetes ser realiza mediante ARCHIVOS DE MANIFIESTO. Son archivos YAML.
(por ejemplo, Ansible también usa archivos YAML)

En los entornos de producción, manejamos muchos conceptos... que son al final los que kubernetes va a manejar también.

Qué cosas manejamos en un entorno de producción:
- Servidores
- Redes
- Aplicaciones
- Volúmenes de almacenamiento
- Control de versiones
- Politicas de disaster recovery.
- Balanceador de carga
    ^
        Apache httpd server: Es un servidor web, que con módulos adicionales puede hacer de balanceador de carga o de proxy reverso.
        Nginx: Es un proxy reverso, que me permite también hacer de servidor web o de balanceador de carga.
    v
- Proxy reverso

Si quiero tener una aplicación montada en cluster (no hablo de kubernetes) para tener HA/Escalabilidad.

Tengo un servidor web nginx y otro más por si el primero se cae... que el segundo tome los mandos (se active): CLUSTER ACTIVO/PASIVO
Podría tener 2 nginx, funcionando a la par... y si uno se cae, el otro se come todas las peticiones... las que se estaba comiendo antes y las del otro que se ha caído. Para montar esto, qué componente necesito en un entorno de producción: Balanceador de carga


 nginx1: IP1 <--
                    Balanceador de carga: IP_BC     <-- Proxy Reverso    <--      Proxy <---      Cliente
 nginx2: IP2 <--

#### Proxy?
Es un programa que intercepta cualquier petición de un cliente, y la ejecuta él en su lugar... dándole al cliente la respuesta de la ejecución que había solicitado. Su misión es PROTEGER:
- La identidad del cliente que está detrás de él
- De posibles datos maliciosos que pueda haber en la respuesta que se le da al cliente.

#### Proxy reverso?
Es un concepto similar ... pero de cara al servidor. PROTEGE:
- La identidad del servidor que está detrás de él
- De posibles datos maliciosos que pueda haber en la petición que le llega al servidor.... o de terminado tipo de ataques que se le puedan hacer al servidor:
- DDoS: Le mandan al servidor 500k peticiones. El proxy las corta, para no saturar al servidor.
        Le mandan 100 peticiones que no acaban nunca... le van mandando los bytes de 1 en uno, durante 2 horas.

En Kubernetes esas cosas son las que vamos a CONFIGURAR, pero Kubernetes les da a esas cosas un nombre especial... alternativo... MALDITA LA HORA.. porque nos lia... Pone nombres nuevos a cosas que ya conocemos por otros nombres.

Qué cosas manejamos en un entorno de producción:
  - Servidores                                     POD (Contenedores)
  - Redes
  - Firewall a nivel de red (reglas)               NETWORK POLICY
  - Aplicaciones
  - Volúmenes de almacenamiento                    PERSISTENT VOLUME
  - Control de versiones
  - Politicas de disaster recovery.
  - Balanceador de carga                           SERVICE
  - Proxy reverso                                  INGRESS CONTROLLER

# RESUMEN DE PUNTOS CLAVES:

1. Con kubernetes hablamos usando Lenguaje Declarativo:
   - Es kubernetes quien se encarga de hacer las cosas.
   - Nosotros nos limitamos a decirle cómo queremos que estén las cosas.
2. Kubernetes maneja los mismos conceptos que hemos manejado tradicionalmente en entornos de producción.
   Solo que Kubernetes les da nombres alternativos.


---

# Kubernetes lo que maneja son contenedores

## Qué es un contenedor? (Es un concepto análogo al de un servidor virtualizado)

En que sentido es análogo a un servidor virtualizado:
- Ejecuta tareas/trabajos (procesos de SO)
- Tiene una cantidad de CPU y memoria asignada
- Tiene unos volúmenes de almacenamiento asignados
- Tiene su propios sistema de archivos
- Tiene sus propias direcciones IP

Un contenedor es un ENTORNO AISLADO dentro de un kernel de SO (habitualmente Linux) en el que ejecutamos procesos.
Ese entorno tiene:
- Su propio sistema de archivos
- Su propia configuración de red -> Dirección IP
- Su propia configuración de almacenamiento
- Su propia configuración de recursos -> CPU, memoria
- Sus propias variables de entorno

Cuando hablo de CONTENEDOR aplica lo mismo a docker que a Kubernetes... ya que el concepto de CONTENEDOR es algo regido por un estándar... que gestiona la Open Container Initiative (OCI).

Los contenedores son un entorno aislado DENTRO DE UN KERNEL DE SO (habitualmente Linux) en el que ejecutamos procesos.

Cuando trabajo con contenedores, los contenedores están en comunicación con el kernel de SO del host. No tiene su propio kernel de SO.
En un contenedor NO PUEDO INSTALAR UN KERNEL DE SO.
En un servidor virtual NECESITO UN KERNEL DE SO.

Los contenedores COMPARTEN EL KERNEL DE SO con el host.
De forma que en una máquina donde haya muchos contenedores... solo hay un kernel de SO.
Mientras que una máquina con muchos servidores virtuales... tiene un kernel de SO por cada servidor virtual + el kernel de SO del host.

Los contenedores me permiten hacer más o menos lo mismo que las máquinas virtuales... pero con muchas ventajas... o mejor dicho... sin los inconvenientes de las máquinas virtuales.

### Forma tradicional de instalar software en un servidor:

        App1    +    App2   +    App3                   Inconvenientes:
    --------------------------------------------            - Si app1 se vuelve loca y toma toda la CPU
        Sistema Operativo (con su kernel)                           app1 pasa a estado OFFLINE
    --------------------------------------------                    app2 y app3 van detrás -> OFFLINE
            HIERRO (Mi servidor)                            - Potencialmente app3 puede espiar los datos / comunicaciones de app1 y 2
                                                            - App1 y app2 pueden tener requerimientos incompatibles

### Para lidiar con esos inconvenientes, se inventaron las máquinas virtuales.

        App1           |    App2 + App3                 Esto me resuelve los problemas de las instalaciones tradicionales
    --------------------------------------------
        SO 1           |       SO 2                     Pero viene con un coste:
    --------------------------------------------            - Derroche de recursos: Cada máquina virtual tiene su propio SO
        VM 1           |       VM2                              Antes había un SO... ahora hay 3... cada uno:
    --------------------------------------------                    - gastando RAM, ocupando espacio en disco, consumiendo CPU
        Hipervisor: HyperV, VMWare, VirtualBox              - Complica las instalaciones y mantenimientos
    --------------------------------------------            - El rendimiento se ve afectado
        Sistema Operativo (con su kernel)
    --------------------------------------------
            HIERRO (Mi servidor)

La VM, lleva:
- su propia configuración de red, 
- su propia configuración de almacenamiento, 
- su propia configuración de recursos (RAM y CPU)
- Tiene su propio SO: Windows, Linux, MacOS:
  - Con su propio sistema de archivos
  - Tiene sus propias variables de entorno

### Contenedores (alternativa a las máquinas virtuales)

        App1             |    App2 + App3               Esto resuelve los mismos problemas que las máquinas virtuales
    --------------------------------------------        
        Contenedor 1     |   Contenedor 2               Pero sin los inconvenientes de las máquinas virtuales
    --------------------------------------------
        Gestor de contenedores:
        Docker, Podman, Containerd, CRI-O
    --------------------------------------------
        Sistema Operativo (con su kernel)
    --------------------------------------------
              HIERRO (Mi servidor)



Linux no es un sistema operativo... es un kernel de SO.
    GNU/Linux es un sistema operativo... que incluye el kernel de SO Linux.
        Ubuntu es una distribución de GNU/Linux.
Windows tiene kernel? Claro que lo tiene. Todo SO tiene kernel.
    Windows es un SO? NO ... es una familia de SO.
        Windows 10 es un SO.
        Windows Server 2019 es un SO.
    Y microsoft ha tenido 2 kernel que ha usado para montar todos los sistemas operativos que ha montado hasta la fecha:
        - DOS:
            MS-DOS
            Windows 3.1
            Windows 95
            Windows 98
            Windows ME
        - NT: (New Technology)
            Windows NT
            Windows 2000
            Windows XP
            Windows Vista
            Windows 7
            Windows 8
            Windows 10
            Windows Server 2003
            Windows Server 2008
            Windows Server 2012
            Windows Server 2016
            Windows Server 2019

Esto significa que los contenedores van a acabar con las máquinas virtuales? NO.
Pero si que las han reemplazado en muchos casos de uso.

---
Kubernetes maneja contenedores
Conocéis alguien que maneje de forma centralizada máquinas virtuales? VCENTER (VMWare)

Es decir... de alguna forma, Kubernetes es el VCENTER de los contenedores.
Pero con el que hablamos mediante lenguaje declarativo, mientras que a VCENTER le hablamos mediante lenguaje imperativo.

Kubernetes: Es un gestor de gestores de contenedores, compatible con (Containerd, CRI-O), apto para entornos de producción.

Kubernetes me permite gestionar multiples gestores de contenedores instalados sobre un cluster de servidores.

Cluster:
- Servidor 1
  - Gestor de contenedores: CRIO 
- Servidor 2
  - Gestor de contenedores: CRIO 
...
- Servidor N
  - Gestor de contenedores: CRIO 

Kubernetes es un programa que controla todos esos CRIOs... y les dice qué contenedores han de tener en ejecución, en cada momento.
Y con una peculiaridad... el Kubernetes es un programa (realmente una colección de programas) que habrá que instalar en algún sitio...
Ese sitio es el propio cluster de servidores.
Es decir, en esas N máquinas que forman el cluster, tendré instalado KUBERNETES + Contenedores de mis aplicaciones.

En vuestro caso tenéis un cluster: 
- Servidor 1 (Máquina Virtual creada en VCENTER)
  - kubelet
     v 
  - CRIO    <- Y en esta es donde están instalados la mayor parte de los programas de kubernetes
        - kube-proxy
        - kube-scheduler
        - kube-controller-manager
        - API Server 
        - ETCD
        - CoreDNS
- Servidor 2 (Máquina Virtual creada en VCENTER)
  - kubelet
     v  
  - CRIO
        - kube-proxy
- Servidor 3 (Máquina Virtual creada en VCENTER)
  - kubelet
     v 
  - CRIO
        - kube-proxy
- Servidor 4 (Máquina Virtual creada en VCENTER)
  - kubelet
     v 
  - CRIO
        - kube-proxy

Qué programas forman parte de kubernetes?
- Kubelet                       Es el programa que se comunica con el gestor de contenedores (CRIO) para arrancar o parar contenedores.
- Kube-proxy                    Es un programa que gestionará las reglas de la red virtual del cluster de kubernetes.
                                Dentro de kubernetes se monta una red virtual, que permite a los contenedores comunicarse entre sí,
                                aislarlos del exterior. 
- Kube-scheduler                Es un programa cuya única misión es determinar en qué servidor del cluster se monta un contenedor.
- Kube-controller-manager       Esto es el meollo de kkubernetes... El que lleva la mayor parte de la responsabilidad:
                                - Es el que se encarga de que los contenedores estén en ejecución
                                - de que las reglas de red estén en vigor
                                - de que los volúmenes de almacenamiento estén montados.
- API Server                    Es el programa que recibe las instrucciones que le damos a kubernetes
- ETCD                          Es una base de datos donde kubernetes guarda las configuraciones que le indicamos
- CoreDNS                       Es un DNS interno del cluster de kubernetes

Salvo kubelet, los demás se ejecutan dentro de contenedores.
Kubelet en cambio es un programa que se instala a hierro en el servidor. Se monta como servicio del sistema operativo... con arranque automático.

Los propios programas de kubernetes, podemos querer que tengan HA... es decir que si uno se cae, tener una alternativa para que haga su trabajo... Y para tener una "HA real" esas otras copias de los programas deberían estar instaladas en otro servidor.

Los servidores que contienen copias de los programas de Kubernetes se llaman servidores (NODOS) maestros.
Y en vuestra instalación, SOLO TENEIS un nodo maestro.... Lo que implica que si se cae, voy jodido.
Y en kubernetes, como en muchas otras apps, pasamos de 1 a un mínimo de 3 nodos maestros.

Todos los contenedores de kubernetes se pinchan a una red virtual que es compartida entre las máquinas del cluster.
Cuando se instala un cluster, es necesario montar esa red virtual.
Hay decenas de formas de montar esa red virtual.
Hay muchos programas que se pueden instalar dentro de un cluster de kubernetes que montan y gestionan esa red virtual:
- Flannel: este es muy conocido en formaciones de kubernetes... porque es muy sencillo de instalar y configurar.
- Calico: Este es el más habitual en entornos de producción... es un poquito más complejo de instalar y configurar, pero nos ofrece muchas más posibilidades.
- Y otro montón más.

La instalación de un cluster supone:
1. Tomar una máquina que será el primer nodo maestro
2. En ella instalar:
   1. kubelet: es la base de kubernetes. Es el que permitirá controlar los CRIOs
   2. CRIO: es el que se encargará de arrancar y parar los contenedores
   3. kubeadm: Nos permite hacer operaciones de administración del cluster: Inicializar el cluster, añadir nodos, quitar nodos, etc.
   4. kubectl: es un cliente de kubernetes. Es el programa que usamos para dar instrucciones a kubernetes.
      kubectl se comunica con el API Server de kubernetes.
      Una alternativa a kubectl para mandar instrucciones al API Server es el Dashboard de kubernetes.

   Una vez montado esto:
   1. Con kubeadm se inicializa el cluster (en este paso hay que suministrar el rango de direcciones IP que se usarán en la red virtual del cluster):
      - Se montan todos los programas de kubernetes en el nodo maestro :
        - Api Server                     \
        - Kube-scheduler                  \   Control plane de kubernetes
        - Kube-controller-manager         /
        - CoreDNS                        /
        - Kube-proxy                    /
        - El ETCD                      / 
                (es una base de datos que se usa para guardar la configuración del cluster. Necesita para HA al menos 3 instancias)
        NOTA: Temporalmente kubeadm crea una red virtual en el rango de IPs que le hemos dado, para poder levantar los programas de kubernetes.... red virtual interna de la máquina. 
   2. Se configura kubectl para que se comunique con el cluster que se ha inicializado.
   3. Montar una red virtual para el cluster... mediante un plugin de red virtual de kubernetes: CALICO
      NOTA: Aquí se monta una red virtual real que opere sobre la red física a la que está conectado el nodo maestro. 
            Y se cambian los contenedores levantados en el paso 1 para que se conecten a la red virtual montada en este paso.
   4. Se añaden nodos al cluster

---

Cuando se instala un plano de control de kubernetes con HA, hay un componente que requiere al menos 3 instancias: ETCD
ETCD requiere 3 instancias para evitar un problema que se denomina BRAIN SPLIT.
Esto es algo muy común en las BBDD, y en sistemas que almacenan datos de forma distribuida: ELASTICSEARCH, MONGODB, KAFTKA, etc.

Imaginad un mariadb... y lo quiero montar en cluster activo/activo:
Las bbdd permiten trabajar de 3 formas diferentes:
- Standalone: Una sola instancia de la bbdd
- Replicación: Una instancia principal y una o varias replicas (espejos) de la principal
  Los espejos solo (si acaso) se usan para lecturas... para escrituras se sigue usando la principal.
- Cluster activo/activo: Todas las instancias del cluster se pueden usar para lecturas y escrituras. Aquí hay un problema

    MARIADB 1
        DATO1   DATO2
    MARIADB 2
        DATO1   DATO3
    MARIADB 3
        DATO2   DATO3

Y quiero hacer que formen un cluster activo/activo.
Lo primero, por delante monto un BALANCEADOR DE CARGA.
Le pido a una que almacene el DATO1

Quiero que ese dato esté en todas las máquinas: NO. Por qué?
Para qué estoy montando ese cluster Activo/Activo: Escalabilidad(rendimiento)
Si quisiera solo HA, montaría un cluster Activo/Pasivo, con promocionado automático de la máquina pasiva a activa.

Al montar cluster Activo/activo, con 3 nodos, consigo mejorar el rendimiento en un 50%.
- Con un solo nodo puedo hacer 1 insert por unidad de tiempo
- Al tener 3 nodos puedo hacer 3 insert en 2 unidades de tiempo.

Esto tiene un problema... Imaginad que la conexión de red en un momento dado se cae entre las máquinas...
O que una máquina tarda en contestar.


    MARIADB 1
        DATO1(1)   DATO2(2)  DATO4(4)
    MARIADB 2
        DATO1(1)   DATO3(3)  DATO4(4)
    ---------------------------------                     <<<< Peticiones (DATO4, DATO5)
    MARIADB 3
        DATO2(2)   DATO3(3)  DATO5(4)

        En ese monento tenemos lo que se denomina un BRAIN SPLIT. Una rotura de cerebro.
        A esos datos, la BBDD le ha ido asignado unos identificadores únicos...

        Y en ese momento esos nodos se vuelven irreconciliables... porque cada uno tiene una versión de los datos que no es compatible con la de los otros nodos.

        La solución a esto es MUY MALA... de muchas horas de artesano.

    Como se evita este problema: haciendo que solo 1 de las máquinas sea la que genere en un momento dado los identificadores únicos.
    Ese máquina recibe el role de MASTER del cluster de BBDD

    Y cómo se elige esa máquina: Se elige mediante un algoritmo de consenso (por VOTACION POPULAR)... y se exige que mayoría en la votación: Implica un número impar de nodos.

---

Estamos hablando todo el rato de Contenedores.
Pero Kubernetes no maneja directamente el concepto de Contenedor... maneja el concepto de POD.

### Qué es un POD?

Un pod es un conjunto de contenedores (puede ser un conjunto de solo 1 contenedor).
Esos contenedores:
- Comparten configuración de red... y por ende:
  - Comparten direcciones IP
  - Y pueden hablar entre si mediante localhost(127.0.0.1)
- Se despliegan en el mismo nodo del cluster
  - Pueden compartir volúmenes de almacenamiento locales
- Escalan juntos

---

Escenario: Tengo un conjunto de servidores web, sirviendo una aplicación web (3 nginx).
Cada nginx corre en su propio contenedor.
Cada nginx genera su propio archivo de log (access.log, error.log).

Quiero esos archivos de log en los contenedores?

                                    Garantizar la entrega del log
    POD  1                                  v                           Cluster de ElasticSearch
        Nginx                               v                           ES Master1
            -> access.log                Kafka  < Logstash > Logstash > ES Master2         <   Kibana
                ^                           ^       ^
        Agente beats -----------------------+    Enrutar     Transf.
    Pod 2                                   |                Filtrar    ES Master3
        Nginx                               |                           ES Data1
            -> access.log                   |                           ES Data2
                ^                           ^
        Agente beats -----------------------+
    Pod 3                                   |
        Nginx                               |
            -> access.log                   |
                ^                           ^
        Agente beats -----------------------+

Esos access.log los quiero en esas máquinas? NO. Por qué?
- Si se jode el HDD de una de esas máquinas... pierdo los logs de esa máquina... que posiblemente es cuando más los necesitaré.
- Llegará un momento en el que se petará el HDD de la máquina... y no podré escribir más logs.
- Si quiero hacer un análisis de logs (irlos revisando en busca de errores) tengo que ir a cada máquina a recoger los logs.

SOLUCION: Stack ELK (ELASTIC SEARCH + LOGSTASH + KIBANA + Agente beats)

ElasticSearch es un motor de búsqueda de texto completo (pero que concretamente para logs, me sirve de bbdd/repositorio de logs)
Logstash es un programa que se encarga de recoger logs de diferentes fuentes y enviarlos a ElasticSearch
Kibana es un programa WEB que me permite ver en tiempo real / analizar en diferido los logs que tenga guardados en un ElasticSearch.

El tema es que el access.log... Me interesa que se escriba en un almacenamiento local o en un almacenamiento en RED?
En RED.. pues os corta las orejas el compañero Joserra.
Además de otro problema: Qué tal va el escribir por red? Peor que en local.
Y el log es algo que no quiero que frene a los servidores nginx.. Esa operación debería de ir a toda ostia!!!!

KAFKA: Sistema de mensajería = WHATSAPP
- Whatsapp es un sistema de mensajería... para humanos
- Kafka es un sistema de mensajería... para programas

Que me asegura: La comunicación aunque el destinatario no esté disponible en ese momento.

Me interesa que nginx y el agente estén en el mismo contenedor o en contenedores diferentes?
Distintos: Por qué?
- Si se cae el agente beats... quiero reiniciar o recrear el proceso de nginx? No, ese déjalo que está funcionando.. y es el objeto principal del servicio.
- Si quiero actualizar la versión de nginx o del agente beats... quiero poder hacerlo por separado.

PERO necesito que se me garantice que:
- Que el contenedor del agente puede acceder al fichero de log del contenedor de nginx (compartir almacenamiento local)
- Que cada nginx que se levante tenga pegao al culo un contenedor de agente beats. (que escalen juntos)
Es decir, forman un POD.
- El nginx sería el contenedor principal del POD
- El agente beats sería lo que en el mundo de kubernetes se llama un SIDE CAR

En la práctica, si queremos montar estoi en un kubernetes, lo que hacemos es:
- Definir un pod que tenga:
  - Un contenedor con nginx
  - Un contenedor con el agente beats
Asociar a ese pod un volumen de almacenamiento local en memoria RAM... que sea compartido por ambos contenedores. 
Kubernetes me permite usar un trozo de la memoria RAM de la máquina para montar un volumen de almacenamiento local (una carpeta en la memoria RAM) que sea compartido por los contenedores de un POD.
- En el nginx, configuro rotado con 2 ficheros de log de 50Kbs cada uno.
Eso me asegura que la ram máxima que se va a usar para los logs es de 100Kbs.
Y las escrituras y lecturas van a la mayor velocidad posible.

---

Todas esas configuraciones hemos dicho que las damos mediantes archivos YAML... Archivos complejos de crear... harto complejos.
Un archivo YAML para un despliegue de un nginx, con el agente beats... y el cluster de elastic...
Puede ser en realidad no un archivos sino 50... Algunos com más de 500 lineas de código.. HARTO COMPLEJO

Qué hay aquí... HELM

HELM Es un programa que opera sobre un cluster de kubernetes.
Las empresas que crean software usualmente crean lo que se denomina un CHART de HELM.
Qué es un CHART de HELM?
Una plantilla de despliegue de una aplicación en un cluster de kubernetes.

HELM es una herramienta que me permite tomar:
- Un CHART de HELM
- Un archivo de personalización de ese CHART (de esa plantilla para mi caso concreto de despliegue)
Y generar en base a esto todos los archivos YAML de manifiesto que necesito para desplegar esa aplicación en un cluster de kubernetes.
E instalarla en automático en el cluster.

Se define HELM como el GESTOR DE PAQUETES DE KUBERNETES.

De hecho... el archivo de configuración de un chart de helm (de personalización) es un archivo YAML que puede tener el mismo número de líneas que el archivo de manifiesto de kubernetes que se genera a partir de él.

Depende del fabricante... existirán esos CHARTS de HELM... o no.
Y estarán mejor o peor hechos.

El Chart de Helm de Nextcloud... es genial !
El chart de helm de Keycloak... es genial !
El chart de helm de JITSI... es una mierda gigantesca!

---

Helm no es la única opción para definir y jugar con plantillas de despliegue de aplicaciones en kubernetes.
Hay un programita mucho más sencillo que se llama KUSTOMIZE.
No nos gusta KUSTOMIZE...  no nos da la flexibilidad y funcionalidad que nos da HELM.

Kustomize solo genera plantillas
HELM gestiona versiones de aplicaciones en un cluster de kubernetes.
Con helm puedo instalar una versión de mi app.
Puedo actualizar la versión de mi app.
Puedo hacer un rollback a una versión anterior de mi app.