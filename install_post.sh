#!/bin/bash

# Script para instalar Odoo 18 desde el repositorio odoo/odoo en un entorno on-premise (Debian/Ubuntu)
# Sin interacciones durante la ejecución, con archivos centralizados y re-ejecutable
# Utiliza el usuario actual y se ejecuta con sudo
# Comandos de post-instalación

# Cargar el archivo de configuración
source config.sh

# Establecer el propietario de los archivos
echo "Estableciendo el propietario de los archivos en $ODOO_HOME a $ODOO_USER..."
chown -R "$ODOO_USER":"$ODOO_USER" "$ODOO_HOME"
check_success

# Imprimir información final
echo "
¡Odoo $ODOO_VERSION ha sido instalado con éxito desde el repositorio odoo/odoo!

Puedes acceder a Odoo en http://localhost:$ODOO_PORT
Usuario administrador: admin
Contraseña administrador: admin

Archivo de configuración: $ODOO_CONFIG_FILE
Logs: $ODOO_LOG_DIR/odoo.log
Addons: $ODOO_ADDONS_DIR
"
