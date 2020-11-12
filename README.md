# script

## Requisitos
* Las tablas en la base de datos destino deben de estar creadas
* Las sentencias a ejecutar deben de poder ejecutarse, es decir, si hay dependencias de funciones o procedimientos estos deberán estar en la base de datos destino.
* El script está pensado para hacer movimientos de datos no muy elevados, si se requiere de movimientos de volumenes más elevados se debería de podificar para extraer e importar datos con tablas externas. 

## Funcionamiento
El siguiente script permite el movimiento de datos de una base de datos a otra destino. Para ello ejecutará una sentencia en la base de datos origen y posteriormente los movera a la tabla de la base de datos destino. 

## Ejecución
El script posee los siguientes parámetros de entrada:

* -s | --source, indica la base de datos origin
* -d | --destination, indica la base de datos destino
* -i | --input, indica el fichero con las sentencias a ejecutar

Ejemplo
```
./script.sh -s planeta -d vdirbi -i /tmp/input_file
```

## Fichero de entrada
El fichero de entrada estará compuesto por lineas separadas por pipes (|) siguiendo el siguiente formato:

**sentencia origen|tabla destino|setencia post insercion|truncate**

* **sentencia origen** indica la sentencia que se va a ejecutar en la base de datos origen.
* **tabla destino** indica la tabla destino en la que se van a insertar los datos
* **sentencia post insercion** indica la sentencia que se ejecutará una vez que se han insertado los datos en la tabla destino.
* **truncate** indica si se hace un truncado de la tabla destino antes de la insercion

Ejemplo
```
select dwc_id from agentes limit 1|test_table|select version()|true
```