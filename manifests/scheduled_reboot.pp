# @summary Reboot node at scheduled time via cron
#
# @param command
#   Command to handle the reboot
#
# @param enabled
#   state of whether reboots via cron are enabled
#
# @param reboot_day_of_week
#   Contains day of week abbreviation for reboot
#   e.g. "Sun", "Mon", "Tue", etc.
#
# @param reboot_hour
#   Hour for cron reboot
#
# @param reboot_minute
#   Minute for reboot
#
# @param reboot_months
#   Names of months (as 3 letter abbreviations) for reboot
#   Empty array implies to run every month
#
# @param reboot_week_of_month
#   Week of the month for reboot, e.g. "1"-"5" or "any"
#   If not defined cron runs every week
#
# @example
#   include profile_update_os::scheduled_reboot
class profile_update_os::scheduled_reboot (
  String        $command,
  Boolean       $enabled,
  String        $reboot_day_of_week,
  Integer       $reboot_hour,
  Integer       $reboot_minute,
  Array[String] $reboot_months,
  String        $reboot_week_of_month,
) {
  if $enabled {
    if empty($reboot_months) {
      $cron_reboot_months = '*'
      $motd_months = 'each month'
    } else {
      $cron_reboot_months = $reboot_months
      $months_3char_abr = $reboot_months.map |$m| { $m[0,3] }
      $motd_months = join( capitalize( $months_3char_abr ), '/' )
    }

    Cron {
      hour    => $reboot_hour,
      minute  => $reboot_minute,
      month   => $cron_reboot_months,
      user    => 'root',
      weekday => '*',
    }

    cron { 'scheduled_reboot':
      command => "( ${profile_update_os::root_cron_scripts_dir}/run-if-today.sh ${reboot_week_of_month} ${reboot_day_of_week} \
&& ${command} )",
    }
    $notice_of_reboot_text = "This server (${facts['networking']['fqdn']}) will be rebooted in"
    cron { '48_hour_notice_of_reboot':
      command => "( ${profile_update_os::root_cron_scripts_dir}/run-if-today.sh ${reboot_week_of_month} ${reboot_day_of_week} 2 \
&& /usr/bin/wall \"${notice_of_reboot_text} 48 hours at $(date -d '+48 hours' +'\\%F \\%R \\%Z').\" )",
    }
    cron { '24_hour_notice_of_reboot':
      command => "( ${profile_update_os::root_cron_scripts_dir}/run-if-today.sh ${reboot_week_of_month} ${reboot_day_of_week} 1 \
&& /usr/bin/wall \"${notice_of_reboot_text} 24 hours at $(date -d '+24 hours' +'\\%F \\%R \\%Z').\" )",
    }
    $reboot_one_hour_earlier = $reboot_hour - 1
    cron { '1_hour_notice_of_reboot':
      command => "( ${profile_update_os::root_cron_scripts_dir}/run-if-today.sh ${reboot_week_of_month} ${reboot_day_of_week} \
&& /usr/bin/wall \"${notice_of_reboot_text} 1 hour at $(date -d '+1 hour' +'\\%F \\%R \\%Z').\" )",
      hour    => $reboot_one_hour_earlier,
    }

    ## UPDATE MOTD
    ## CURRENTLY THIS ONLY DISPLAYS FOR RHEL >=8 SYSTEMS
    case $reboot_week_of_month {
      /1/:  {
        $weeks = 'the 1st'
        $month_prefix = ' of'
      }
      /2/:  {
        $weeks = 'the 2nd'
        $month_prefix = ' of'
      }
      /3/:  {
        $weeks = 'the 3rd'
        $month_prefix = ' of'
      }
      /4/:  {
        $weeks = 'the 4th'
        $month_prefix = ' of'
      }
      /5/:  {
        $weeks = 'the 5th'
        $month_prefix = ' of'
      }
      /any/: {
        $weeks = 'each'
        $month_prefix = ' of'
      }
      default: {
        $weeks = 'unknown'
        $month_prefix = ' of'
      }
    }
    case $reboot_day_of_week {
      /Sun/:  { $day = 'Sunday' }
      /Mon/:  { $day = 'Monday' }
      /Tue/:  { $day = 'Tuesday' }
      /Wed/:  { $day = 'Wednesday' }
      /Thu/:  { $day = 'Thursday' }
      /Fri/:  { $day = 'Friday' }
      /Sat/:  { $day = 'Saturday' }
      default:  { $day = 'unknown' }
    }
    if ( $reboot_hour < 10 ) {
      $hour = "0${reboot_hour}"
    } else {
      $hour = $reboot_hour
    }
    if ( $reboot_minute < 10 ) {
      $minute = "0${reboot_minute}"
    } else {
      $minute = $reboot_minute
    }

    $motdcontent = @("EOF")
      This server (${facts['networking']['hostname']}) reboots ${weeks} ${day}${month_prefix} ${motd_months} at ${hour}:${minute} ${facts['timezone']}.
      | EOF

    ensure_resource( 'file', '/etc/motd.d', { 'ensure' => 'directory', 'mode' => '0755', })

    file { '/etc/motd.d/scheduled_reboot':
      ensure  => file,
      mode    => '0644',
      content => $motdcontent,
    }
  }
  else {
    cron { 'scheduled_reboot':
      ensure => absent,
    }
    cron { '48_hour_notice_of_reboot':
      ensure => absent,
    }
    cron { '24_hour_notice_of_reboot':
      ensure => absent,
    }
    cron { '1_hour_notice_of_reboot':
      ensure => absent,
    }
    file { '/etc/motd.d/scheduled_reboot':
      ensure => absent,
    }
  }
}
