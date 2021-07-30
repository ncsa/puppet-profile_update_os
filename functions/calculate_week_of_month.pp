# See https://puppet.com/docs/puppet/latest/lang_write_functions_in_puppet.html
# for more information on native puppet functions.
function profile_update_os::calculate_week_of_month(String $hostname) >> String {

  case $hostname {
    /[159]$/:      { '1' }
    /[0-9][aei]$/: { '1' }
    /\-aei]$/: { '1' }
    /[26]$/:       { '2' }
    /[0-9][bfj]$/: { '2' }
    /\-[bfj]$/: { '2' }
    /[37]$/:       { '3' }
    /[0-9][cgk]$/: { '3' }
    /\-[cgk]$/: { '3' }
    /[048]$/:      { '4' }
    /[0-9][dhl]$/: { '4' }
    /\-[dhl]$/: { '4' }
    default:       { 'any' }
  }

}
