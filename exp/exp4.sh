#!/bin/bash

tamanos="1800 1644 1500 1344 1200 1044 900 744 600 480 300 240 180 120 96 60 48 36 24"
repeticiones=1
imp_diff="c c2"
imp_blur="asm asm2"
filtros="both"

verbose=false
while getopts 'n:vhcf:i:' opt; do
  case $opt in
    n) repeticiones=$OPTARG ;;
    v) verbose=true ;;
    h) echo ""
       echo "    Experimento 1. Se calcula el tiempo de ejecución para todas las implementa-"
       echo "    ciones de ambos filtros, variando el tamaño de la imagen de entrada."
       echo ""
       echo "    Opciones disponibles:"
       echo "        -c        Elimina los archivos generados por el experimento."
       echo "        -f <blur|diff|both>    Filtro a ejecutar (ambos por defecto)."
       echo "        -h        Imprime este texto de ayuda"
       echo "        -i        Lista de las implementaciones de los filtros que se ejecuta-"
       echo "                  rán, separadas por comas. Valores posibles: c, asm, c2, asm2."
       echo "                  Por defecto, se ejecutarán las implementacions c y c2 de diff"
       echo "                  y asm y asm2 de blur."
       echo "        -n <núm>  Determina la cantidad de veces que se ejecutará cada imple-"
       echo "                    mentación (1 por defecto)."
       echo "        -v        Muestra más información por pantalla."
       echo ""
       exit 0 ;;
    c) rm $(dirname $0)/exp1 -R
       exit 0 ;;
    f) filtros=$OPTARG ;;
    i) imp_diff=$(echo $OPTARG | sed s/,/\\n/g) ; imp_asm=$(echo $OPTARG | sed s/,/\\n/g) ;;
  esac
done

echo "Compilando..."
make -s -C $(dirname $0)/..
if [ $? -ne 0 ]; then
    echo "ERROR: Error de compilación."
    exit 1
fi

echo "Generando datos de entrada..."
mkdir -p $(dirname $0)/exp1/in
for i in $tamanos; do
    if [ ! -f $(dirname $0)/exp1/in/phoebe1-$i.bmp ]; then
        if [ "$verbose" = true ]; then
            echo "  Generando archivo $(dirname $0)/exp1/in/phoebe1-$i.bmp"
        fi
        convert $(dirname $0)/../img/phoebe1.bmp -scale ${i}x${i} $(dirname $0)/exp1/in/phoebe1-$i.bmp
    fi
    if [ ! -f $(dirname $0)/exp1/in/phoebe2-$i.bmp ]; then
        if [ "$verbose" = true ]; then
            echo "  Generando archivo $(dirname $0)/exp1/in/phoebe2-$i.bmp"
        fi
        convert $(dirname $0)/../img/phoebe2.bmp -scale ${i}x${i} $(dirname $0)/exp1/in/phoebe2-$i.bmp
    fi
done
if [ $? -ne 0 ]; then
    echo "ERROR: Error generando datos de entrada."
    exit 1
fi

echo "Corriendo instancias del experimento..."

# diff
if [[ $filtros = "diff" || $filtros == "both" ]]; then
    for imp in $imp_diff; do
        mkdir -p $(dirname $0)/exp1/out/diff-$imp
        echo "   Filtro: diff   Implementación: $imp   Imágenes: phoebe1, phoebe2"
        echo "Filtro: diff   Implementación: $imp   Imágenes: phoebe1, phoebe2" >> $(dirname $0)/exp1/datos.txt
        for k in $(seq $repeticiones); do
            for i in $tamanos; do
                let "j=i*2/3"
                let "t=i*j"
                if [ "$verbose" = true ]; then
                    echo "  Corriendo instancia ${i}×${j}"
                fi
                $(dirname $0)/../build/tp2 diff -i $imp -o $(dirname $0)/exp1/out/diff-$imp $(dirname $0)/exp1/in/phoebe1-$i.bmp $(dirname $0)/exp1/in/phoebe2-$i.bmp |
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
fi

# blur
if [[ $filtros = "blur" || $filtros == "both" ]]; then
    for imp in $imp_blur; do
        mkdir -p $(dirname $0)/exp1/out/blur-$imp
        echo "   Filtro: blur   Implementación: $imp   Imagen: phoebe1"
        echo "Filtro: blur   Implementación: $imp   Imagen: phoebe1" >> $(dirname $0)/exp1/datos.txt
        for k in $(seq $repeticiones); do
            for i in $tamanos; do
                let "j=i*2/3"
                let "t=i*j"
                if [ "$verbose" = true ]; then
                    echo "  Corriendo instancia ${i}×${j}"
                fi
                $(dirname $0)/../build/tp2 blur -i $imp -o $(dirname $0)/exp1/out/blur-$imp $(dirname $0)/exp1/in/phoebe1-$i.bmp 5 15 |
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
fi