# encoding: utf-8

require "codemodels"
require "codemodels/html"
require "codemodels/js"
require 'htmlentities'
require 'liquid'

module CrossLanguageSpotter

def _language_from_filename(filename)
    if filename.end_with?('.html')
        'html'
    else
        'javascript'
    end
end

def generate_report_file(relations,output)
    files_content = Hash.new{|h,k| h[k]=File.readlines(k)}
    template = Liquid::Template.parse(File.read('./resources/template.html'))

    data = []
    relations.each do |rel|
        entry = {}
        entry['filenameA'] = rel[:node_a_file]
        entry['languageA'] = _language_from_filename(entry['filenameA'])
        entry['srcfileA']  = _code(files_content,rel[:node_a_file],
                rel[:node_a_begin_line]-1,rel[:node_a_end_line]-1,
                rel[:node_a_begin_column],rel[:node_a_end_column])
        entry['filenameB'] = rel[:node_b_file]
        entry['languageB'] = _language_from_filename(entry['filenameB'])
        entry['srcfileB']  = _code(files_content,rel[:node_b_file],
                rel[:node_b_begin_line]-1,rel[:node_b_end_line]-1,
                rel[:node_b_begin_column],rel[:node_b_end_column])        
        data << entry
    end

    File.open(output, 'w') {|f| f.write(template.render({"relations"=>data})) }
end

def _code(files_content,filename,begin_line,end_line,begin_col,end_col)
    code = ""
    snippet_lines = _get_snippet_lines(files_content[filename],begin_line)
    snippet_lines[:before].each do |l|
        code += HTMLEntities.new.encode(l,:decimal)
    end
    snippet_lines[:lines].each do |l|
        code += HTMLEntities.new.encode(l[0...(begin_col-1)],:decimal)
        code += '<span style="background-color:yellow;padding:2px">'+HTMLEntities.new.encode(l[(begin_col-1)...end_col],:decimal)+"</span>"
        code += HTMLEntities.new.encode(l[end_col..-1],:decimal)
    end
    snippet_lines[:after].each do |l|
        code += HTMLEntities.new.encode(l,:decimal)
    end
    code = _remove_extra_spaces(code)
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

def _number_of_spaces(s)
    return 0 unless s.start_with?(' ')
    1+_number_of_spaces(s[1..-1])
end

def _remove_extra_spaces(code,newline="&#10;")
    lines = code.split(newline)
    spaces = []
    lines.each do |l|
        spaces << _number_of_spaces(l)
    end
    extra_spaces = spaces.min
    lines.each_with_index {|l,i| lines[i] = l[extra_spaces..-1]}    
    lines.join(newline)
end

end