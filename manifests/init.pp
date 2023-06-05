# @summary configure functionality for upgrading OS packages
# 
# @param root_cron_scripts_dir
#   Directory where root cron scripts exist
#
# @example
#   include profile_update_os
class profile_update_os (
  String $root_cron_scripts_dir,
) {
  include profile_update_os::kernel_upgrade
  include profile_update_os::scheduled_reboot
  include profile_update_os::yum_upgrade

  # Only include kpatch on Redhat systems (centos/rocky don't seem to publish kpatch-patches)
  case $facts['os']['name'] {
    'Redhat' : {
      include profile_update_os::kpatch
    }
    default  : {} # do nothing
  }

  file { $root_cron_scripts_dir:
    ensure => 'directory',
  }
  file { 'run-if-today.sh':
    ensure => 'file',
    path   => "${root_cron_scripts_dir}/run-if-today.sh",
    source => "puppet:///modules/${module_name}/root/cron_scripts/run-if-today.sh",
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }
}
