#!/bin/bash

radios=$(seq 15 15 185)" 199"
sigma_fijo=5

repeticiones=1
implementaciones="asm c"

verbose=false
while getopts 'n:vhcs:' opt; do
  case $opt in
    n) repeticiones=$OPTARG ;;
    v) verbose=true ;;
    h) echo ""
       echo "    Experimento 2. Se aplica el filtro blur a una imagen fija, variando"
       echo "    el parámetro radio, y midiendo el tiempo de cada ejecución."
       echo ""
       echo "    Opciones disponibles:"
       echo "        -c        Elimina los archivos generados por el experimento."
       echo "        -h        Imprime este texto de ayuda."
       echo "        -n <núm>  Determina la cantidad de veces que se realizará el expe-"
       echo "                    rimento (1 por defecto)."
       echo "        -v        Muestra más información por pantalla."
       echo "        -s        Determina el valor del parámetro sigma (5 por defecto)."
       echo ""
       exit 0 ;;
    c) if [ -d $(dirname $0)/exp2 ]; then rm $(dirname $0)/exp2 -R; fi
       exit 0 ;;
    s) sigma_fijo=$OPTARG ;;
  esac
done

echo "Compilando..."
make -s -C $(dirname $0)/..
if [ $? -ne 0 ]; then
    echo "ERROR: Error de compilación."
    exit 1
fi

echo "Generando datos de entrada..."
mkdir -p $(dirname $0)/exp2/in
convert $(dirname $0)/../img/phoebe1.bmp -scale 600x600 $(dirname $0)/exp2/in/phoebe1-600.bmp
if [ $? -ne 0 ]; then
    echo "ERROR: Error generando datos de entrada."
    exit 1
fi

echo "Corriendo instancias del experimento..."

for imp in $implementaciones; do
    mkdir -p $(dirname $0)/exp2/out/blur-$imp
    echo "   Implementación: $imp   Imagen: phoebe1   Sigma: $sigma_fijo"
    printf "%d\n" $repeticiones >> $(dirname $0)/exp2/data-blur-$imp.txt
    for r in $radios; do
        printf "%d" "$r" >> $(dirname $0)/exp2/data-blur-$imp.txt
        if [ "$verbose" = true ]; then
            echo "  Corriendo instancia r = $r"
        fi
        for k in $(seq $repeticiones); do
            $(dirname $0)/../build/tp2 blur -i $imp -o $(dirname $0)/exp2/out/blur-$imp $(dirname $0)/exp2/in/phoebe1-600.bmp $sigma_fijo $r |
                sed -e '/insumidos totales/!d' -e 's/.*: //' |
                while IFS= read -r line; do
                    if [ "$verbose" = true ]; then
                        printf "    Radio: %8s.    Tiempo insumido: %12s\n" "$r" "$line"
                    fi
                    printf " %d" "$line" >> $(dirname $0)/exp2/data-blur-$imp.txt
                done
            n1=$($(dirname $0)/../build/tp2 blur -i $imp -n $(dirname $0)/exp2/in/phoebe1-600.bmp)
            n2=$(echo $n1 | sed -e "s/.bmp$/.$sigma_fijo.$r.bmp/")
            mv $(dirname $0)/exp2/out/blur-$imp/$n1 $(dirname $0)/exp2/out/blur-$imp/$n2
        done
        printf "\n" >> $(dirname $0)/exp2/data-blur-$imp.txt
    done
done
