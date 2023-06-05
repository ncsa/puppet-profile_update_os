# See https://puppet.com/docs/puppet/latest/lang_write_functions_in_puppet.html
# for more information on native puppet functions.
function profile_update_os::calculate_day_of_week(String $hostname) >> String {
  case $hostname {
    /test$/:  { 'Tue' }
    /\-test/: { 'Tue' }
    default:  { 'Wed' }
  }
}
