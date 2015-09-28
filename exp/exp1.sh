#!/bin/bash

tamanos="1800 1644 1500 1344 1200 1044 900 744 600 480 300 240 180 120 96 60 48 36 24"
repeticiones=1
imp_diff="asm c"
imp_blur="asm c"

verbose=false
while getopts 'r:v' opt; do
  case $opt in
    r) repeticiones=$OPTARG ;;
    v) verbose=true ;;
  esac
done

echo "Compilando..."
make -s -C $(dirname $0)/..
if [ $? -ne 0 ]; then
    echo "ERROR: Error de compilación."
    exit 1
fi

echo "Generando datos de entrada..."
mkdir -p $(dirname $0)/exp1
for i in $tamanos; do
    if [ ! -f $(dirname $0)/exp1/phoebe1-$i.bmp ]; then
        if [ "$verbose" = true ]; then
            echo "  Generando archivo $(dirname $0)/exp1/phoebe1-$i.bmp"
        fi
        convert $(dirname $0)/../img/phoebe1-1800.bmp -scale ${i}x${i} $(dirname $0)/exp1/phoebe1-$i.bmp
    fi
    if [ ! -f $(dirname $0)/exp1/phoebe2-$i.bmp ]; then
        if [ "$verbose" = true ]; then
            echo "  Generando archivo $(dirname $0)/exp1/phoebe2-$i.bmp"
        fi
        convert $(dirname $0)/../img/phoebe2-1800.bmp -scale ${i}x${i} $(dirname $0)/exp1/phoebe2-$i.bmp
    fi
done
if [ $? -ne 0 ]; then
    echo "ERROR: Error generando datos de entrada."
    exit 1
fi

echo "Corriendo instancias del experimento..."

# diff
for imp in $imp_diff; do
    mkdir -p $(dirname $0)/exp1/diff-$imp
    echo "   Filtro: diff   Implementación: $imp   Imágenes: phoebe1, phoebe2"
    echo "Filtro: diff   Implementación: $imp   Imágenes: phoebe1, phoebe2" >> $(dirname $0)/exp1/datos.txt
    for k in $(seq $repeticiones); do
        for i in $tamanos; do
            let "j=i*2/3"
            let "t=i*j"
            if [ "$verbose" = true ]; then
                echo "  Corriendo instancia ${i}×${j}"
            fi
            $(dirname $0)/../build/tp2 diff -i $imp -o $(dirname $0)/exp1/diff-$imp $(dirname $0)/exp1/phoebe1-$i.bmp $(dirname $0)/exp1/phoebe2-$i.bmp |
                sed -e '/insumidos totales/!d' -e 's/.*: //' |
                while IFS= read -r line; do
                    if [ "$verbose" = true ]; then
                        printf "    Tamaño: %8s.    Tiempo insumido: %12s\n" "$t" "$line"
                    fi
                    echo "$t $line" >> $(dirname $0)/exp1/datos.txt
                done
        done
        echo "" >> $(dirname $0)/exp1/datos.txt
    done
done

# blur
for imp in $imp_blur; do
    mkdir -p $(dirname $0)/exp1/blur-$imp
    echo "   Filtro: blur   Implementación: $imp   Imagen: phoebe1"
    echo "Filtro: blur   Implementación: $imp   Imagen: phoebe1" >> $(dirname $0)/exp1/datos.txt
    for k in $(seq $repeticiones); do
        for i in $tamanos; do
            let "j=i*2/3"
            let "t=i*j"
            if [ "$verbose" = true ]; then
                echo "  Corriendo instancia ${i}×${j}"
            fi
            $(dirname $0)/../build/tp2 blur -i $imp -o $(dirname $0)/exp1/blur-$imp $(dirname $0)/exp1/phoebe1-$i.bmp 5 15 |
                sed -e '/insumidos totales/!d' -e 's/.*: //' |
                while IFS= read -r line; do
                    if [ "$verbose" = true ]; then
                        printf "    Tamaño: %8s.    Tiempo insumido: %12s\n" "$t" "$line"
                    fi
                    echo "$t $line" >> $(dirname $0)/exp1/datos.txt
                done
        done
        echo "" >> $(dirname $0)/exp1/datos.txt
    done
done