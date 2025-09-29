# GUÍA PASO A PASO (Windows + VirtualBox)

## Objetivo
Ejecutar el taller completo en Windows 10/11 usando Vagrant + VirtualBox, con 5 VMs simultáneas y aprovisionamiento automático con Ansible.

---

## FASE 1: PREPARACIÓN INICIAL (Windows)

### Paso 1.0: Instalar dependencias (PowerShell como Administrador)
```powershell
# Instalar Chocolatey (si no lo tienes)
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex

# Instalar VirtualBox, Vagrant y Git
choco install -y virtualbox vagrant git

# (Opcional) Cliente psql para pruebas
choco install -y postgresql
```

### Paso 1.1: Verificar instalación y ubicación
```powershell
# Directorio del proyecto
Get-Location

# Versiones
vagrant --version
VBoxManage --version
```

### Paso 1.2: Configuración del Vagrantfile
**El Vagrantfile ya está configurado para Windows + VirtualBox**

**Características principales:**
- Usa `ubuntu/jammy64` (x86_64) compatible con VirtualBox
- Configuración optimizada de VirtualBox para Windows
- Clonado automático desde GitHub
- Todos los providers configurados para VirtualBox
- Configuración de SSH adaptada para Windows

**Aplicación integrada:**
No necesitas descargar ni configurar nada manualmente. El Vagrantfile:
- Clona automáticamente desde: `https://github.com/andrei-diaz/examenes_sistema.git`
- Instala en la VM webserver en: `/var/www/examenes_sistema`
- Configura permisos automáticamente para el usuario `www-data`

Si quieres usar otro repositorio, modifica la URL en la línea 76 del Vagrantfile.

### Paso 1.3: Verificar la configuración

Puedes revisar el Vagrantfile actual para verificar todas las configuraciones.

### Paso 1.3: Entender el inventario de Ansible (NO necesitas crear nada)

**IMPORTANTE: El inventario ya existe en `ansible/inventory/hosts` y funciona automáticamente.**

Para tu referencia, así es como Ansible identifica las máquinas virtuales:

**Estructura del inventario:**
```ini
[loadbalancer]        # Grupo para el balanceador de carga
examenes-lb ansible_host=192.168.56.10

[webservers]          # Grupo para servidores web
examenes-web ansible_host=192.168.56.20

[database]            # Grupo para base de datos
examenes-db ansible_host=192.168.56.30

[monitoring]          # Grupo para monitoreo
examenes-monitoring ansible_host=192.168.56.40

[orchestrator]        # Grupo para orquestador
examenes-orchestrator ansible_host=192.168.56.50
```

**¿Qué significa esto?**
- Cada VM tiene una IP fija en la red privada 192.168.56.x
- Ansible usa estas IPs para configurar los servicios automáticamente
- Los "grupos" permiten aplicar configuración a tipos de servidores
- Por ejemplo: `[webservers]` recibe la configuración de PHP y Nginx

**No necesitas modificar nada** - Vagrant y Ansible manejan esto automáticamente.

---

## 🚨 PATRÓN COMÚN EN WINDOWS + VIRTUALBOX

**Problema frecuente:** Las VMs pueden fallar con SSH timeout en el primer `vagrant up`

**Solución universal:**
```powershell
vagrant reload [nombre_vm]   # Reinicia y ejecuta provisioning automáticamente
```

**Por qué pasa:** Windows + VirtualBox a veces tiene problemas de timing en el primer boot

**Por qué funciona:** `vagrant reload` reinicia la VM correctamente y soluciona SSH

---

## FASE 2: INICIO DE LA INFRAESTRUCTURA

### Paso 2.1: Levantar la Base de Datos
```powershell
vagrant up database
```

#### 🚨 SOLUCIONES PARA PROBLEMAS COMUNES (Windows + VirtualBox)

**PROBLEMA 1: SSH Timeout**
Si el comando anterior falla con:
```
Timed out while waiting for the machine to boot. This means that
Vagrant was unable to communicate with the guest machine...
```

**SOLUCIÓN:**
```powershell
vagrant reload database
```

**PROBLEMA 2: Datos de prueba vacíos**
Si después de que todo funcione, las tablas están vacías (0 usuarios, 0 reactivos):

**SOLUCIÓN:**
```powershell
vagrant provision database
```

**FLUJO RECOMENDADO PARA WINDOWS:**
1. `vagrant up database` ← Intenta primero
2. Si falla SSH → `vagrant reload database` ← Soluciona conexión
3. Si datos vacíos → `vagrant provision database` ← Re-ejecuta Ansible

Este flujo asegura que:
✓ La VM arranque correctamente
✓ SSH funcione sin problemas  
✓ PostgreSQL esté configurado
✓ Los datos de prueba se inserten correctamente

#### Verificaciones de la VM Database:

**1. Verificar que PostgreSQL está corriendo:**
```powershell
vagrant ssh database -c "sudo systemctl status postgresql --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**2. Verificar datos dentro de la VM:**
```powershell
# Conectarse a la VM
vagrant ssh database

# Dentro de la VM, conectar a PostgreSQL
sudo -u postgres psql -d examenes_db

# Dentro de PostgreSQL, verificar tablas
\dt

# Verificar usuarios (debe mostrar admin@examenes.com)
SELECT email, role FROM users;

# Verificar reactivos (debe mostrar al menos 3)
SELECT COUNT(*) FROM reactivos;

# Salir
\q
exit
```
**Resultado esperado:**
- Tablas: users, reactivos, examenes
- 1 usuario: admin@examenes.com
- Al menos 3 reactivos de medicina

**3. Probar acceso desde Windows (port forwarding):**
```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 5434
```
**Resultado esperado:** `TcpTestSucceeded : True`

**NOTA:** Usamos puerto 5434 para evitar conflicto con PostgreSQL local si lo tienes instalado.

### Paso 2.2: Levantar el Servidor Web
```powershell
vagrant up webserver
```

#### 🚨 SOLUCIÓN SSH TIMEOUT (si ocurre)
Si el comando anterior falla con timeout SSH:

```powershell
vagrant reload webserver
```

Este comando:
1. Reinicia la VM correctamente
2. Soluciona el problema de conexión SSH  
3. Ejecuta el script de clonado desde GitHub
4. Ejecuta automáticamente Ansible para instalar PHP 8.3 + Nginx
5. Configura CakePHP completamente

**Mensaje esperado al finalizar:**
```
==> webserver: Running provisioner: shell...
==> webserver: ✅ Aplicación clonada desde GitHub exitosamente
==> webserver: Running provisioner: ansible_local...
==> webserver: PLAY RECAP *********************************************************************
==> webserver: examenes-web            : ok=18   changed=13   unreachable=0    failed=0
```
  
#### Verificaciones de la VM Web Server:

**1. Verificar que Nginx está corriendo:**
```powershell
vagrant ssh webserver -c "sudo systemctl status nginx --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**2. Verificar que PHP-FPM está corriendo:**
```powershell
vagrant ssh webserver -c "sudo systemctl status php8.3-fpm --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**3. Verificar que la aplicación se clonó correctamente:**
```powershell
vagrant ssh webserver -c "ls -la /var/www/examenes_sistema/"
```
**Resultado esperado:** Archivos del proyecto CakePHP (src/, config/, webroot/, etc.)

**4. Verificar configuración de base de datos:**
```powershell
vagrant ssh webserver -c "cat /var/www/examenes_sistema/config/app_local.php"
```
**Resultado esperado:** Configuración con host `192.168.56.30` y usuario `examenes_user`

**5. Probar respuesta HTTP interna:**
```powershell
vagrant ssh webserver -c "curl -s -o /dev/null -w '%{http_code}' http://localhost/"
```
**Resultado esperado:** Código `200` o `302`

#### 🚨 SOLUCIÓN PARA ERROR 500 (Dependencias faltantes)
Si el comando anterior devuelve `500` (error interno):

**PROBLEMA:** Ansible no instaló las dependencias de CakePHP con Composer

**SOLUCIÓN:**
```powershell
vagrant ssh webserver -c "sudo -u www-data composer install --working-dir=/var/www/examenes_sistema --no-dev --optimize-autoloader"
```

**Qué hace este comando:**
- Instala todas las dependencias de CakePHP (directorio `vendor/`)
- Crea el autoloader optimizado para mejor rendimiento
- Se ejecuta como usuario `www-data` para permisos correctos
- Tarda ~2-3 minutos en completarse

**Verificar que funcionó:**
```powershell
vagrant ssh webserver -c "curl -s -o /dev/null -w '%{http_code}' http://localhost/"
```
**Resultado esperado después del fix:** `302` (redirect, ¡funciona!)

#### 🚨 SOLUCIÓN PARA ERRORES DE BASE DE DATOS
Si al abrir la aplicación web ves errores como:
- `permission denied for schema public`
- `Columns used in constraints must be added to the Table schema first`

**PROBLEMA:** El usuario de PostgreSQL no tiene permisos completos en el esquema

**SOLUCIÓN:**
```powershell
# Otorgar permisos de esquema
vagrant ssh database -c "sudo -u postgres psql -d examenes_db -c 'GRANT ALL PRIVILEGES ON SCHEMA public TO examenes_user;'"

# Otorgar permisos para tablas futuras  
vagrant ssh database -c "sudo -u postgres psql -d examenes_db -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO examenes_user;'"

# Arreglar permisos de logs en CakePHP
vagrant ssh webserver -c "sudo chmod -R 777 /var/www/examenes_sistema/logs && sudo chown -R www-data:www-data /var/www/examenes_sistema/logs"
```

**Verificar que funcionó:** La aplicación debe cargar sin errores de base de datos

### Paso 2.3: Levantar el Load Balancer
```powershell
vagrant up loadbalancer
```

**Mensaje esperado al finalizar:**
```
==> loadbalancer: PLAY RECAP *********************************************************************
==> loadbalancer: examenes-lb           : ok=XX   changed=XX   unreachable=0    failed=0
```

#### Verificaciones de la VM Load Balancer:

**1. Verificar que Nginx está corriendo:**
```powershell
vagrant ssh loadbalancer -c "sudo systemctl status nginx --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**2. Verificar configuración del proxy:**
```powershell
vagrant ssh loadbalancer -c "sudo nginx -t"
```
**Resultado esperado:** `nginx: configuration file /etc/nginx/nginx.conf test is successful`

**3. Verificar que puede conectar al webserver:**
```powershell
vagrant ssh loadbalancer -c "curl -s -o /dev/null -w '%{http_code}' http://192.168.56.20/"
```
**Resultado esperado:** Código `200` o `302`

**4. Probar desde Windows:**
```powershell
Invoke-WebRequest -UseBasicParsing -Uri http://localhost:8080 | Select-Object -ExpandProperty StatusCode
```
**Resultado esperado:** `200`

**5. Abrir en navegador:**
```powershell
start http://localhost:8080
```
**Resultado esperado:** Página de inicio del sistema de exámenes

## FASE 3: PRUEBAS DE CONECTIVIDAD ENTRE VMs

### 3.1 Probar conectividad entre Web Server y Database
```powershell
vagrant ssh webserver -c "nc -zv -w3 192.168.56.30 5432"
```
**Resultado esperado:** `Connection to 192.168.56.30 5432 port [tcp/postgresql] succeeded!`

### 3.2 Probar conectividad entre Load Balancer y Web Server  
```powershell
vagrant ssh loadbalancer -c "nc -zv -w3 192.168.56.20 80"
```
**Resultado esperado:** `Connection to 192.168.56.20 80 port [tcp/http] succeeded!`

---

## FASE 3: PRUEBAS FUNCIONALES DE LA APLICACIÓN

### 3.1 Probar Base de Datos desde Windows

**Conectar usando psql (requiere PostgreSQL client instalado):**
```powershell
$env:PGPASSWORD = 'examenes_password_123'
psql -h 127.0.0.1 -p 5434 -U examenes_user -d examenes_db -c "\dt"
```
**Resultado esperado:** Lista de tablas como `users`, `especialidades`, `examenes`, etc.

**Verificar datos de prueba:**
```powershell
$env:PGPASSWORD = 'examenes_password_123'
psql -h 127.0.0.1 -p 5434 -U examenes_user -d examenes_db -c "SELECT email FROM users LIMIT 3;"
```
**Resultado esperado:** 
```
              email               
----------------------------------
 admin@examenes.com
 profesor@examenes.com
 estudiante@examenes.com
```

### 3.2 Pruebas de la Aplicación Web

**1. Abrir la aplicación:**
```powershell
start http://localhost:8080
```
**Resultado esperado:** Página de inicio del Sistema de Exámenes Médicos

**2. Probar login con credenciales de administrador:**
- URL: `http://localhost:8080/login`
- Email: `admin@examenes.com`
- Password: `admin123`

**Resultado esperado:** Acceso al panel de administración

**3. Probar login con credenciales de profesor:**
- Email: `profesor@examenes.com`
- Password: `profesor123`

**Resultado esperado:** Acceso al panel de profesor

**4. Verificar que la aplicación puede conectar a la base de datos:**
```powershell
vagrant ssh webserver -c "cd /var/www/examenes_sistema && php bin/cake.php migrations status"
```
**Resultado esperado:** Estado de las migraciones (deberían estar aplicadas)

### 3.3 Prueba de Balanceador de Carga

**Verificar que el Load Balancer distribuye correctamente:**
```powershell
# Hacer múltiples requests
for($i=1; $i -le 5; $i++) {
    Invoke-WebRequest -UseBasicParsing -Uri http://localhost:8080 | Select-Object StatusCode
    Start-Sleep 1
}
```
**Resultado esperado:** Todas las respuestas deben ser 200

**Verificar logs del Load Balancer:**
```powershell
vagrant ssh loadbalancer -c "sudo tail -f /var/log/nginx/access.log"
```
**Resultado esperado:** Requests siendo loggeados en tiempo real

---

## RESUMEN DE PUERTOS Y SERVICIOS

| Servicio | VM | IP Interna | Puerto | Acceso desde Windows | Estado Esperado |
|---|---|---|---|---|---|
| PostgreSQL | database | 192.168.56.30 | 5432 | localhost:5433 | Active (running) |
| App Web | webserver | 192.168.56.20 | 80 | vía LB localhost:8080 | Active (running) |
| Load Balancer | loadbalancer | 192.168.56.10 | 80 | http://localhost:8080 | Active (running) |
| Grafana | monitoring | 192.168.56.40 | 3000 | http://localhost:3000 | Active (running) |
| Prometheus | monitoring | 192.168.56.40 | 9090 | http://localhost:9090 | Active (running) |
| Node Exporter | monitoring | 192.168.56.40 | 9100 | Interno | Active (running) |

---

## CHECKLIST DE VERIFICACIÓN COMPLETA

### Database VM (192.168.56.30)
- [ ] PostgreSQL service active
- [ ] Base de datos `examenes_db` creada
- [ ] Usuario `examenes_user` existe
- [ ] Puerto 5433 accesible desde Windows
- [ ] Tablas del sistema creadas
- [ ] Datos de prueba insertados (3 usuarios)

### Web Server VM (192.168.56.20)
- [ ] Nginx service active
- [ ] PHP 8.3-FPM service active
- [ ] Aplicación clonada en `/var/www/examenes_sistema`
- [ ] Configuración de base de datos correcta
- [ ] Permisos de archivos configurados
- [ ] Respuesta HTTP 200/302 local

### Load Balancer VM (192.168.56.10)
- [ ] Nginx service active
- [ ] Configuración de proxy correcta
- [ ] Conectividad al webserver
- [ ] Puerto 8080 accesible desde Windows
- [ ] Página de la aplicación carga correctamente

### Monitoring VM (192.168.56.40)
- [ ] Grafana service active
- [ ] Prometheus service active
- [ ] Node Exporter service active
- [ ] Puerto 3000 accesible (Grafana)
- [ ] Puerto 9090 accesible (Prometheus)
- [ ] Targets "UP" en Prometheus
- [ ] Login Grafana funcional (admin/admin)

### Pruebas de Integración
- [ ] Conectividad entre VMs verificada
- [ ] Login en aplicación con admin@examenes.com
- [ ] Login en aplicación con profesor@examenes.com
- [ ] Métricas visibles en Prometheus
- [ ] Dashboards funcionales en Grafana
- [ ] Consultas a base de datos desde Windows

### Lo que debes ver al final:
1. **http://localhost:8080** - Sistema de Exámenes funcionando
2. **http://localhost:3000** - Grafana con dashboards
3. **http://localhost:9090** - Prometheus con métricas
4. **localhost:5433** - PostgreSQL accesible
5. **VirtualBox** - 4 VMs corriendo (database, webserver, loadbalancer, monitoring)

---

## TROUBLESHOOTING (Windows)

**Ver puertos en uso:**
```powershell
netstat -ano | findstr :8080
netstat -ano | findstr :5433
netstat -ano | findstr :3000
```

**Probar conectividad a puertos:**
```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 5433  # PostgreSQL
Test-NetConnection -ComputerName 127.0.0.1 -Port 8080  # Load Balancer
Test-NetConnection -ComputerName 127.0.0.1 -Port 3000  # Grafana
```

**Reiniciar una VM con re-aprovisionamiento:**
```powershell
vagrant reload database --provision
vagrant reload webserver --provision
```

**Ver logs de una VM:**
```powershell
vagrant ssh database -c "sudo journalctl -u postgresql -f"
vagrant ssh webserver -c "sudo tail -f /var/log/nginx/error.log"
```

**Verificar estado de todas las VMs:**
```powershell
vagrant status
```
