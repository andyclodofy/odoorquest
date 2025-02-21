#!/bin/bash

# Script para instalar Odoo 18 desde el repositorio odoo/odoo en un entorno on-premise (Debian/Ubuntu)
# Sin interacciones durante la ejecución, con archivos centralizados y re-ejecutable
# Utiliza el usuario actual y se ejecuta con sudo
# Comandos que requieren permisos de root

# Cargar el archivo de configuración
source config.sh

# Función para verificar si un comando se ejecutó correctamente
check_success() {
  if [ $? -ne 0 ]; then
    echo "Error: El comando anterior falló."
    exit 1
  fi
}

# Actualizar el sistema
echo "Actualizando el sistema..."
apt update && apt upgrade -y
check_success

# Instalar dependencias
echo "Instalando dependencias..."
if ! dpkg -l | grep -q "git"; then
  apt install -y git python3-pip python3-venv wget build-essential \
      libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev python3-dev \
      node-less libjpeg-dev zlib1g-dev libpq-dev postgresql
  check_success
else
  echo "Las dependencias ya están instaladas."
fi

# Verificar e instalar python3-venv
echo "Verificando e instalando python3-venv..."
if ! dpkg -l | grep -q "python3-venv"; then
  apt install -y python3-venv
  check_success
else
  echo "python3-venv ya está instalado."
fi

# Instalar PostgreSQL si no está instalado
echo "Verificando e instalando PostgreSQL..."
if ! id -u "postgres" > /dev/null 2>&1; then
  echo "PostgreSQL no está instalado. Instalando..."
  apt install -y postgresql
  check_success
else
  echo "PostgreSQL ya está instalado."
fi

# Configurar PostgreSQL
echo "Configurando PostgreSQL..."
if ! sudo su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'\"" | grep -q 1; then
  echo "Creando usuario $DB_USER en PostgreSQL..."
  sudo su - postgres -c "psql -c \"CREATE USER $DB_USER WITH PASSWORD '$DB_PASS' CREATEDB;\""
  check_success
else
  echo "El usuario $DB_USER ya existe en PostgreSQL."
fi

# Otorgar permisos CREATEDB al usuario si no los tiene
echo "Verificando permisos de CREATEDB para el usuario $DB_USER..."
if ! sudo su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$DB_USER' AND rolcreatedb=true\"" | grep -q 1; then
  echo "Otorgando permisos CREATEDB al usuario $DB_USER..."
  sudo su - postgres -c "psql -c \"ALTER USER $DB_USER CREATEDB;\""
  check_success
else
  echo "El usuario $DB_USER ya tiene permisos CREATEDB."
fi

# Crear script de inicio para Odoo
echo "Creando script de inicio para Odoo..."
if [ ! -f /etc/systemd/system/odoo.service ]; then
  cp odoo.service.template /etc/systemd/system/odoo.service
  sed -i "s|ODOO_USER|$ODOO_USER|g" /etc/systemd/system/odoo.service
  sed -i "s|ODOO_SERVER|$ODOO_SERVER|g" /etc/systemd/system/odoo.service
  sed -i "s|ODOO_CONFIG_FILE|$ODOO_CONFIG_FILE|g" /etc/systemd/system/odoo.service
  check_success
else
  echo "El archivo de servicio Odoo ya existe."
fi

# Iniciar y habilitar el servicio Odoo
echo "Iniciando y habilitando el servicio Odoo..."
systemctl daemon-reload
systemctl enable odoo
systemctl start odoo
check_success

echo "Instalación y configuración completadas correctamente."
