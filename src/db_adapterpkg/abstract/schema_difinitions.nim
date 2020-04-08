import tables
type PrimaryKeyDefinition = object
    name:string

type PrimaryKeyDefinitionRef = ref PrimaryKeyDefinition
type TableDefinitionOptions = object of RootObj
    primary_key:bool
    null: bool

type
  TableDefinitionRef* = ref TableDefinition
  TableDefinition* = object of RootObj
    name*:string
    temporary*:bool
    if_not_exists*:bool
    options*:TableDefinitionOptions
    #    :as, schema_definitions.rb line:279 
    comment*:string 
    indexes*:seq[tuple[name: string, options: TableDefinitionOptions]]
    foreign_keys*:seq[tuple[name: string, options: TableDefinitionOptions]]
    primary_keys:PrimaryKeyDefinitionRef
    columns_hash:Table[string,TableDefinitionOptions]


proc  newTableDefinitionRef*(conn,name:string,temporary=false,if_not_exists=false,options:TableDefinitionOptions,comment:string) :TableDefinitionRef=
    result = new TableDefinitionRef
    # result.conn = conn
    # result.columns_hash
    result.indexes = newSeq[tuple[name: string, options: TableDefinitionOptions]]()
    result.foreign_keys = newSeq[tuple[name: string, options: TableDefinitionOptions]]()
    # result.primary_keys
    result.temporary = temporary
    result.if_not_exists = if_not_exists
    result.options = options
    result.name = name
    result.comment = comment

proc primary_keys*(self:TableDefinitionRef,name:string="") : PrimaryKeyDefinitionRef = 
    if len(name) > 0 : 
     self.primary_keys =  PrimaryKeyDefinitionRef(name:name) 
    result = self.primary_keys

# def columns; @columns_hash.values; end

proc `[]`*(self:TableDefinitionRef,name:string) : TableDefinitionOptions =
    self.columns_hash[name]

proc index*(self:TableDefinitionRef,column_name:string,options:TableDefinitionOptions) = 
     self.indexes.add( (column_name,options) )

proc foreign_key*(self:TableDefinitionRef,table_name:string,options:TableDefinitionOptions)=
    self.foreign_keys.add( (table_name,options) )

# proc timestamps*(self:TableDefinitionRef,options:TableDefinitionOptions) =
    # let isNull = if options.null ? 
    # column("created_at","datetime",options)