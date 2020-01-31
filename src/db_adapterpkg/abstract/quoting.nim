import typeinfo
import regex
import strutils

proc quoteString(s:string): string = 
    s.replace(re"\\", r"\&\&").replace(re"'", "''") # ' (for ruby-mode)

proc quotedTrue:string = "TRUE"

proc quotedFalse:string = "FALSE"
    

proc unquotedTrue:bool = true
proc unquotedFalse:bool = false

proc typeQuote(value:Any): string =
    case value.kind
        of akString:
            result = "'$1'" % quoteString(value.getString)
        of akCString:
            result = "'$1'" % quote_string($value.getCString)
        of akBool:
            let v = value.getBool
            if v:
                result = quotedTrue()
            else:
                result = quotedFalse()
        of akPointer:
            if isNil(value):
                result = "NULL"
        else:
            raise newException(ValueError,"can't quote $1" % $value)
#     when true       then quotedTrue
#     when false      then quotedFalse
#     when nil        then "NULL"
#     # BigDecimals need to be put in a non-normalized form and quoted.
#     when BigDecimal then value.toS("F")
#     when Numeric, ActiveSupport::Duration then value.toS
#     when Type::Binary::Data then quotedBinary(value)
#     when Type::Time::Value then "'#{quotedTime(value)}'"
#     when Date, Time then "'#{quotedDate(value)}'"
#     when Class      then "'#{value}'"
#     else raise TypeError, "can't quote #{value.class.name}"
#     end
#   end

proc quote*(value:string):string = 
    # value = idValueForDatabase(value) if value.isA?(Base)

    # if value.respondTo?(:valueForDatabase)
    #   value = value.valueForDatabase
    # end
    var x = value
    typeQuote(x.toAny)

# Quotes the column name. Defaults to no quoting.
proc quoteColumnName*(columnName:string):string =
    columnName


# Quotes the table name. Defaults to column name quoting.
proc quoteTableName*(tableName:string) :string =
    quoteColumnName(tableName)
