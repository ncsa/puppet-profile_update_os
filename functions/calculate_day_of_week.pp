# See https://puppet.com/docs/puppet/latest/lang_write_functions_in_puppet.html
# for more information on native puppet functions.
function profile_update_os::calculate_day_of_week(String $hostname) >> Array {

  case $hostname {
    #/[13579]$/: { [ 'tue' ]  }
    #/[13579][acegi]$/: { [ 'tue' ]  }
    /test$/:    { [ 2, 4 ] }
    /\-test/:    { [ 2, 4 ] }
    default:    { [ 'wed' ]  }
  }

}
