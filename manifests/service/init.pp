# == Define: logstash_legacy::service::init
#
# This class exists to coordinate all service management related actions,
# functionality and logical units in a central place.
#
# <b>Note:</b> "service" is the Puppet term and type for background processes
# in general and is used in a platform-independent way. E.g. "service" means
# "daemon" in relation to Unix-like systems.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
define logstash_legacy::service::init{

  #### Service management

  # set params: in operation
  if $logstash_legacy::ensure == 'present' {

    case $logstash_legacy::status {
      # make sure service is currently running, start it on boot
      'enabled': {
        $service_ensure = 'running'
        $service_enable = true
      }
      # make sure service is currently stopped, do not start it on boot
      'disabled': {
        $service_ensure = 'stopped'
        $service_enable = false
      }
      # make sure service is currently running, do not start it on boot
      'running': {
        $service_ensure = 'running'
        $service_enable = false
      }
      # do not start service on boot, do not care whether currently running
      # or not
      'unmanaged': {
        $service_ensure = undef
        $service_enable = false
      }
      # unknown status
      # note: don't forget to update the parameter check in init.pp if you
      #       add a new or change an existing status.
      default: {
        fail("\"${logstash_legacy::status}\" is an unknown service status value")
      }
    }

  # set params: removal
  } else {

    # make sure the service is stopped and disabled (the removal itself will be
    # done by package.pp)
    $service_ensure = 'stopped'
    $service_enable = false

  }

  $notify_service = $logstash_legacy::restart_on_change ? {
    true  => Service[$name],
    false => undef,
  }


  if ( $logstash_legacy::status != 'unmanaged' ) {

    # defaults file content. Either from a hash or file
    if ($logstash_legacy::init_defaults_file != undef) {
      $defaults_content = undef
      $defaults_source  = $logstash_legacy::init_defaults_file
    } elsif ($logstash_legacy::init_defaults != undef and is_hash($logstash_legacy::init_defaults) ) {
      $defaults_content = template("${module_name}/etc/sysconfig/defaults.erb")
      $defaults_source  = undef
    } else {
      $defaults_content = undef
      $defaults_source  = undef
    }

    # Check if we are going to manage the defaults file.
    if ( $defaults_content != undef or $defaults_source != undef ) {

      file { "${logstash_legacy::params::defaults_location}/${name}":
        ensure  => $logstash_legacy::ensure,
        source  => $defaults_source,
        content => $defaults_content,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Service[$name],
        notify  => $notify_service,
      }

    }

    # init file from template
    if ($logstash_legacy::init_template != undef) {

      file { "/etc/init.d/${name}":
        ensure  => $logstash_legacy::ensure,
        content => template($logstash_legacy::init_template),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        before  => Service[$name],
        notify  => $notify_service,
      }

    }

  }

  file { "/etc/init/${name}.conf":
    ensure => 'absent',
    before => Service[$name],
  }

  # Puppet 3 doesn't know that Debian 8 uses systemd, not SysV init,
  # so we'll help it out with our knowledge from the future.
  if($::operatingsystem == 'debian' and $::operatingsystemmajrelease == '8'){
    $service_provider = 'systemd'
  }
  else {
    # In most cases, Puppet can figure out the correct service
    # provider on its own, so we'll just say 'undef', and let it do
    # whatever it thinks is best.
    $service_provider = undef
  }

  service { $name:
    ensure     => $service_ensure,
    enable     => $service_enable,
    name       => $name,
    hasstatus  => $logstash_legacy::params::service_hasstatus,
    hasrestart => $logstash_legacy::params::service_hasrestart,
    pattern    => $logstash_legacy::params::service_pattern,
    provider   => $service_provider,
  }

  # If any files tagged as config files for the service are changed, notify
  # the service so it restarts.
  if $::logstash_legacy::restart_on_change {
    File<| tag == 'logstash_config' |> ~> Service[$name]
    Logstash::Plugin<| |> ~> Service[$name]
  }
}
