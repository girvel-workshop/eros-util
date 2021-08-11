package = "crater"
version="2.0-16"
source = {
   url = "git://github.com/girvel-workshop/crater",
   tag="2.0-16"
}
description = {
   summary = "none",
   license = "MIT"
}
build = {
   type = "builtin",
   modules = {
      crater = "crater.lua"
   }
}
