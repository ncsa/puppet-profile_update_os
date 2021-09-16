# @summary Apply yum updates via cron
#
# @param command
#   Command to apply yum updates for the OS version
#
# @param config_file
#   Full path to yum update config file for the OS version
#
# @param enabled
#   State of whether yum updates via cron are enabled
#
# @param excluded_packages
#   List of packages to exclude from yum updates
#
# @param random_delay
#   Maximum number of minutes to randomly wait before applying yum updates
#
# @param package
#   Package name for the yum update package for the OS version
#
# @param service
#   Service name for the yum update service for the OS version
#
# @param update_day_of_week
#   Day of week abbreviation for yum update cron
#   e.g. "Sun", "Mon", "Tue", etc.
#   If not defined day of week is calculated from hostname
#
# @param update_hour
#   Hour for yum update cron
#   There is a random delay of up to 30 minutes before the yum update occurs
#
# @param update_minute
#   Minute for yum update cron
#   There is a random delay of up to 30 minutes before the yum update occurs
#
# @param update_months
#   Names of months (as 3 letter abbreviations) for kernel update cron
#   Empty array implies to run every month
#
# @param update_week_of_month
#   Week of the month for yum update cron, e.g. "1"-"5" or "any"
#   If not defined cron runs every week
#
# @param yum_config_file
#   Full path to yum config file for the OS version
#
# @example
#   include profile_update_os::yum_upgrade
class profile_update_os::yum_upgrade (
  String        $command,
  String        $config_file,
  Boolean       $enabled,
  Array         $excluded_packages,
  String        $package,
  Integer       $random_delay,
  String        $service,
  String        $update_day_of_week,
  Integer       $update_hour,
  Integer       $update_minute,
  Array[String] $update_months,
  String        $update_week_of_month,
  String        $yum_config_file,
) {

  if $enabled
  {

    ensure_packages( $package, {'ensure' => 'present'} )

    File_line {
      ensure   => 'present',
      multiple => 'false',
      require  => Package[$package],
      notify   => Service[$service],
    }

    # PERHAPS SHOULD BE MOVED TO A DIFFERENT PROFILE CLASS
    # IS HERE TO MAKE SURE KERNEL PACKAGE EXCLUDED BY DEFAULT
    if empty($excluded_packages) {
      file_line { 'yum_config_exclude':
        ensure            => 'absent',
        #line              => 'exclude',
        path              => $yum_config_file,
        match             => '^exclude*',
        match_for_absence => true,
      }
    } else {
      $excludes = join($excluded_packages, ' ')
#      include ::yum
#      yum::config { 'exclude': ensure => $excludes, }
      file_line { 'yum_config_exclude':
        path  => $yum_config_file,
        line  => "exclude=${excludes}",
        match => '^exclude*',
      }
    }

    file_line { 'yum_update_config_apply_updates':
      path  => $config_file,
      line  => 'apply_updates = yes',
      match => '^apply_updates*',
    }

    file_line { 'yum_update_config_random_sleep':
      path  => $config_file,
      line  => 'random_sleep = 0',
      match => '^random_sleep*',
    }

    service { $service:
      ensure     => stopped,
      enable     => false,
      hasstatus  => true,
      hasrestart => true,
      require    => Package[$package],
    }

    if empty($update_day_of_week) {
      $day_of_week = profile_update_os::calculate_day_of_week($facts['hostname'])
    } else {
      $day_of_week = $update_day_of_week
    }
    if empty($update_week_of_month) {
      $week_num = profile_update_os::calculate_week_of_month($facts['hostname'])
    } else {
      $week_num = $update_week_of_month
    }

    if empty($update_months) {
      $cron_update_months = '*'
    } else {
      $cron_update_months = $update_months
    }

    # AVOID DIVISION BY 0 ERRORS
    if ( $random_delay < 1 ) {
      $max_wait_time = 1
    } else {
      $max_wait_time = $random_delay
    }
    $wait_command = "sleep \$((RANDOM \\% ${max_wait_time}))m"

    cron { 'yum_upgrade':
      command => "( ${profile_update_os::root_cron_scripts_dir}/run-if-today.sh ${week_num} ${day_of_week} \
&& ${wait_command} && ${command} )",
      hour    => $update_hour,
      minute  => $update_minute,
      month   => $cron_update_months,
      user    => 'root',
    }
    # ENSURE OLD NAME OF CRON NO LONGER EXISTS - CAN BE REMOVED IN FUTURE AFTER SURE CLEANED UP
    cron { 'yum-cron':
      ensure => absent,
    }

  }
  else
  {
    cron { 'yum_upgrade':
      ensure => absent,
    }
  }

}
