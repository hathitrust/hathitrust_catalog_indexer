# Not really a translation map; just a proc to 
# strip off leading/trailing spaces and any trailing
# punctuation

{
 :maptype=>:multi,
 :mapname=>"strip",
 :map => [
   [/^\s*(.+?)[.,<>;:_\/&^!~`[:space:]]*$/, Proc.new {|m| m[1]}],
 ]

}
