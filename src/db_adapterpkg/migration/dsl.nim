import allographer/schema_builder/[alter, table, column]
import macros except body

macro removeColumn*(tbl: untyped, name: typed) =
  result = nnkStmtList.newTree
  var cols = nnkBracket.newTree()
  cols.add nnkCall.newTree(
    newIdentNode("delete"),
    newStrLitNode(macros.strVal(name))
  )
  var alterCall = nnkCall.newTree(ident("alter"))
  var tableCall = nnkCall.newTree(ident("table"), newStrLitNode(macros.strVal(tbl)))
  tableCall.add cols
  alterCall.add tableCall
  result.add alterCall

macro addColumn*(tbl, name, typ: untyped,args:varargs[untyped]) =
  result = nnkStmtList.newTree
  var cols = nnkBracket.newTree()
  var addCall = nnkCall.newTree(
            nnkDotExpr.newTree(
              nnkCall.newTree(
                newIdentNode("add")
        ),
        typ
      ),
    newStrLitNode(macros.strVal(name))
    )
  for arg in args:
    if arg.kind == nnkIdent:
      addCall = nnkCall.newTree(nnkDotExpr.newTree(
            addCall,
            arg
          )
      )
    elif arg.kind == nnkExprEqExpr:
      addCall = nnkCall.newTree(
        nnkDotExpr.newTree(
            addCall,
            arg[0]
          ),
          arg[1]
      )

  cols.add addCall
  var alterCall = nnkCall.newTree(ident("alter"))
  var tableCall = nnkCall.newTree(ident("table"), newStrLitNode(macros.strVal(tbl)))
  tableCall.add cols
  alterCall.add tableCall
  result.add alterCall

# change do:
when isMainModule:
  # dumpAstGen:
  #   add().string(name).unique().default("")
  addColumn posts, title, string ,unique,default = ""#,null = false
  addColumn posts, body, text
  addColumn posts, published, boolean
  removeColumn posts, "name"
