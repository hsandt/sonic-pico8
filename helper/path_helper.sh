# make sure paths passed are not absolute or backward relative to avoid deletion of upper paths
function is_unsafe_path {
  [[ $1 == /* ]] || [[ $1 == .. ]] || [[ $1 == ../* ]] || [[ $1 == */.. ]] || [[ $1 == */../* ]]
}
