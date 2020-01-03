import ../../common
import regex

# https://github.com/rails/rails/blob/aeba121a83965d242ed6d7fd46e9c166079a3230/activerecord/lib/active_record/connection_adapters/mysql/quoting.rb

proc quote_column_name*(name:string):string =
    name.replace(re"`","``")
    # @quoted_column_names[name] ||= "`#{super.gsub('`', '``')}`"
proc quote_table_name*(name:string):string =
    name.replace(re".","`.`")
    # self.class.quoted_table_names[name] ||= super.gsub(".", "`.`").freeze

proc unquoted_true*():int =  1
    
proc unquoted_false*():int =  0