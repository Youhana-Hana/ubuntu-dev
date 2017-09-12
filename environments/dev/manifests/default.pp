class apt_update {
    exec { "aptGetUpdate":
        command => "sudo apt-get update -y",
        path => ["/bin", "/usr/bin"]
    }
}

class othertools {
    package { "git":
        ensure => latest,
        require => Exec["aptGetUpdate"]
    }

    package { "vim-common":
        ensure => latest,
        require => Exec["aptGetUpdate"]
    }

    package { "curl":
        ensure => present,
        require => Exec["aptGetUpdate"]
    }

    package { "htop":
        ensure => present,
        require => Exec["aptGetUpdate"]
    }

    package { "g++":
        ensure => present,
        require => Exec["aptGetUpdate"]
    }

    package { "libpq-dev":
        ensure => present,
        require => Exec["aptGetUpdate"]
    }
}

class nodejs {
	exec { 
		"get-nave":
			command => "/usr/bin/git clone https://github.com/isaacs/nave.git /usr/local/src/nave",
			creates => "/usr/local/src/nave",
			user => root,
			require => [Package['git']] 
	} 

	file { "/usr/local/bin/nave":
    ensure => link,
    target => "/usr/local/src/nave/nave.sh",
		require => [Exec['get-nave']]
  }

	exec { 
		"get-node":
			command => "/usr/local/src/nave/nave.sh usemain 6.11.1 > /var/tmp/node-6.11.1-complete",
			creates => "/var/tmp/node-6.11.1-complete",
			user => root,
			timeout => 1200,
			require => [Exec['get-nave']] 
	}
	
	exec { 
		"get-npm":
			command => "/usr/local/bin/npm install npm@5.3.0 -g",
			timeout => 1200,
			require => [Exec['get-node']] 
	}
}

class java {
exec {
		"add-sun-java-ppa":
			command => "/usr/bin/add-apt-repository ppa:webupd8team/java"
	}

exec {
		"update-repositories":
		  command => "/usr/bin/apt-get update",
		  require => [Exec['add-sun-java-ppa']],
		  timeout => 1200,
		  user => root
	}

	exec { 
		"accept-java-license-1":
	         command => "/bin/echo debconf shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections > /var/tmp/accept-java-license-1", 
		  path =>"/bin:/usr/bin",
	   	  require => Exec['aptGetUpdate'],
		  creates => "/var/tmp/accept-java-license-1"
	}
	
	exec { 
		"accept-java-license-2":
	         command => "/bin/echo debconf shared/accepted-oracle-license-v1-1 seen true | /usr/bin/debconf-set-selections > /var/tmp/accept-java-license-2", 
		  path =>"/bin:/usr/bin",
	   	  require => Exec['accept-java-license-1'],
		  creates => "/var/tmp/accept-java-license-2"
	}

	package { 
		"oracle-java8-installer":
		  ensure => latest,
		  require => [Exec['accept-java-license-2']] 
	}

	package { 
		"oracle-java8-set-default":
		  ensure => latest,
		  require => [Package['oracle-java8-installer']] 
	}

	package { 
		"java-common":
		  ensure => latest
	}

	package { 
		"unixodbc":
		  ensure => latest
	}  
}

class emacs {
	exec {
		"add-emacs-ppa":
			command => "/usr/bin/add-apt-repository ppa:ubuntu-elisp/ppa"
	}
	exec { "system-packages-update":
		command => "/usr/bin/apt-get update",
		require => Exec["add-emacs-ppa"]
	}
	package { 
		"emacs-snapshot":
			ensure => latest,
			require => Exec['system-packages-update'],
	} 
  exec { 'spacemacs':
  command => '/usr/bin/git clone https://github.com/syl20bnr/spacemacs /home/developer/.emacs.d',
  creates => '/home/developer/.emacs.d',
  user => developer,
  require => Package['emacs-snapshot', 'git'] 

  }
}

 class idea {
  file { 
    "/home/developer/tools":
			ensure => directory,
      owner => developer,
      mode => '0750' 
	}

	exec { "get-idea":
		command => "/usr/bin/wget https://download.jetbrains.com/idea/ideaIC-2017.2.tar.gz -O $homedir/tools/idea.tar.gz",
		creates => "/home/developer/tools/idea.tar.gz",
    timeout => 1200,
    user => developer,
    require => File['/home/developer/tools']
	}

  exec { "extract-idea":	
		command => "/bin/tar -xzf $homedir/tools/idea.tar.gz -C $homedir/tools",
		require => Exec['get-idea'],
		creates => "/home/developer/tools/idea-IC-172.3317.76",
    user => developer
	}

	exec { "append-idea-to-path":
				  command => "/bin/echo 'PATH=\$PATH:$homedir/tools/idea-IC-172.3317.76/bin' >> $homedir/.bashrc",
		      unless => "/bin/grep -qe 'idea-IC-172.3317.76/bin' -- $homedir/.bashrc",
					user => root,
          require => Exec['extract-idea']
  }
}

 class gradle {
	exec { "get-gradle":
		command => "/usr/bin/wget https://services.gradle.org/distributions/gradle-4.0.1-bin.zip  -O $homedir/tools/gradle.zip",
		creates => "/home/developer/tools/gradle.zip",
    timeout => 1200,
    user => developer,
    require => File['/home/developer/tools']
	}

  exec { "extract-gradle":	
		command => "/usr/bin/unzip -d  $homedir/tools $homedir/tools/gradle.zip ",
		require => Exec['get-gradle'],
		creates => "/home/developer/tools/gradle-4.0.1",
    user => developer
	}

	exec { "append-gradle-to-path":
				  command => "/bin/echo 'PATH=\$PATH:$homedir/tools/gradle-4.0.1/bin' >> $homedir/.bashrc",
		      unless => "/bin/grep -qe 'gradle-4.0.1/bin' -- $homedir/.bashrc",
					user => root,
          require => Exec['extract-gradle']
  }
}

 class scm {
  exec { 'get-scm-breeze':
    command => '/usr/bin/git clone https://github.com/ndbroadbent/scm_breeze.git /home/developer/.scm_breeze',
    user => developer,
    creates => '/home/developer/.scm_breeze',
    require => Package['git'] 
  }

	exec { "install-scm-breeze":
    command => "/bin/bash $homedir/.scm_breeze/install.sh",
    require => Exec["get-scm-breeze"],
    creates => "/home/developer/.scmbrc"
  }
}

 class ssh {
  exec { 'copy-ssh':
    command => '/bin/cp -r /vagrant/.ssh /home/developer/.ssh',
    user => developer,
    creates => '/home/developer/.ssh/id_rsa.pub'
  }
  
  exec { 'add-ssh':
    command => '/usr/bin/ssh-add $homedir/.ssh/id_rsa',
    user => developer
  }
}

class pcf {
      exec {
      "get-pcf":
      command => "/usr/bin/curl -o $homedir/tools/cf.deb -L https://cli.run.pivotal.io/stable?release=debian64&source=github",
      creates => "/home/developer/tools/cf.deb",
      user => developer
      }

exec {
     "install-pcf":
     command => "/usr/bin/dpkg -i $homedir/tools/cf.deb",
     require => Exec['get-pcf'],
     creates => '/usr/bin/cf'
     }
}

class chrome {
	exec {
		"add-chrome-ppa":
			command => "/usr/bin/wget -q https://dl-ssl.google.com/linux/linux_signing_key.pub -O $homedir/tools/chrome.pub",
      user => developer,
      creates => '/home/developer/tools/chrome.pub'
	}

	exec {
		"add-chrome-key":
			command => "/usr/bin/apt-key add $homedir/tools/chrome.pub",
      require => Exec['add-chrome-ppa']
	}

	exec {
		"add-chrome-source-list":
			command => "/bin/echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' >> /etc/apt/sources.list.d/google-chrome.list",
      creates => '/etc/apt/sources.list.d/google-chrome.list', 
      require => Exec['add-chrome-key']
	}

	exec {
  "chrome-system-packages-update":
    command => "/usr/bin/apt-get update",
		require => Exec["add-chrome-source-list"]
	}

	package {
		"google-chrome-stable":
			ensure => latest,
			require => Exec['chrome-system-packages-update']
	} 
}

class user {
	exec {
		"add-developer-user":
			command => "/usr/sbin/useradd developer -m -p elask0++ -g sudo",
      creates => '/home/developer'
	}
}

class tmux {
	package {
		"tmux":
			ensure => latest,
        require => Exec["aptGetUpdate"]
	} 
}

class docker {
      exec { "allow-apt-get-https":
      command => "/usr/bin/apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl software-properties-common libappindicator1",
      require => Exec["aptGetUpdate"]
}
  exec { "add-docker-gpg":
  command => "/usr/bin/curl -fsSL https://apt.dockerproject.org/gpg | /usr/bin/apt-key add -",
  require => Exec["allow-apt-get-https"]
}

exec { "add-docker-repo":
     command => "/usr/bin/add-apt-repository \"deb https://apt.dockerproject.org/repo/ ubuntu-$(lsb_release -cs) main\"",
     require => Exec["add-docker-gpg"]
}

exec { "docker-system-packages-update":
     command => "/usr/bin/apt-get update",
     require => Exec["add-docker-repo"]
     }
     
     exec { "get-docker-compose":
     command => '/usr/bin/curl -L "https://github.com/docker/compose/releases/download/1.11.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose',
     require => Exec["allow-apt-get-https"]
        }

  
	file { '/usr/local/bin/docker-compose':
  ensure => present,
  owner => developer,
  mode => '0755',
  require => Exec["get-docker-compose"]
  }
	package { 
		"docker-engine":
			ensure => latest,
			require => Exec['docker-system-packages-update'],
	}

exec { "add-docker-user-group":
command => "/usr/sbin/groupadd docker -f",
require => Package["docker-engine"]
}

exec { "unsudo-docker":
command => "/usr/sbin/gpasswd -a developer docker && /usr/bin/newgrp docker",
require => Exec["add-docker-user-group"]
}
}

$homedir = "/home/developer"

include apt_update
include tmux
include docker
include othertools
include nodejs
include java
include emacs
include idea
include gradle
include scm
include ssh
include pcf
include chrome