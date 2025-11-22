# Script để update categories và remove descriptions cho tất cả plugins

$categoryMap = @{
    # SETUP category (cài đặt hệ thống)
    'nginx' = 'SETUP'
    'php' = 'SETUP'
    'nodejs' = 'SETUP'
    'docker' = 'SETUP'
    'preset-basic-stack' = 'SETUP'
    'setup-wizard' = 'SETUP'
    
    # DOMAIN_SSL
    'certbot' = 'DOMAIN_SSL'
    'vhost-nginx' = 'DOMAIN_SSL'
    
    # WORDPRESS
    'wordpress' = 'WORDPRESS'
    'wordpress-migrate' = 'WORDPRESS'
    
    # WP_OPTIMIZE
    'wordpress-speed' = 'WP_OPTIMIZE'
    'wordpress-security' = 'WP_OPTIMIZE'
    'wordpress-backup' = 'WP_OPTIMIZE'
    
    # NODE
    'appnode' = 'NODE'
    'app-deploy-node' = 'NODE'
    'nodeapp' = 'NODE'
    'node-app-manager' = 'NODE'
    'node-project' = 'NODE'
    'node-env' = 'NODE'
    'node-pm2-manager' = 'NODE'
    'node-logs' = 'NODE'
    'node-bluegreen' = 'NODE'
    'node-git-deploy' = 'NODE'
    'node-health' = 'NODE'
    'nodealert' = 'NODE'
    
    # DATABASE
    'mariadb' = 'DATABASE'
    'mongo' = 'DATABASE'
    'postgres' = 'DATABASE'
    'redis' = 'DATABASE'
    
    # DB_GUI
    'dbgui' = 'DB_GUI'
    'db-gui-profiles' = 'DB_GUI'
    'phpmyadmin' = 'DB_GUI'
    'pgadmin' = 'DB_GUI'
    
    # MONITORING
    'healthcheck' = 'MONITORING'
    'httpcheck' = 'MONITORING'
    'processwatch' = 'MONITORING'
    'logwatch' = 'MONITORING'
    'netdata' = 'MONITORING'
    'telegram' = 'MONITORING'
    
    # PROJECT_BACKUP
    'backup' = 'PROJECT_BACKUP'
    
    # SYSTEM_BACKUP
    'rclone-gdrive' = 'SYSTEM_BACKUP'
    
    # SECURITY
    'fail2ban' = 'SECURITY'
    'ufw' = 'SECURITY'
    
    # SYSINFO
    'system-unattended' = 'SYSINFO'
    
    # UTILITIES
    'cron' = 'UTILITIES'
    'ssh-helper' = 'UTILITIES'
}

Write-Host "Updating plugin categories and removing descriptions..." -ForegroundColor Cyan

foreach ($file in Get-ChildItem "d:\APP\nguyendc-ols\plugins\*.plugin.sh") {
    $content = Get-Content $file.FullName -Raw
    
    # Extract plugin ID from ndc_register_plugin
    if ($content -match 'ndc_register_plugin\s+\\\s+"([^"]+)"') {
        $pluginId = $Matches[1]
        
        if ($categoryMap.ContainsKey($pluginId)) {
            $newCategory = $categoryMap[$pluginId]
            
            Write-Host "Processing $($file.Name) - ID: $pluginId -> Category: $newCategory" -ForegroundColor Yellow
            
            # Replace ndc_register_plugin block:
            # Remove description (line 5) and update category
            $pattern = '(ndc_register_plugin\s+\\\s+"' + [regex]::Escape($pluginId) + '"\s+\\\s+"[^"]+"\s+\\\s+)"[^"]*"(\s+\\\s+)"[^"]*"(\s+\\\s+"[^"]+"\s*)'
            $replacement = "`$1`"$newCategory`"`$2`"`"`$3"
            
            $newContent = $content -replace $pattern, $replacement
            
            if ($newContent -ne $content) {
                Set-Content -Path $file.FullName -Value $newContent -NoNewline
                Write-Host "  ✓ Updated!" -ForegroundColor Green
            } else {
                Write-Host "  - No changes needed" -ForegroundColor Gray
            }
        }
    }
}

Write-Host "`nDone!" -ForegroundColor Green
