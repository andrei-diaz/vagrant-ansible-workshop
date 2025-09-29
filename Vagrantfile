# -*- mode: ruby -*-
# vi: set ft=ruby :

# Taller Vagrant + Ansible: Sistema de Exámenes Médicos
# Arquitectura Multi-VM con aprovisionamiento automatizado
# Configurado para Windows + VirtualBox

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Box x86_64 compatible con VirtualBox en Windows
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false
  
  # Configuración global para VirtualBox
  config.vm.provider "virtualbox" do |vb|
    # Habilitar GUI si es necesario (descomentrar la siguiente línea)
    vb.gui = true
    
    # Configuraciones de red y sistema
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end
  
  # Configuración de SSH para Windows
  config.ssh.forward_agent = true
  config.ssh.insert_key = false
  config.vm.boot_timeout = 600  # 10 minutos timeout

  # ===========================================
  # LOAD BALANCER - Nginx Proxy Reverso
  # ===========================================
  config.vm.define "loadbalancer" do |lb|
    lb.vm.hostname = "examenes-lb"
    lb.vm.network "private_network", ip: "192.168.56.10"
    lb.vm.network "forwarded_port", guest: 22, host: 50021, auto_correct: true
    lb.vm.network "forwarded_port", guest: 80, host: 8080
    
    lb.vm.provider "virtualbox" do |vb|
      vb.name = "examenes-lb"
      vb.memory = 512
      vb.cpus = 1
    end
    
    # Provision con Ansible Local
    lb.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/load_balancer.yml"
      ansible.inventory_path = "ansible/inventory/hosts_local"
      ansible.limit = "loadbalancer"
      ansible.install_mode = "default"
      ansible.provisioning_path = "/vagrant"
    end
  end

  # ===========================================
  # WEB SERVER - PHP + CakePHP 5
  # ===========================================
  config.vm.define "webserver" do |web|
    web.vm.hostname = "examenes-web"
    web.vm.network "private_network", ip: "192.168.56.20"
    web.vm.network "forwarded_port", guest: 22, host: 50023, auto_correct: true
    
    web.vm.provider "virtualbox" do |vb|
      vb.name = "examenes-web"
      vb.memory = 2048
      vb.cpus = 2
    end
    
    # Clonado automático del código fuente desde GitHub
    web.vm.provision "shell", inline: <<-SHELL
      # Instalar Git si no está disponible
      sudo apt-get update
      sudo apt-get install -y git
      
      # Crear directorio y clonar el repositorio
      sudo mkdir -p /var/www
      sudo rm -rf /var/www/examenes_sistema
      sudo git clone https://github.com/andrei-diaz/examenes_sistema.git /var/www/examenes_sistema
      
      # Establecer permisos correctos
      sudo chown -R www-data:www-data /var/www/examenes_sistema
      sudo chmod -R 755 /var/www/examenes_sistema
      
      echo "✅ Aplicación clonada desde GitHub exitosamente"
    SHELL
    
    web.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/web_server.yml"
      ansible.inventory_path = "ansible/inventory/hosts_local"
      ansible.limit = "webservers"
      ansible.install_mode = "default"
      ansible.provisioning_path = "/vagrant"
      ansible.extra_vars = {
        app_name: "examenes_sistema",
        php_version: "8.3",
        app_env: "development"
      }
    end
  end

  # ===========================================
  # DATABASE SERVER - PostgreSQL
  # ===========================================
  config.vm.define "database" do |db|
    db.vm.hostname = "examenes-db"
    db.vm.network "private_network", ip: "192.168.56.30"
    db.vm.network "forwarded_port", guest: 22, host: 50022, auto_correct: true
    db.vm.network "forwarded_port", guest: 5432, host: 5434
    
    db.vm.provider "virtualbox" do |vb|
      vb.name = "examenes-db"
      vb.memory = 1536
      vb.cpus = 2
    end
    
    db.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/database.yml"
      ansible.inventory_path = "ansible/inventory/hosts_local"
      ansible.limit = "database"
      ansible.install_mode = "default"
      ansible.provisioning_path = "/vagrant"
      ansible.extra_vars = {
        db_name: "examenes_db",
        db_user: "examenes_user",
        db_password: "examenes_password_123",
        postgres_version: "15"
      }
    end
  end

  # ===========================================
  # TALLER SIMPLIFICADO - SOLO 3 VMs ESENCIALES
  # ===========================================
  # monitoring y orchestrator eliminadas para hacer el taller más rápido
end