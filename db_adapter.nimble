# Package

version       = "0.1.0"
author        = "bung"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["db_adapter"]



# Dependencies

requires "nim >= 1.2.0" #2916080 
requires "terminaltables"
