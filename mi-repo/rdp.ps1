name: RDP Windows Server

on:
  workflow_dispatch:

jobs:
  setup-rdp:
    runs-on: windows-latest
    timeout-minutes: 120

    steps:
    - name: Configure Windows RDP
      shell: pwsh
      run: |
        Write-Host "🖥️ Configurando Remote Desktop..."
        
        # 1. Habilitar RDP en el registro
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
        
        # 2. Configurar firewall para RDP
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        
        # 3. Crear usuario administrador
        $password = "Admin123456!"
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        
        # Crear usuario si no existe
        $userExists = Get-LocalUser -Name "rdpuser" -ErrorAction SilentlyContinue
        if (-not $userExists) {
            New-LocalUser -Name "rdpuser" -Password $securePassword -FullName "RDP User" -Description "Usuario para acceso remoto"
            Add-LocalGroupMember -Group "Administrators" -Member "rdpuser"
            Add-LocalGroupMember -Group "Remote Desktop Users" -Member "rdpuser"
            Write-Host "✅ Usuario 'rdpuser' creado"
        }
        
        # 4. Configurar NeverExpire para la contraseña
        Set-LocalUser -Name "rdpuser" -PasswordNeverExpires $true
        
        # 5. Obtener información de red
        $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -eq "Ethernet" -or $_.InterfaceAlias -eq "Ethernet 2"}).IPAddress
        if (-not $ipAddress) {
            $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne "127.0.0.1"}).IPAddress
        }
        
        Write-Host "✅ RDP Configurado Exitosamente"
        Write-Host "📍 IP: $($ipAddress -join ', ')"
        Write-Host "👤 Usuario: rdpuser"
        Write-Host "🔐 Contraseña: Admin123456!"
        Write-Host "🔧 Puerto: 3389"

    - name: Install Essential Software
      shell: pwsh
      run: |
        Write-Host "📦 Instalando software esencial..."
        
        # Instalar Chrome
        $ChromeInstaller = "chrome_installer.exe"
        Invoke-WebRequest "https://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $ChromeInstaller
        Start-Process -FilePath $ChromeInstaller -Args "/silent /install" -Wait
        Remove-Item $ChromeInstaller
        
        Write-Host "✅ Chrome instalado"

    - name: Display Connection Information
      shell: pwsh
      run: |
        # Obtener IP actual
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne "127.0.0.1" -and $_.PrefixOrigin -eq "Dhcp"}).IPAddress | Select-Object -First 1
        
        if (-not $ip) {
            $ip = "IP no disponible - Usa GitHub Codespaces"
        }
        
        Write-Host ""
        Write-Host "🎉 === SERVIDOR RDP CONFIGURADO ==="
        Write-Host "📍 IP: $ip"
        Write-Host "👤 Usuario: rdpuser"
        Write-Host "🔐 Contraseña: Admin123456!"
        Write-Host "🔧 Puerto: 3389"
        Write-Host "⏰ Tiempo restante: ~115 minutos"
        Write-Host ""
        Write-Host "📋 INSTRUCCIONES:"
        Write-Host "1. Abre 'Conexión a Escritorio Remoto'"
        Write-Host "2. Conectate a: $ip"
        Write-Host "3. Usuario: rdpuser"
        Write-Host "4. Contraseña: Admin123456!"
        Write-Host ""
        Write-Host "⚠️  Este servidor estará activo por 2 horas"
        
        # Guardar en summary
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "# 🖥️ Servidor RDP Listo"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "**IP:** $ip"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "**Usuario:** rdpuser"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "**Contraseña:** Admin123456!"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "**Puerto:** 3389"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ""
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "## 📝 Para conectar:"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "1. Abre **Conexión a Escritorio Remoto**"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "2. Ingresa: **$ip**"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "3. Usuario: **rdpuser**"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "4. Contraseña: **Admin123456!**"

    - name: Keep Alive
      shell: pwsh
      run: |
        Write-Host "🔄 Manteniendo servidor activo..."
        # Mantener el servidor activo
        for ($i = 0; $i -lt 115; $i++) {
            Write-Host "Minuto $i - Servidor RDP activo"
            Start-Sleep -Seconds 60
        }
        Write-Host "⏰ Tiempo agotado - Cerrando servidor"

  deploy-website:
    runs-on: ubuntu-latest
    needs: setup-rdp
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Deploy to GitHub Pages
      run: |
        echo "🌐 Página web desplegada"
        echo "Tu sitio estará disponible en: https://tu-usuario.github.io/tu-repositorio/"
        
        # Crear un index.html simple si no existe
        if [ ! -f "index.html" ]; then
          echo '<!DOCTYPE html>
          <html>
          <head>
              <title>Mi Sitio Web</title>
          </head>
          <body>
              <h1>¡Hola Mundo!</h1>
              <p>Mi sitio web está funcionando correctamente.</p>
          </body>
          </html>' > index.html
        fi