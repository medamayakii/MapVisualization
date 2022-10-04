#-------------------------new-method--------------------------#
begin
    dataframe = df_motorway
    g = Array{Bool}(undef, (length(dataframe.geometry), length(dataframe.geometry)))
    for i in eachindex(dataframe.geometry)
        for j in i:length(dataframe.geometry)
            g[i, j] = ArchGDAL.touches(dataframe.geometry[i], dataframe.geometry[j])
            g[j, i] = g[i, j]
        end
    end
    g2 = connected_components(SimpleGraph(g))       # グループのインデックス
    g3 = Set.(Graphs.SimpleGraphs.adj(SimpleGraph(g)))    # 隣接リスト
    ordered = Vector{Int}[]
    group_no = 2
    # for group_no in eachindex(g2)
    idx = g2[group_no]

    slist = Set(idx)
    srted_index_list = Int[]
    dir = 1 # 1:forward(pushfirst), -1:backword(push)
    previous = present = idx[begin]

    push!(srted_index_list, present)
end
#-------------------initialiser-end--------------------#
#----------------------loop---srart--------------------#
# present = pop!(g3[present])
# isempty(g3[previous]) && pop!(slist, previous)
# dir == 1 ? pushfirst!(srted_index_list, present) : push!(srted_index_list, present)
# pop!(g3[present], previous)
# isempty(g3[present]) && pop!(slist, previous)
# previous = present

@time while ~isempty(slist)
    # begin
    present = pop!(g3[present])
    isempty(g3[previous]) && pop!(slist, previous)
    dir == 1 ? pushfirst!(srted_index_list, present) : push!(srted_index_list, present)
    pop!(g3[present], previous)
    isempty(g3[present]) && begin
        pop!(slist, present)
        if srted_index_list[end] in slist
            previous = present = srted_index_list[end]
            dir = -1
            continue
        elseif ~isempty(slist)
            push!(ordered, srted_index_list)
            srted_index_list = Int[]
            previous = present = pop!(slist)
            push!(slist, present)
            continue
        end
    end
    previous = present
end
push!(ordered, srted_index_list)

isempty(g3[present])
srted_index_list
g3[present]
g3[previous]
slist
previous, present
ordered

for i in tuple.(idx, g3[idx])
    println(i)
end


function order2(dataframe)
    #-------------------initialiser-start------------------#
    g = Array{Bool}(undef, (length(dataframe.geometry), length(dataframe.geometry)))
    for i in eachindex(dataframe.geometry)
        for j in i:length(dataframe.geometry)
            g[i, j] = ArchGDAL.touches(dataframe.geometry[i], dataframe.geometry[j])
            g[j, i] = g[i, j]
        end
    end
    g2 = connected_components(SimpleGraph(g))       # グループのインデックス
    g3 = Set.(Graphs.SimpleGraphs.adj(SimpleGraph(g)))    # 隣接リスト

    ordered = Vector{Int}[]
    # group_no = 2
    for group_no in eachindex(g2)
        idx = g2[group_no]

        slist = Set(idx)
        srted_index_list = Int[]
        dir = 1 # 1:forward(pushfirst), -1:backword(push)
        previous = present = idx[begin]

        push!(srted_index_list, present)
        #-------------------initialiser-end--------------------#
        #---------------------loop----srart--------------------#
        while ~isempty(slist)
            # begin
            ~isempty(g3[present]) ? present = pop!(g3[present]) : break
            isempty(g3[previous]) && pop!(slist, previous)
            dir == 1 ? pushfirst!(srted_index_list, present) : push!(srted_index_list, present)
            pop!(g3[present], previous)
            isempty(g3[present]) && begin
                pop!(slist, present)
                if srted_index_list[end] in slist
                    previous = present = srted_index_list[end]
                    dir = -1
                    continue
                elseif ~isempty(slist)
                    push!(ordered, srted_index_list)
                    srted_index_list = Int[]
                    previous = present = pop!(slist)
                    push!(slist, present)
                    continue
                end
            end
            previous = present
        end
        #-------------------loop----end--------------------#
        push!(ordered, srted_index_list)
    end
    return ordered
end

test = @time order2(df_motorway)
test = @time order(df_motorway)
test