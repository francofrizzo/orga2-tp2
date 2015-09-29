#!/bin/bash

LC_NUMERIC="en_US.UTF-8"

sigmas=".5 1 1.5 "$(seq 3 3 48)" 50"
r_fijo=50

repeticiones=1
implementaciones="asm c"

verbose=false
while getopts 'n:vhcr:' opt; do
  case $opt in
    n) repeticiones=$OPTARG ;;
    v) verbose=true ;;
    h) echo ""
       echo "    Experimento 3. Se aplica el filtro blur a una imagen fija, variando"
       echo "    el parámetro sigma, y midiendo el tiempo de cada ejecución."
       echo ""
       echo "    Opciones disponibles:"
       echo "        -c        Elimina los archivos generados por el experimento."
       echo "        -h        Imprime este texto de ayuda."
       echo "        -n <núm>  Determina la cantidad de veces que se realizará el expe-"
       echo "                    rimento (1 por defecto)."
       echo "        -v        Muestra más información por pantalla."
       echo "        -r        Determina el valor del parámetro radio (50 por defecto)."
       echo ""
       exit 0 ;;
    c) if [ -d $(dirname $0)/exp3 ]; then rm $(dirname $0)/exp3 -R; fi
       exit 0 ;;
    r) r_fijo=$OPTARG ;;
  esac
done

echo "Compilando..."
make -s -C $(dirname $0)/..
if [ $? -ne 0 ]; then
    echo "ERROR: Error de compilación."
    exit 1
fi

echo "Generando datos de entrada..."
mkdir -p $(dirname $0)/exp3/in
convert $(dirname $0)/../img/phoebe1.bmp -scale 600x600 $(dirname $0)/exp3/in/phoebe1-600.bmp
if [ $? -ne 0 ]; then
    echo "ERROR: Error generando datos de entrada."
    exit 1
fi

echo "Corriendo instancias del experimento..."

for imp in $implementaciones; do
    mkdir -p $(dirname $0)/exp3/out/blur-$imp
    echo "   Implementación: $imp   Imagen: phoebe1   Radio: $r_fijo"
    printf "%d\n" $repeticiones >> $(dirname $0)/exp3/data-blur-$imp.txt
    for s in $sigmas; do
        printf "%.2g" "$s" >> $(dirname $0)/exp3/data-blur-$imp.txt
        if [ "$verbose" = true ]; then
            echo "  Corriendo instancia sigma = $s"
        fi
        for k in $(seq $repeticiones); do
            $(dirname $0)/../build/tp2 blur -i $imp -o $(dirname $0)/exp3/out/blur-$imp $(dirname $0)/exp3/in/phoebe1-600.bmp $s $r_fijo |
                sed -e '/insumidos totales/!d' -e 's/.*: //' |
                while IFS= read -r line; do
                    if [ "$verbose" = true ]; then
                        printf "    Sigma: %8s.    Tiempo insumido: %12s\n" "$s" "$line"
                    fi
                    printf " %d" "$line" >> $(dirname $0)/exp3/data-blur-$imp.txt
                done
            n1=$($(dirname $0)/../build/tp2 blur -i $imp -n $(dirname $0)/exp3/in/phoebe1-600.bmp)
            n2=$(echo $n1 | sed -e "s/.bmp$/.$s.$r_fijo.bmp/")
            mv $(dirname $0)/exp3/out/blur-$imp/$n1 $(dirname $0)/exp3/out/blur-$imp/$n2
        done
        printf "\n" >> $(dirname $0)/exp3/data-blur-$imp.txt
    done
done
