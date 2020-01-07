
import macros

import strutils, parseutils

type
  Version* = distinct string

proc `$`*(ver: Version): string {.borrow.}

proc newVersion*(ver: string): Version =
  doAssert(ver.len == 0 or ver[0] in {'#', '\0'} + Digits,
           "Wrong version: " & ver)
  return Version(ver)

proc isSpecial(ver: Version): bool =
  return ($ver).len > 0 and ($ver)[0] == '#'

proc isValidVersion(v: string): bool =
  if v.len > 0:
    if v[0] in {'#'} + Digits: return true

converter toBoolean*(ver: Version): bool = ($ver).len > 0

proc `==`*(ver: Version, ver2: Version): bool = $ver == $ver2

proc `<`*(ver: Version, ver2: Version): bool =
  ## This is synced from Nimble's version module.
 
  # Handling for normal versions such as "0.1.0" or "1.0".
  var sVer = string(ver).split('.')
  var sVer2 = string(ver2).split('.')
  for i in 0..<max(sVer.len, sVer2.len):
    var sVerI = 0
    if i < sVer.len:
      discard parseInt(sVer[i], sVerI)
    var sVerI2 = 0
    if i < sVer2.len:
      discard parseInt(sVer2[i], sVerI2)
    if sVerI < sVerI2:
      return true
    elif sVerI == sVerI2:
      discard
    else:
      return false


macro cached_property*(s: string, prc: untyped): untyped =
  if prc.kind notin {nnkProcDef, nnkLambda, nnkMethodDef, nnkDo}:
    error("Cannot transform this node kind into an cached_property proc." &
          " proc/method definition or lambda node expected.")
  let self = prc.params[1][0]
  var outerProcBody = nnkStmtList.newTree(
      nnkIfStmt.newTree(
        nnkElifBranch.newTree(
          nnkDotExpr.newTree(
            self,
            newIdentNode(s.strVal)
    ),
    nnkStmtList.newTree(
      nnkAsgn.newTree(
        newIdentNode("result"),
        nnkDotExpr.newTree(
          self,
          newIdentNode(s.strVal)
      )
    )
    )
  ),
        nnkElse.newTree(
          nnkStmtList.newTree(
            nnkAsgn.newTree(
              nnkDotExpr.newTree(
                self,
                newIdentNode(s.strVal)
    ),
    prc.body
  ),
            nnkAsgn.newTree(
              newIdentNode("result"),
              nnkDotExpr.newTree(
                self,
                newIdentNode(s.strVal)
    )
  )
    )
  )
    )
  )
  result = prc
  result.body = outerProcBody
  return result

proc ndigits*(input: string; intVal: var int; start: int; n: int): int =
  # matches exactly ``n`` digits. Matchers need to return 0 if nothing
  # matched or otherwise the number of processed chars.
  var x = 0
  var i = 0
  while i < n and i+start < input.len and input[i+start] in {'0'..'9'}:
      x = x * 10 + input[i+start].ord - '0'.ord
      inc i
  # only overwrite if we had a match
  if i == n:
      result = n
      intVal = x