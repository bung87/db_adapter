import ../../common
import regex

# https://github.com/rails/rails/blob/aeba121a83965d242ed6d7fd46e9c166079a3230/activerecord/lib/active_record/connectionAdapters/mysql/quoting.rb

proc quoteColumnName*(name:string):string =
    name.replace(re"`","``")
    # @quotedColumnNames[name] ||= "`#{super.gsub('`', '``')}`"
proc quoteTableName*(name:string):string =
    name.replace(re".","`.`")
    # self.class.quotedTableNames[name] ||= super.gsub(".", "`.`").freeze

proc unquotedTrue*():int =  1
    
proc unquotedFalse*():int =  0