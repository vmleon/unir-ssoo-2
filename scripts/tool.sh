#!/bin/bash

echo "OS Tool - Actividad 2"

copy_sh_and_c_files () {
    if [ ! -d "$1" ]; then
        echo "$1 does not exist."
        return
    fi
    source_path="$(realpath $1)"

    if [ ! -d "$2" ]; then
        mkdir -p $2
    fi
    dest_path="$(realpath $2)"
    
    echo "Moving files (.sh and .c) from $source_path to $dest_path"
    
    cp $source_path/*.sh $dest_path
    cp $source_path/*.c $dest_path
}

PS3='Please enter your choice: '
items=("Disk Space" "Size in disk" "Process usage" "Current Users" "Latest Users" "Last 5 lines from file", "Copy sh and c files")

select item in "${items[@]}" Quit
do
    case $REPLY in
        # Obtener el espacio libre del disco
        1) echo "$REPLY - $item"; df -h; break;;

        # Obtener el tamaño ocupado por un determinado directorio y sus ficheros y subdirectorios
        2) echo "$REPLY - $item"; du -sh $(realpath $1); break;;
        
        # Obtener el uso del procesador
        3) echo "$REPLY - $item"; iostat -c; break;;
        
        # Obtener el número de usuarios conectados
        4) echo "$REPLY - $item"; w; break;;
        
        # Obtener el número de usuarios conectados desde la última vez que se preguntó
        5) echo "$REPLY - $item"; last; break;;
        
        # Mostrar las últimas cinco líneas de un fichero de texto que se pasa como parámetro con su ubicación completa
        6) echo "$REPLY - $item"; tail -n 5 $(realpath $1); break;;
        
        # Copiar todos los archivos con extensión .sh y .c de un directorio origen pasado como parámetro a un 
        # directorio destino pasado como parámetro. Si el directorio destino no existe, el script lo debe crear
        7) echo "$REPLY - $item"; copy_sh_and_c_files $1 $2; break;; # TODO path parameter instead of default .
        
        $((${#items[@]}+1))) echo "bye..."; break 2;;
        *) echo "invalid option $REPLY"; break;
    esac
done