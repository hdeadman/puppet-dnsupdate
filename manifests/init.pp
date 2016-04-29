# Class: dnsupdate
#
# This module manages PTR, and A records in AD DNS
#
# Parameters: none
#
# Actions: 
# It makes sure bind-utils is installed which has the nsupdate binary.
# It makes a file /etc/nsupdate used for pushing updates and for
# verifying that updates need to be made by queuring DNS first.
# 
# Zones in Active Directory need to allow secure and non-secure updates, 
# make sure you do this for the forward and reverse zones
#
# Requires: stdlib
#
# Sample Usage: include ::dnsupdate
#
class dnsupdate ($ipaddr             = $::ipaddress,
                 $dnsname            = $::fqdn,
                 $manage_bind_utils  = true,
                 $bind_utils_package = 'bind-utils',
                 $debug              = true) {
  
  if $manage_bind_utils { 
    # Package
    package {'bind-tools': 
      ensure => present,
      name   => $bind_utils_package
    }
  }
  
  # -D for $debug gives you more debug than -d
	case $debug {
	  true : {
	    $debug_option = '-d'
	  }
	  false : {
	    $debug_option = ''
	  }
	  default : {
	    $debug_option = $debug
	  }
	}
  
  # Update, dump input for debugging purposes if we are going to run the update, in case it fails
  file { '/etc/nsupdate':
    ensure  => 'present',
    content => template('dnsupdate/nsupdate.erb')
  } ->
  exec { 'cat nsupdate':
    path     => ['/bin', '/usr/bin'],
    command  => 'cat /etc/nsupdate',
    provider => 'shell',
    logoutput=> true,
    unless   => "grep $(nslookup $(hostname -f) |sed -n '/^Name/{n;s/.*: //p}') /etc/nsupdate && grep $(nslookup $(hostname -i)|egrep -o '^[0-9]+.[0-9]+.[0-9]+.[0-9]+') /etc/nsupdate",
  } ->   
  exec { 'nsupdate':
    path     => ['/bin', '/usr/bin'],
    command  => "nsupdate $debug_option /etc/nsupdate",
    provider => 'shell',
    unless   => "grep $(nslookup $(hostname -f) |sed -n '/^Name/{n;s/.*: //p}') /etc/nsupdate && grep $(nslookup $(hostname -i)|egrep -o '^[0-9]+.[0-9]+.[0-9]+.[0-9]+') /etc/nsupdate",
    require  => Package['bind-tools'],
  }
}
