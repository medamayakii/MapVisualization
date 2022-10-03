using PlotlyJS, PyPlotly
using DataFrames, CSV
using GeoDataFrames, ArchGDAL
using PyCall
using Graphs, SciPy
using GraphPlot


function line_plot(dataframe)
    cplotly = ["#636EFA", "#EF553B", "#00CC96", "#AB63FA", "#FFA15A", "#19D3F3", "#FF6692", "#B6E880", "#FF97FF", "#FECB52"]
    layout = Layout(mapbox=attr(zoom=6, center=attr(lat=34.7, lon=135.45), style="carto-darkmatter"),
        title=attr(text="$OBJECTIF", font=attr(size=28)),
        showlegend=true,
        legend=attr(title=attr(text="GROUPS",
                side="top",
                font=attr(size=16)),
            itemsizing="constant",
            itemclick="toggle"),
        legendgrouptitle=attr(text="1"),
        margin=attr(t=60, b=0, r=150, l=0),
        width=1280,
        height=720,
        autotypenumbers="strict",
        modebar=attr(add=["v1hovermode", "hoverclosest", "hovercompare", "togglehover", "togglespikelines", "drawline", "drawopenpath", "drawclosedpath", "drawcircle", "drawrect", "eraseshape"]),
        clickmode="event+select"
    )

    fig = scattermapbox(dataframe;
        name=:name,
        lat=:lat,
        lon=:lon,
        text=:name,
        hoverinfo="all",
        legendgroup=:name,
        visible="true",
        mode="markers+text",
        meta=:name,
        marker=attr(color=cplotly[1], size=3),
        line=attr(color=cplotly[1]),
        customdata=:name,
        uirevision=:name
    )
    plot(fig, layout)
end

function load_master(path)
    return GeoDataFrames.read(path)
end

function convert2laton(df, ordered_idx)
    lat = []
    lon = []
    name = []
    group = []
    type = []

    for index in eachindex(ordered_idx)
        for i in ordered_idx[index] #1:size(df)[1]
            lats = Float64[]
            lons = Float64[]
            names = String[]
            groups = String[]
            types = String[]
            n_points = ArchGDAL.ngeom(df[!, :geometry][i])
            for j in 0:n_points-1
                push!(lons, ArchGDAL.getx(df[!, :geometry][i], j))
                push!(lats, ArchGDAL.gety(df[!, :geometry][i], j))
                push!(names, df[!, :name][i])
                push!(types, df[!, :highway][i])
                # push!(groups, df[!, :name][i] * "$(g2[i])")
                push!(groups, df[!, :name][i] * "$(i)")
            end
            push!(lat, lats)
            push!(lon, lons)
            push!(name, names)
            push!(group, groups)
            push!(type, types)
        end
    end

    df = DataFrame("lon" => vcat(lon...), "lat" => vcat(lat...), "group" => vcat(group...), "type" => vcat(type...), "name" => vcat(name...))
    return df
end

function make_2df(df_master, objectif, mode)
    df = df_master[df_master.name.!=nothing, :]
    df = df[!, [:name, :highway, :geometry]]
    # df = df[df.highway.=="motorway", :]
    sort!(df, :name)

    if mode == "start"
        df = df[startswith.(df.name, objectif), :]
    elseif mode == "end"
        df = df[endswith.(df.name, objectif), :]
    elseif mode == "contain"
        df = df[occursin.(objectif, df.name), :]
    else
        error("Mode shoule be start, end, or contain.")
    end

    # df |> CSV.write("data/aaa.csv")
    # df2 = convert2laton(df)
    return df #, df2
end

function order(dft)
    g = Array{Bool}(undef, (length(dft.geometry), length(dft.geometry)))
    #  g .= (ArchGDAL.touches(dft.geometry[i], dft.geometry[j]) for i in 1:length(dft.geometry), j in 1:length(dft.geometry))
    for i in eachindex(dft.geometry)
        for j in i:length(dft.geometry)
            g[i, j] = ArchGDAL.touches(dft.geometry[i], dft.geometry[j])
            g[j, i] = g[i, j]
        end
    end

    g2 = connected_components(SimpleGraph(g))
    g3 = Graphs.SimpleGraphs.adj(SimpleGraph(g))
    ordered = Vector{Int}[]

    for group_no in eachindex(g2) # 1:gg[1]
        idx = g2[group_no]

        a = Int[]
        temp = idx[1]
        push!(a, temp)
        for i in eachindex(idx)
            # temp = g4[idx[temp]]
            if i == 1
                length(g2[group_no]) != 1 && (temp = g3[idx[i]][1])
            end

            pushfirst!(a, temp...)
            temp = [i for i in vcat(g3[temp]...) if i ∉ a]
            isempty(temp) && break

            # println(i, " ", j, " $(temp)")
        end
        for i in eachindex(idx)
            if i == 1
                (length(g3[idx[i]]) > 1 && length(g2[group_no]) != 1) ? (temp = g3[idx[i]][2]) : break
            end

            a = vcat(a, temp...)
            temp = [i for i in vcat(g3[temp]...) if i ∉ a]
            isempty(temp) && break
        end
        push!(ordered, a)
    end
    return ordered
end

PATH = "data/japan-motorway.json"
df_master = load_master(PATH)
OBJECTIF = "東名"

df_tmp = make_2df(df_master, OBJECTIF, "contain")
ordered_index = @time order(df_tmp)
# df = convert2laton(df_tmp, ordered_index)
# line_plot(df)


begin
    df = convert2laton(df_tmp, ordered_index)

    fig = px.line_mapbox(
        lat=df.lat,
        lon=df.lon,
        color=df.name,
        line_group=df.group,
        mapbox_style="carto-darkmatter",
        template="ggplot2",
        zoom=7,
        width=1280,
        height=720,
        title="<b>$OBJECTIF"
    )
    fig.update_layout(margin_b=0, margin_l=0, margin_r=150, margin_t=60, title_font_size=24)
    # fig.show()
    fig.write_html("sample/test_jupy.html")
end



# a = df_tmp.geometry[1]
# a = ArchGDAL.createlinestring()
# b = ArchGDAL.createmultilinestring()
# ArchGDAL.getgeomtype(a)
# ArchGDAL.getgeomtype(b)

# for i in df_tmp.geometry
#     if Int(ArchGDAL.getgeomtype(i)) == 2
#         print("line")
#     elseif Int(ArchGDAL.getgeomtype(i)) == 5
#         println("multiline")
#     end
# end

