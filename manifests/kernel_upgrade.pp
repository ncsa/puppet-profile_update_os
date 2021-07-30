# @summary Apply kernel updates via cron
#
# @param enabled
#   Boolean of whether kernel updates via cron are enabled
#
# @param nowait
#   Boolean of whether to wait before applying kernel updates
#
# @param update_day_of_week
#   Array of strings containing days of week for kernel update cron
#   If not defined days are colculated from hostname
#
# @param update_month
#   Array of strings containing months for kernel update cron
#
# @param update_week_of_month
#   Array of strings containing week of the month for kernel update cron, e.g. "1"-"5"
#   If not defined cron runs every week
#
# @example
#   include profile_update_os::kernel_upgrade
class profile_update_os::kernel_upgrade (
  Boolean       $enabled,
  Boolean       $nowait,
  Array[String] $update_day_of_week,
  Array[String] $update_month,
  Array[String] $update_week_of_month,
) {

  if $enabled {

    if ( ! empty($update_day_of_week) ) {
      $weekday = $update_day_of_week
    }
    else
    {
      $weekday = profile_update_os::calculate_day_of_week($facts['hostname'])
      #case $facts['hostname'] {
      #  /[13579]$/: { $weekday = 'wed'  }
      #  /test$/:    { $weekday = 'odd'  }
      #  default:    { $weekday = 'tue'  }
      #}
    }
    if ( ! empty($update_week_of_month) ) {
      $monthweek = $update_week_of_month
    }
    else
    {
      $monthweek = profile_update_os::calculate_week_of_month($facts['hostname'])
    }

    case $monthweek {
      1, '1':       { $day_of_month = '1-7' }
      2, '2':       { $day_of_month = '8-14' }
      3, '3':       { $day_of_month = '15-21' }
      4, '4':       { $day_of_month = '22-28' }
      5, '5':       { $day_of_month = '29-31' }
      default: { $day_of_month = '*' }
    }

    if $nowait {
      $script_options='-n'
    }
    else
    {
      $script_options=''
    }

    case $weekday {
      #'odd': { $cron_day = [1,3,5] }
      #'even': { $cron_day = [2,4] }
      'tue': {
        $cron_day = '*'
        $weekday_command = "( test \$(date +\\%w) = 2 ) &&"
      }
      'wed': {
        $cron_day = '*'
        $weekday_command = "( test \$(date +\\%w) = 3 ) &&"
      }
      default: {
        $cron_day = '*'
        $weekday_command = "( test \$(date +\\%w) = ${weekday} ) &&"
      }
    }
    if $weekday != false {
      cron { 'kernel_upgrade':
        command  => "( ${weekday_command} /root/scripts/kernel_upgrade.sh ${script_options} )",
        hour     => 6,
        minute   => 0,
        weekday  => $cron_day,
        month    => $update_month,
        monthday => $day_of_month,
        require  => File['/root/scripts/kernel_upgrade.sh'],
      }
    }
  }
  else
  {
    cron { 'kernel_upgrade':
      ensure => absent,
    }

  }

  file { '/root/scripts/kernel_upgrade.sh':
    ensure => 'file',
    source => "puppet:///modules/${module_name}/root/scripts/kernel_upgrade.sh",
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    #require => File['/root/scripts'],
  }
  ## /root/scripts ALREADY DEFINED IN ELSEWHERE?
  #file { '/root/scripts':
  #  ensure => 'directory',
  #  owner  => 'root',
  #  group  => 'root',
  #  mode   => '0700',
  #}

#  cron { 'run_puppet_after_reboot':
#    command => '( /usr/bin/sleep 10s; /opt/puppetlabs/bin/puppet agent -t )',
#    user    => 'root',
#    special => 'reboot',
#    require => Package['puppet'],
#  }

}
