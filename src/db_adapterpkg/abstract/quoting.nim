import typeinfo
import nre
import strutils

proc quote_string(s:string): string = 
    s.replace(re"\\", r"\&\&").replace(re"'", "''") # ' (for ruby-mode)

proc quoted_true:string = "TRUE"

proc quoted_false:string = "FALSE"
    

proc unquoted_true:bool = true
proc unquoted_false:bool = false

proc type_quote(value:Any): string =
    case value.kind
        of akString,akCString:
            result = "'$1'" % quote_string($value)
        of akBool:
            let v = value.getBool
            if v:
                result = quoted_true()
            else:
                result = quoted_false()
        of akPointer:
            if isNil(value):
                result = "NULL"
        else:
            raise newException(ValueError,"can't quote $1" % $value)
#     when true       then quoted_true
#     when false      then quoted_false
#     when nil        then "NULL"
#     # BigDecimals need to be put in a non-normalized form and quoted.
#     when BigDecimal then value.to_s("F")
#     when Numeric, ActiveSupport::Duration then value.to_s
#     when Type::Binary::Data then quoted_binary(value)
#     when Type::Time::Value then "'#{quoted_time(value)}'"
#     when Date, Time then "'#{quoted_date(value)}'"
#     when Class      then "'#{value}'"
#     else raise TypeError, "can't quote #{value.class.name}"
#     end
#   end

proc quote*(value:string):string = 
    # value = id_value_for_database(value) if value.is_a?(Base)

    # if value.respond_to?(:value_for_database)
    #   value = value.value_for_database
    # end
    var x = value
    type_quote(x.toAny)

# Quotes the column name. Defaults to no quoting.
proc quote_column_name*(column_name:string):string =
    column_name


# Quotes the table name. Defaults to column name quoting.
proc quote_table_name*(table_name:string) :string =
    quote_column_name(table_name)
