def tabcol_to_plaincol(line,tabcol)
	c   = 0
	i   = 0
	while c<tabcol
		c+=((line[i]=="\t") ? 4 : 1)
		i+=1
	end
	raise "error" unless c==tabcol
	i
end

		