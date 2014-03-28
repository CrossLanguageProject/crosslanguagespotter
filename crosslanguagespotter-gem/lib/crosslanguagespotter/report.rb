# encoding: utf-8

require "codemodels"
require "codemodels/html"
require "codemodels/js"
require 'htmlentities'

module CrossLanguageSpotter

def generate_report_file(relations,output)
    File.open(output, 'w') {|f| f.write(generate_report_code(relations)) }
end

# Generate the HTML code of a report
def generate_report_code(relations,encoding="UTF-8")
    files_content = Hash.new{|h,k| h[k]=File.readlines(k)}
    code = "<html><body>"
    relations.each do |rel|
        code += "<h1>Relation</h1>"
        code += "<h2>End point A</h2>"
        code += _code(files_content,rel[:node_a_file],
                rel[:node_a_begin_line]-1,rel[:node_a_end_line]-1,
                rel[:node_a_begin_column],rel[:node_a_end_column])
        code += "<h2>End point B</h2>"
        code += _code(files_content,rel[:node_b_file],
                rel[:node_b_begin_line]-1,rel[:node_b_end_line]-1,
                rel[:node_b_begin_column],rel[:node_b_end_column])        
    end
    code += "</body></html>"
    code
end 

def _code(files_content,filename,begin_line,end_line,begin_col,end_col)
    code = ""
    snippet_lines = _get_snippet_lines(files_content[filename],begin_line)
    snippet_lines[:before].each do |l|
        code += HTMLEntities.new.encode(l,:decimal)
        code += "<br/>"
    end
    snippet_lines[:lines].each do |l|
        #l = l.gsub("\t",'    ')
        code += HTMLEntities.new.encode(l[0...(begin_col-1)],:decimal)
        code += '<span style="color:red">'+HTMLEntities.new.encode(l[(begin_col-1)...end_col],:decimal)+"</span>"
        code += HTMLEntities.new.encode(l[end_col..-1],:decimal)
        code += "<br/>"
    end
    snippet_lines[:after].each do |l|
        code += HTMLEntities.new.encode(l,:decimal)
        code += "<br/>"
    end
    code
end

def _get_snippet_lines(lines,line_index)   
    around = 5
    start_line = [0,line_index-5].max
    end_line   = [lines.count-1,line_index+5].min
    before = lines[start_line...line_index]
    sel_lines  = [lines[line_index]]
    after  = lines[(line_index+1)..(end_line)]
    {before:before,lines:sel_lines,after:after}
end

end