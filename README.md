# UNIR Sistemas Operativos Avanzados - Actividad 2

## Introducción

El script creado contiene un menú con un `do case` para seleccionar la opción a ejecutar.

En caso de ser una función que requiera parametros, son TODO

Funcionalidades que requieran mas de una linea, están externalizadas en una función de bash. Por ejemplo `copy_sh_and_c_files`.

> Comprueba que tools.sh tiene permisos de ejecucion con `ls -l scripts/tools.sh.
>
> Si no es asi, da permisos con este comando:
>
> ```bash
> chmod u+x scripts/tool.sh
> ```

### Compatibilidad

La compatibilidad del script ha sido probada en MacOS Sequoia 15.1.1 (24B91) (localmente) y en un Ubuntu 25.04 ejecutado como container con [Podman](https://podman.io/), open source container engine creado por RedHat. Podman tiene funcionalidad equivalente a Docker, con un `alias docker=podman` la migración sería transparente para el usuario.

> Con Docker no es necesario. Para usar Podman, a diferencia de Docker, necesitamos crear y arrancar la máquina virtual donde se ejecuta el container engine.
> Si no tienes máquina virtual ejecuta `podman machine init` para crear/iniciar una.
> Una vez creada, ejecuta `podman machine start`.

Para simplificar la creación de un Ubuntu compatible y con más funcionalidad, este proyecto contienen un `Containerfile` (equivalente a [Dockerfile](https://docs.docker.com/reference/dockerfile/)) donde se actualizan los repositorios de Ubuntu, y se instalan los siguientes paquetes básicos:

- `sysstat`,
- `build-essential`,
- `curl`,
- `git`,
- `htop`,
- `man`,
- `unzip`,
- `vim`,
- `wget`
- `tree`

> `sysstat` es el único requisito mínimo para ejecutar `tool.sh`, en concreto la opción 3 "Obtener el uso del procesador" porque require el uso de `iostat` contenido en este paquete.

Para construir la imagen, ejecutemos el siguiente comando:

```bash
podman build -t ssoo-ubuntu .
```

## Ejecución

### Ubuntu en container

- `podman run` pide a Podman ejecutar un nuevo container
- `--rm` borra el container cuando la ejecución termina
- `--name ubuntu` le da nombre al container para hacer referencia posteriormente en vez de asignarle nombre por defecto
- `-it` envia la entrada y salida del container a standard output e input de nuestra terminal
- `-v $(pwd)/scripts/:/tools` mapea el directorio `scripts` del repositorio con un directorio `/tools` dentro del container. Así tenemos acceso a `/scripts/tools.sh` en el path `/tools/tool.sh` dentro del container.
- `localhost/tools:latest` es el nombre de la imagen Ubuntu 25.04 que hemos creado en los pasos anteriores.
- `/bin/bash` nos abre una terminal dentro del container

```bash
podman run \
    --rm \
    --name ssoo-ubuntu \
    -it \
    -v $(pwd)/scripts/:/tools \
    -v $(pwd)/test/:/test \
    localhost/ssoo-ubuntu:latest \
    /bin/bash
```

### Ejercicio 1: Obtener el espacio libre del disco

```bash
/tools/tool.sh
```

> Selecciona la Opción 1

![Screenshot Option 1](images/ubuntu-opcion-1.png)

Debido al overlay que hace podman del disco y el mapeo de volumenes como `/test`, vemos que el directorio `/` tiene 100G, 29G usados y 72G libres, lo que hace un 29% de uso de disco. Esta memoria es virtual asignada a la máquina de Podman. Y luego que `/test` tiene 461G con un uso del 98%. Un momento estupendo para limpiar disco en el MacOS que contiene Podman :)

### Ejercicio 2: Obtener el tamaño ocupado por un determinado directorio y sus ficheros y subdirectorios

```bash
/tools/tool.sh /test
```

> Selecciona la Opción 2

![Screenshot Option 2](images/ubuntu-opcion-2.png)

### Ejercicio 3: Obtener el uso del procesador

> On ubuntu, container image, install sysstat:
> Update repositories: `apt update -y`
> Install package: `apt install -y sysstat`

```bash
/tools/tool.sh
```

> Selecciona la Opción 3

![Screenshot Option 3](images/ubuntu-opcion-3.png)

El comando `iostat -c` devuelve información sobre el sistema, en este caso un kernel 6 de linux ya que estamos usando Ubuntu 25.04 y una architectura ARM ya que el hardware usado es MacBook M1 Chip.

`user` muestra el uso medio de CPU para el usuario.

`nice` indica la carga de CPU debido a procesos con `setpriority`. O el equivalente en sistemas antiguos `nice`.

`iowait` son tiempos de espera donde el procesador no ha saltado a otro proceso pero esta esperando a una operacion de entrada y salida

`steal` es tiempo de hypervisor o container engine. Un valor a tener en cuenta si sospechamos que el problema puede ser que nuestra máquina (bare metal o host) soportando muchas máquinas virtuales en un punto que esta saturando al hypervisor.

`idle` que es el resto del tiempo que no esta haciendo nada productivo. En este caso, el sistema no está bajo ninguna carga.

### Ejercicio 4: Obtener el número de usuarios conectados

```bash
/tools/tool.sh
```

> Selecciona la Opción 4

![Screenshot Option 4](images/ubuntu-opcion-4.png)

Ejecutando el comando en el container de Ubuntu porque estamos usando el comando `w` que según la documentación oficial con `man w` _Show who is logged on and what they are doing_. Y `logged` nos da la clave del resultado. Containers son procesos usando cgroup y namespaces del Kernel de Linux. Y cuando ejecutamos el proceso bash, no estamos haciendo logging en la máchina si no ejecutando ese proceso.

Para confirmar esta hipótesis, en una máquina virtual Ubuntu 24.04 en Parallels (un hypervisor para MacOS) nos da un valor más acorde, porque en este caso si estas logged dentro de la máchina.

Veamoslo en el pantallazo a continuación:

![Screenshot Option 4 VM](images/ubuntu-opcion-4-vm.png)

El usuario `parallels` (usuario creado por defecto en VMs en Parallels) con su hora y qué esta haciendo. Dado que el comando se ejecuta desde una terminal de Gnome, ahi tenemos el comando concreto `gnome-session-binary`.

### Ejercicio 5: Obtener el número de usuarios conectados desde la última vez que se preguntó

```bash
/tools/tool.sh
```

> Selecciona la Opción 5

Recibimos el siguiente ERROR:

```
Please enter your choice: 5
5 - Latest Users
/tools/tool.sh: line 42: last: command not found
root@62a99fa3efaf:/# last
bash: last: command not found
```

El comando `last` no se ha encontrado. Parece que hemos topado con un error en Ubuntu 25.04 según este post [“last” command is not found on Plucky 25.04](https://discourse.ubuntu.com/t/last-command-is-not-found-on-plucky-25-04/51215/3) del foro de Ubuntu.

Recomiendan reinstalar el paquete `wtmpdb` que mantiene los logs de usuarios.

```bash
apt install --reinstall  wtmpdb
```

Comprobamos version y que se ha instalado adecuadamente:

```bash
apt policy wtmpdb
```

Seguimos encontrando un ERROR, aunque diferente:

```
Please enter your choice: 5
5 - Latest Users
open_database_ro: Cannot open database (/var/lib/wtmpdb/wtmp.db): unable to open database file
```

A pesar de ser usuario root, no podemos abrir el fichero `/var/lib/wtmpdb/wtmp.db`. Con `ls /var/lib/wtmpdb/wtmp.db` vemos que el fichero no existe.

Haciendo un `ls /var/lib/wtmpdb/` vemos que no hay ningun fichero dentro del directorio, aunque el directorio existe.

En este punto lamento haber probado con Ubuntu 25.04 en container pero mi hipotesis es que a pesar de reinstallar el paquete como no hacemos login/logout en la máquina (ya que es un container, es decir, un proceso) la base de datos `wtmp.db` no se ha creado en el sistema.

Vamos a hacer la misma prueba en Ubuntu 24.04 en máquina virtual.

![Screenshot Option 5 VM](images/ubuntu-opcion-5-vm.png)

En una máquina virtual con Ubuntu 24.04 el resultado es el esperado

### Ejercicio 6: Mostrar las últimas cinco líneas de un fichero de texto que se pasa como parámetro con su ubicación completa

```bash
/tools/tool.sh /test/leave_me_alone.txt
```

> Selecciona la Opción 6

![Screenshot Option 6](images/ubuntu-opcion-6.png)

El fichero /test/leave_me_alone.txt tiene lineas numeradas para ayudar a comprobar el resultado de este ejecicio.

El resultado de `tail -n 5 $(realpath $1)` es imprimir en pantalla las últimas 5 lineas del fichero pasado por parametro número `1`. Usamos `realpath` para limpiar el path pasado por parametro.

### Ejercicio 7: Copiar todos los archivos con extensión .sh y .c de un directorio origen pasado como parámetro a un directorio destino pasado como parámetro.

```bash
/tools/tool.sh /test backup
```

> Selecciona la Opción 7

![Screenshot Option 7](images/ubuntu-opcion-7.png)

En este ejercicio se llama a una función en bash que copia ficheros con las extensiones `.sh` y `.c` del directorio pasado en el primer parametro, en este ejemplo `/test`. Y crea un directorio, en este ejemplo `/backend` pasado como segundo parametro que es el destino de los ficheros copiados.

Se usa `cp` que acepta ficheros y considera el último parametro como el destino.

Usamos `tree` para mostrar los ficheros, aunque se podria usar `ls`.

`tree` imprime toda la jerarquía de ficheros dentro del directorio. Me ha hecho pensar que seria interesante incluir la opción de copiar todos los ficheros `.sh` y `.c` independientemente de la profundidad a la que se encuentren.

Para este nuevo ejercicio deberiamos usar `find` de la siguiente manera:

```bash
cp $(find /test -type f -iname \*\.sh -o -iname \*\.c) /backup/
```

La parte importante esta en el `find` donde `/test` es el sitio donde queremos buscar.

`-type f` indicamos que solo queremos ficheros.

`-iname` hace un case insensitive match por nombre.

`-o` es un OR dando por valida cualquiera de las condiciones que son verdaderas.

## Dificultades

- `realpath` necesario cuando se resuelve `.` y `..` pasado por parametro de la herramienta
- `declare -a` necesario en Ubuntu, si no da error al encontrar el primer parentesis `(`

## Bibliografía

- [Ubuntu - How can I create a select menu in a shell script?](https://askubuntu.com/questions/1705/how-can-i-create-a-select-menu-in-a-shell-script)
- [Baeldung Linux - Creating a Simple Select Menu in the Shell Script](https://www.baeldung.com/linux/shell-script-simple-select-menu)
- [nixCraft - Linux List Current Logged In Users](https://www.cyberciti.biz/faq/unix-linux-list-current-logged-in-users/)
- [w(1) — Linux manual page](https://man7.org/linux/man-pages/man1/w.1.html)
- [Ubuntu - When writing a bash script, how do I get the absolute path of the location of the current file?](https://askubuntu.com/questions/893911/when-writing-a-bash-script-how-do-i-get-the-absolute-path-of-the-location-of-th)
- [Stackoverflow - How do I check if a directory exists or not in a Bash shell script?](https://stackoverflow.com/questions/59838/how-do-i-check-if-a-directory-exists-or-not-in-a-bash-shell-script)
- [Bash Array – How to Declare an Array of Strings in a Bash Script](https://www.freecodecamp.org/news/bash-array-how-to-declare-an-array-of-strings-in-a-bash-script/)
- [“last” command is not found on Plucky 25.04](https://discourse.ubuntu.com/t/last-command-is-not-found-on-plucky-25-04/51215/3)
