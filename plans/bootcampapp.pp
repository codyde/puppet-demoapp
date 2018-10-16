
  Package {'nginx':
         ensure => present,
     }

  exec { 'git clone':
     command => '/usr/bin/git clone -b standalone-p https://github.com/codyde/cmbu-bootcamp-app /tmp/cmbu-bootcamp-app'
     }


  file { "/tmp/cmbu-bootcamp-app/frontend-tier/src/app/app.component.html":
    ensure  => file,
    force   => true,
    content => epp('/puppet-demoapp/templates/app.component.html.epp'),
    require => Exec['git clone']
    }

  file { "/etc/nginx/conf.d/default.conf":
     ensure => file,
     force  => true, 
     source => '/tmp/cmbu-bootcamp-app/frontend-tier/nginx/default.conf',
     require => Exec['git clone']
     }

  exec { 'remove default nginx':
     command => '/bin/rm -rf /etc/nginx/sites-available/default',
     require => File['/etc/nginx/conf.d/default.conf']
     }

  exec { 'install repo':
      command => '/usr/bin/curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -',
      require => File['/tmp/cmbu-bootcamp-app/frontend-tier/src/app/app.component.html']
      }

  exec { 'install node':
      command => '/usr/bin/apt install nodejs',
      require => Exec['install repo']
      }

  exec { '@angular/cli':
     command   => '/usr/bin/npm install -g @angular/cli',
     require => Exec['install node']
       }

  exec { 'npm install':
     command => '/usr/bin/npm i --save',
     cwd     => '/tmp/cmbu-bootcamp-app/frontend-tier',
     creates => '/tmp/cmbu-bootcamp-app/frontend-tier/node_modules',
     require => Exec['@angular/cli']
        }

  exec { 'ng build --prod':
     command => '/usr/bin/ng build --prod',
     cwd     => '/tmp/cmbu-bootcamp-app/frontend-tier',
     creates => '/tmp/cmbu-bootcamp-app/frontend-tier/dist/cmbu-bootcamp-app',
     require => Exec['npm install']
     }

  file { '/usr/share/nginx/html':
        ensure => 'directory',
        source => '/tmp/cmbu-bootcamp-app/frontend-tier/dist/cmbu-bootcamp-app',
        recurse => true,
        force => true,
        require => Exec['ng build --prod']
        }

  exec { 'remove old nginx confs':
        command => '/bin/rm -rf /etc/nginx/sites-available/* && /bin/rm -rf /etc/nginx/sites-enabled/*',
        require => File['/usr/share/nginx/html']
        }

  exec { 'restart nginx':
       command => '/bin/systemctl restart nginx',
       require => Exec['remove old nginx confs']
        }
