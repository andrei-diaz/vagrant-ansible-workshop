# 📋 GUÍA PASO A PASO: Taller Vagrant + Ansible

## 🎯 Objetivo
Esta guía te llevará paso a paso para ejecutar el taller completo y verificar que cada componente funcione correctamente.

---

## FASE 1: PREPARACIÓN INICIAL

### Paso 1.1: Verificar Ubicación y Dependencias
```bash
# 1. Verificar que estás en el directorio correcto
pwd
# Debe mostrar: /Users/andreidiazrosario/Documents/School/vagrant-ansible-workshop

# 2. Verificar que Vagrant funciona
vagrant --version
# Debe mostrar: Vagrant 2.4.9

# 3. Verificar plugin QEMU
vagrant plugin list | grep vagrant-qemu
# Debe mostrar: vagrant-qemu (0.3.12)

# 4. Verificar QEMU
qemu-system-aarch64 --version
# Debe mostrar información de QEMU 10.x
```

### Paso 1.2: Verificar Estructura del Proyecto
```bash
# Listar archivos del taller
ls -la
# Debes ver: Vagrantfile, README.md, GUIA_PASO_A_PASO.md, ansible/

# Verificar estructura de Ansible
tree ansible/
# O si no tienes tree:
find ansible/ -type f
```

**CHECKPOINT 1**: Si todo se ve correcto, continúa. Si hay errores, revisa la instalación.

---

## FASE 2: INICIO DE LA INFRAESTRUCTURA

### Paso 2.1: Levantar la Primera VM (Base de Datos)
```bash
# Iniciar solo la VM de base de datos
vagrant up database

# TIEMPO ESTIMADO: 8-12 minutos
# QUÉ ESTÁ PASANDO:
# - Descarga la box ARM64 (primera vez)
# - Crea la VM con 1.5GB RAM
# - Instala PostgreSQL 15
# - Configura la base de datos
# - Crea tablas y datos de prueba
```

#### 🔍 Verificar que la Base de Datos Funciona
```bash
# 1. Verificar estado de la VM
vagrant status database
# Debe mostrar: running (qemu)

# 2. Conectar por SSH a la VM
vagrant ssh database

# 3. DENTRO DE LA VM, verificar PostgreSQL
sudo systemctl status postgresql
# Debe mostrar: active (running)

# 4. DENTRO DE LA VM, conectar a la base de datos
sudo -u postgres psql -d examenes_db -c "\dt"
# Debe mostrar las tablas: users, reactivos

# 5. DENTRO DE LA VM, verificar datos de prueba
sudo -u postgres psql -d examenes_db -c "SELECT email, role FROM users;"
# Debe mostrar el usuario admin@examenes.com

# 6. Salir de la VM
exit
```

Nota: El mensaje "could not change directory to /home/vagrant: Permission denied" al usar `sudo -u postgres psql` es inofensivo y se puede ignorar.

#### 🔗 Verificar Conectividad desde tu Mac
```bash
# Método recomendado (port forwarding desde tu Mac)
# Verifica que el puerto local 5433 esté abierto
nc -zv 127.0.0.1 5433
# Debe mostrar: Connection to 127.0.0.1 port 5433 succeeded!
```

**✅ CHECKPOINT 2**: La base de datos debe estar corriendo y accesible.

---

### Paso 2.2: Levantar el Servidor Web
```bash
# Iniciar la VM del servidor web
vagrant up webserver

# ⏰ TIEMPO ESTIMADO: 10-15 minutos
# ✨ QUÉ ESTÁ PASANDO:
# - Crea VM con 2GB RAM
# - Instala PHP 8.3 + Nginx
# - Sincroniza tu código CakePHP
# - Instala dependencias con Composer
# - Configura el servidor web
```

#### 🔍 Verificar que el Servidor Web Funciona
```bash
# 1. Verificar estado
vagrant status webserver
# Debe mostrar: running (qemu)

# 2. Conectar por SSH
vagrant ssh webserver

# 3. DENTRO DE LA VM, verificar servicios
sudo systemctl status nginx
sudo systemctl status php8.3-fpm
# Ambos deben mostrar: active (running)

# 4. DENTRO DE LA VM, verificar la aplicación
ls -la /var/www/examenes_sistema/
# Debe mostrar los archivos de tu proyecto CakePHP

# 5. DENTRO DE LA VM, probar PHP
php --version
# Debe mostrar: PHP 8.3.x

# 6. DENTRO DE LA VM, verificar configuración CakePHP
cd /var/www/examenes_sistema
php bin/cake.php version
# Debe mostrar información de CakePHP 5

# 7. Salir de la VM
exit
```

#### 🌐 Verificar Acceso Web
```bash
# En macOS + qemu, verifica desde dentro de la VM (la red privada puede no ser accesible desde el host)
vagrant ssh webserver -c "curl -I http://127.0.0.1"
# Debe mostrar: HTTP/1.1 200 OK o 302 Found

# Desde tu Mac, accederás al sitio a través del Load Balancer en el siguiente paso: http://localhost:8080
```

**✅ CHECKPOINT 3**: El servidor web debe estar sirviendo tu aplicación CakePHP.

---

### Paso 2.3: Levantar el Load Balancer
```bash
# Iniciar la VM del load balancer
vagrant up loadbalancer

# ⏰ TIEMPO ESTIMADO: 5-8 minutos
# ✨ QUÉ ESTÁ PASANDO:
# - Crea VM ligera (512MB RAM)
# - Instala y configura Nginx como proxy reverso
# - Configura balanceador hacia el webserver
```

#### 🔍 Verificar que el Load Balancer Funciona
```bash
# 1. Verificar estado
vagrant status loadbalancer

# 2. Conectar por SSH
vagrant ssh loadbalancer

# 3. DENTRO DE LA VM, verificar Nginx
sudo systemctl status nginx
sudo nginx -t
# Debe mostrar: syntax is ok y test is successful

# 4. DENTRO DE LA VM, ver configuración del proxy
sudo cat /etc/nginx/sites-available/examenes-lb
# Debe mostrar la configuración del upstream hacia 192.168.56.20

# 5. Salir de la VM
exit
```

#### 🔗 Verificar Load Balancer desde tu Mac
```bash
# Probar el port forwarding (principal desde macOS)
curl -I http://localhost:8080
# Debe mostrar respuesta HTTP

# Abrir en navegador
open http://localhost:8080

# (Opcional) Verificar dentro de la VM
vagrant ssh loadbalancer -c "curl -I http://127.0.0.1"
```

**✅ CHECKPOINT 4**: Debes poder acceder a tu aplicación via http://localhost:8080

---

### Paso 2.4: Levantar Monitoreo
```bash
# Iniciar la VM de monitoreo
vagrant up monitoring

# ⏰ TIEMPO ESTIMADO: 8-10 minutos
# ✨ QUÉ ESTÁ PASANDO:
# - Instala Grafana y Prometheus
# - Configura dashboards
# - Configura métricas de las otras VMs
```

#### 🔍 Verificar Monitoreo
```bash
# 1. SSH a la VM
vagrant ssh monitoring

# 2. DENTRO DE LA VM, verificar servicios
sudo systemctl status grafana-server
sudo systemctl status prometheus
# Ambos deben estar active (running)

# 3. Salir de la VM
exit

# 4. Verificar desde tu Mac (puertos forwardeados)
curl -I http://localhost:3000   # Grafana
curl -I http://localhost:9090   # Prometheus

# 5. Abrir Grafana en el navegador
open http://localhost:3000
# Usuario: admin, Password: admin

# (Opcional) Verificar dentro de la VM
vagrant ssh monitoring -c "curl -I http://127.0.0.1:3000"
vagrant ssh monitoring -c "curl -I http://127.0.0.1:9090"
```

**✅ CHECKPOINT 5**: Grafana debe estar accesible en http://localhost:3000

---

## 🎯 FASE 3: VERIFICACIÓN COMPLETA DEL SISTEMA

### Paso 3.1: Estado General de las VMs
```bash
# Ver todas las VMs
vagrant status
# Todas deben mostrar: running (qemu)

# Ver uso de recursos
vagrant ssh database -c "free -h && df -h"
vagrant ssh webserver -c "free -h && df -h"
vagrant ssh loadbalancer -c "free -h && df -h"
vagrant ssh monitoring -c "free -h && df -h"
```

### Paso 3.2: Prueba de Conectividad entre VMs
```bash
# Desde webserver, probar conexión a database
vagrant ssh webserver -c "nc -zv 192.168.56.30 5432"
# Debe conectar exitosamente

# Desde loadbalancer, probar conexión a webserver
vagrant ssh loadbalancer -c "nc -zv 192.168.56.20 80"
# Debe conectar exitosamente
```

### Paso 3.3: Prueba de la Aplicación Completa
```bash
# 1. Acceder desde tu navegador a:
open http://localhost:8080

# 2. Verificar que carga la aplicación CakePHP
# Debes ver la página de inicio del sistema de exámenes

# 3. Probar login (si está configurado)
# Usuario: admin@examenes.com
# Password: admin123

# 4. Verificar base de datos desde aplicación
# La app debe mostrar datos de reactivos/preguntas
```

---

## 🔍 FASE 4: PRUEBAS ESPECÍFICAS POR COMPONENTE

### 4.1: Pruebas de Base de Datos
```bash
# Conectar directamente a PostgreSQL desde tu Mac
# (Necesitas tener psql instalado: brew install postgresql)
psql -h localhost -p 5433 -U examenes_user -d examenes_db
# Password: examenes_password_123

# DENTRO DE PSQL, ejecutar:
\dt              # Listar tablas
SELECT COUNT(*) FROM users;        # Contar usuarios
SELECT COUNT(*) FROM reactivos;    # Contar preguntas
\q               # Salir
```

### 4.2: Pruebas de Servidor Web
```bash
# Probar diferentes endpoints
curl http://192.168.56.20/
curl http://192.168.56.20/users/login
curl http://192.168.56.20/reactivos

# Verificar logs del servidor
vagrant ssh webserver -c "sudo tail -f /var/log/nginx/access.log"
# (Ctrl+C para salir)
```

### 4.3: Pruebas de Load Balancer
```bash
# Hacer múltiples requests para ver balanceador
for i in {1..5}; do curl -s http://localhost:8080 | head -1; done

# Ver logs del load balancer
vagrant ssh loadbalancer -c "sudo tail -f /var/log/nginx/access.log"
```

### 4.4: Pruebas de Monitoreo
```bash
# Acceder a Prometheus
open http://localhost:9090

# En Prometheus, probar queries:
# - up{job="node"}
# - node_cpu_seconds_total

# Acceder a Grafana
open http://localhost:3000
# Explorar dashboards predefinidos
```

---

## 🚨 TROUBLESHOOTING: Qué Hacer Si Algo No Funciona

### Error: VM No Inicia
```bash
# 1. Destruir y recrear
vagrant destroy database -f
vagrant up database

# 2. Ver logs detallados
VAGRANT_LOG=info vagrant up database

# 3. Verificar recursos del sistema
free -h  # En tu Mac
df -h    # En tu Mac
```

### Error: Servicio No Responde
```bash
# 1. Verificar dentro de la VM
vagrant ssh [vm_name]
sudo systemctl status [service]
sudo journalctl -u [service] -f

# 2. Reiniciar servicio
sudo systemctl restart [service]
```

### Error: No Hay Conectividad
```bash
# 1. Verificar redes
ifconfig | grep 192.168.56

# 2. Reiniciar networking
vagrant reload [vm_name] --provision

# 3. Verificar puertos
netstat -tulpn | grep [puerto]
```

#### Caso en macOS (qemu): No responde 192.168.56.30:5432
- En Macs con chip Apple (M1/M2/M3) usando el proveedor qemu, la red privada (host-only) puede no ser accesible desde el host.
- SOLUCIÓN: usa siempre el port forwarding definido en Vagrantfile.
  - PostgreSQL: 127.0.0.1:5433 -> VM(database):5432
  - Web (vía load balancer): http://localhost:8080
- No es necesario cambiar la configuración de PostgreSQL dentro de la VM para esto; el forward funciona aunque `listen_addresses` sea `localhost` dentro de la VM.

---

## 📊 RESUMEN DE PUERTOS Y ACCESOS

| Servicio | VM | IP Interna | Puerto | Acceso desde Mac |
|---|---|---|---|---|
| **PostgreSQL** | database | 192.168.56.30 | 5432 | localhost:5433 (recomendado) |
| **Aplicación Web** | webserver | 192.168.56.20 | 80 | http://192.168.56.20 |
| **Load Balancer** | loadbalancer | 192.168.56.10 | 80 | http://localhost:8080 |
| **Grafana** | monitoring | 192.168.56.40 | 3000 | http://localhost:3000 |
| **Prometheus** | monitoring | 192.168.56.40 | 9090 | http://localhost:9090 |

---

## 🎯 FLUJO COMPLETO DE PRUEBAS

### Escenario 1: Acceso Normal del Usuario
```bash
1. Usuario accede: http://localhost:8080
2. Load Balancer recibe request en 192.168.56.10:80
3. Load Balancer redirige a Web Server 192.168.56.20:80
4. Web Server ejecuta PHP/CakePHP
5. CakePHP consulta base de datos en 192.168.56.30:5432
6. Respuesta regresa por el mismo camino
```

### Escenario 2: Monitoreo del Sistema
```bash
1. Prometheus recolecta métricas de todas las VMs
2. Grafana consulta Prometheus para dashboards
3. Admin accede a http://localhost:3000 para ver métricas
```

---

## ✅ CHECKLIST FINAL

Marca cada item cuando lo hayas verificado:

- [ ] PostgreSQL corriendo en database VM
- [ ] Datos de prueba cargados en la BD
- [ ] Nginx + PHP corriendo en webserver VM  
- [ ] Aplicación CakePHP accesible
- [ ] Load balancer redirigiendo tráfico
- [ ] Aplicación accesible en http://localhost:8080
- [ ] Grafana accesible en http://localhost:3000
- [ ] Prometheus recolectando métricas
- [ ] Login funcionando en la aplicación
- [ ] Base de datos respondiendo consultas

---

## 🎉 ¡ÉXITO!

Si todos los checkpoints están marcados, ¡felicidades! Tienes:

✅ **Infraestructura completa** funcionando  
✅ **Aplicación real** desplegada automáticamente  
✅ **Monitoreo** operativo  
✅ **Alta disponibilidad** configurada  
✅ **Automatización** completa con Vagrant + Ansible  

**Tu sistema de exámenes médicos está corriendo en una infraestructura de clase mundial! 🏥⚡**