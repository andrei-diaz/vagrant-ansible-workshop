# 📋 GUÍA PASO A PASO (Windows + VirtualBox)

## 🎯 Objetivo
Ejecutar el taller completo en Windows 10/11 usando Vagrant + VirtualBox, con 5 VMs simultáneas y aprovisionamiento automático (Ansible ejecutándose dentro de las VMs con ansible_local).

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

### Paso 1.2: Preparar Vagrantfile para Windows + VirtualBox
Copia y reemplaza tu Vagrantfile con el siguiente contenido (ajusta la ruta del synced_folder si usas otro path para tu app CakePHP):

```ruby path=null start=null
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Ubuntu 22.04 x86_64 para VirtualBox
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = true

  # =========================
  # LOAD BALANCER
  # =========================
  config.vm.define "loadbalancer" do |lb|
    lb.vm.hostname = "examenes-lb"
    lb.vm.network "private_network", ip: "192.168.56.10"
    lb.vm.network "forwarded_port", guest: 80, host: 8080

    lb.vm.provider "virtualbox" do |vb|
      vb.memory = 512
      vb.cpus = 1
    end

    lb.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/load_balancer.yml"
      ansible.inventory_path = "/vagrant/ansible/inventory/hosts_win"
      ansible.limit = "loadbalancer"
      ansible.install = true
    end
  end

  # =========================
  # WEB SERVER
  # =========================
  config.vm.define "webserver" do |web|
    web.vm.hostname = "examenes-web"
    web.vm.network "private_network", ip: "192.168.56.20"

    web.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end

    # Ajusta este path a tu ruta local del proyecto CakePHP
    web.vm.synced_folder "../TecSoft/examenes_sistema", "/var/www/examenes_sistema", type: "rsync",
      rsync__exclude: [".git/", "tmp/", "logs/", "vendor/"]

    web.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/web_server.yml"
      ansible.inventory_path = "/vagrant/ansible/inventory/hosts_win"
      ansible.limit = "webservers"
      ansible.install = true
    end
  end

  # =========================
  # DATABASE
  # =========================
  config.vm.define "database" do |db|
    db.vm.hostname = "examenes-db"
    db.vm.network "private_network", ip: "192.168.56.30"
    db.vm.network "forwarded_port", guest: 5432, host: 5433

    db.vm.provider "virtualbox" do |vb|
      vb.memory = 1536
      vb.cpus = 2
    end

    db.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/database.yml"
      ansible.inventory_path = "/vagrant/ansible/inventory/hosts_win"
      ansible.limit = "database"
      ansible.install = true
    end
  end

  # =========================
  # MONITORING
  # =========================
  config.vm.define "monitoring" do |mon|
    mon.vm.hostname = "examenes-monitoring"
    mon.vm.network "private_network", ip: "192.168.56.40"
    mon.vm.network "forwarded_port", guest: 3000, host: 3000
    mon.vm.network "forwarded_port", guest: 9090, host: 9090

    mon.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 2
    end

    mon.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/monitoring.yml"
      ansible.inventory_path = "/vagrant/ansible/inventory/hosts_win"
      ansible.limit = "monitoring"
      ansible.install = true
    end
  end

  # =========================
  # ORCHESTRATOR (opcional)
  # =========================
  config.vm.define "orchestrator" do |orch|
    orch.vm.hostname = "examenes-orchestrator"
    orch.vm.network "private_network", ip: "192.168.56.50"

    orch.vm.provider "virtualbox" do |vb|
      vb.memory = 512
      vb.cpus = 1
    end

    # Instalar Ansible dentro del orquestador (opcional)
    orch.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      sudo apt-get install -y software-properties-common
      sudo add-apt-repository --yes --update ppa:ansible/ansible
      sudo apt-get install -y ansible
      echo "Orchestrator listo. Puedes ejecutar:"
      echo "ansible-playbook -i /vagrant/ansible/inventory/hosts_win /vagrant/ansible/site.yml"
    SHELL
  end
end
```

### Paso 1.3: Crear inventario para Windows (ansible/inventory/hosts_win)
Este inventario apunta a las IPs privadas. ansible_local lo usará para aplicar cada play en su VM; y si usas el orquestador, también puede ejecutar site.yml a las otras VMs:

```ini path=null start=null
[loadbalancer]
examenes-lb ansible_host=192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=/vagrant/.vagrant/machines/loadbalancer/virtualbox/private_key

[webservers]
examenes-web ansible_host=192.168.56.20 ansible_user=vagrant ansible_ssh_private_key_file=/vagrant/.vagrant/machines/webserver/virtualbox/private_key

[database]
examenes-db ansible_host=192.168.56.30 ansible_user=vagrant ansible_ssh_private_key_file=/vagrant/.vagrant/machines/database/virtualbox/private_key

[monitoring]
examenes-monitoring ansible_host=192.168.56.40 ansible_user=vagrant ansible_ssh_private_key_file=/vagrant/.vagrant/machines/monitoring/virtualbox/private_key

[orchestrator]
examenes-orchestrator ansible_host=192.168.56.50 ansible_user=vagrant ansible_ssh_private_key_file=/vagrant/.vagrant/machines/orchestrator/virtualbox/private_key

[examenes_infrastructure:children]
loadbalancer
webservers
database
monitoring
```

Nota: Ya se actualizaron los binarios de Prometheus y Node Exporter a linux-amd64 en el playbook de monitoring.

---

## FASE 2: INICIO DE LA INFRAESTRUCTURA

### Paso 2.1: Levantar la Base de Datos
```powershell
vagrant up database
```

#### Verificar PostgreSQL dentro de la VM
```powershell
vagrant ssh database -c "sudo systemctl status postgresql --no-pager"
vagrant ssh database -c "sudo -u postgres psql -d examenes_db -c \"\\dt\""
```

#### Probar acceso desde Windows (port forwarding)
```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 5433
```

### Paso 2.2: Levantar el Servidor Web
```powershell
vagrant up webserver
```

#### Verificar servicios dentro de la VM
```powershell
vagrant ssh webserver -c "sudo systemctl status nginx --no-pager"
vagrant ssh webserver -c "sudo systemctl status php8.3-fpm --no-pager"
```

### Paso 2.3: Levantar el Load Balancer
```powershell
vagrant up loadbalancer
```

#### Verificar desde Windows
```powershell
Invoke-WebRequest -UseBasicParsing -Uri http://localhost:8080 | Select-Object -ExpandProperty StatusCode
# Para abrir en navegador
start http://localhost:8080
```

### Paso 2.4: Levantar Monitoreo
```powershell
vagrant up monitoring
```

#### Verificar desde Windows
```powershell
Invoke-WebRequest -UseBasicParsing -Uri http://localhost:3000 | Select-Object -ExpandProperty StatusCode
Invoke-WebRequest -UseBasicParsing -Uri http://localhost:9090 | Select-Object -ExpandProperty StatusCode
start http://localhost:3000
```

---

## FASE 3: PRUEBAS DE CONECTIVIDAD ENTRE VMs
Con VirtualBox, la red privada 192.168.56.0/24 funciona entre VMs.
```powershell
vagrant ssh webserver -c "nc -zv -w3 192.168.56.30 5432"
vagrant ssh loadbalancer -c "nc -zv -w3 192.168.56.20 80"
```

---

## FASE 4: PRUEBAS DE APLICACIÓN

### 4.1 PostgreSQL desde Windows
```powershell
# Requiere psql instalado (via Chocolatey)
$env:PGPASSWORD = 'examenes_password_123'
psql -h 127.0.0.1 -p 5433 -U examenes_user -d examenes_db -c "\\dt"
```

### 4.2 Verificación Web
```powershell
start http://localhost:8080
```

### 4.3 Monitoreo
```powershell
start http://localhost:3000
start http://localhost:9090
```

---

## TROUBLESHOOTING (Windows)

- Ver puertos en uso:
```powershell
netstat -ano | findstr :8080
netstat -ano | findstr :5433
```

- Probar puerto:
```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 5433
```

- Reiniciar una VM:
```powershell
vagrant reload [vm_name] --provision
```

---

## RESUMEN DE PUERTOS

| Servicio | VM | IP Interna | Puerto | Acceso desde Windows |
|---|---|---|---|---|
| PostgreSQL | database | 192.168.56.30 | 5432 | localhost:5433 |
| App Web | webserver | 192.168.56.20 | 80 | vía LB http://localhost:8080 |
| Load Balancer | loadbalancer | 192.168.56.10 | 80 | http://localhost:8080 |
| Grafana | monitoring | 192.168.56.40 | 3000 | http://localhost:3000 |
| Prometheus | monitoring | 192.168.56.40 | 9090 | http://localhost:9090 |

---

## ✅ CHECKLIST FINAL
- [ ] VMs arriba en VirtualBox
- [ ] PostgreSQL accesible en localhost:5433
- [ ] App accesible en http://localhost:8080
- [ ] Grafana accesible en http://localhost:3000
- [ ] Pruebas dentro de VMs correctas
