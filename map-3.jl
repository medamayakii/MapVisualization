using PlotlyJS, PyPlotly
using DataFrames, CSV
using GeoDataFrames, ArchGDAL
using Graphs


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
# line_plot(df)

function load_master(path)
    return GeoDataFrames.read(path)
end
const PATH = "data/japan-motorway.json"
df_master = load_master(PATH)

function convert2laton(df, ordered_idx)
    name = df.name[begin]
    lon = []
    lat = []
    group = []
    type = []

    for index in eachindex(ordered_idx)
        for (reverse_check, i) in enumerate(ordered_idx[index]) #1:size(df)[1]
            n_points = ArchGDAL.ngeom(df[!, :geometry][i])

            lons = [ArchGDAL.getx(df[!, :geometry][i], j) for j in 0:n_points-1]
            lats = [ArchGDAL.gety(df[!, :geometry][i], j) for j in 0:n_points-1]
            groups = fill(name * "_$(df.highway[i])_$(index)", n_points) # i or index(better)
            types = fill(df.highway[i], n_points)

            # reverse_check == 1 && println("lon[end][begin], lon[end][end], lon[end-1][begin], lon[end-1][end]")

            reverse_check > 1 && if lons[end] == lon[end][end] # task 1 b==d
                reverse!(lons)
                reverse!(lats)
            elseif lons[end] == lon[end][begin] # task 2 b==c
                reverse!(lons)
                reverse!(lats)
                reverse!(lon[end])
                reverse!(lat[end])
            elseif lons[end] == lon[end][begin] # task 3 a==c
                reverse!(lon[end])
                reverse!(lat[end])
            end

            push!(lon, lons)
            push!(lat, lats)
            push!(group, groups)
            push!(type, types)

            # reverse_check == 1 && println("lon[begin], lon[end], lon[end-1][begin], lon[end-1][end]")
            # reverse_check > 1 && println(lons[begin], "\t", lons[end], "\t", lon[end-1][begin], "\t", lon[end-1][end], "\t", lons[begin] == lon[end-1][end], "\t", lons[end] == lon[end-1][begin], "\t", (lons[begin] == lon[end-1][end]) && (lons[end] != lon[end-1][begin]))
            # reverse_check > 1 && println(lats[begin], "\t", lats[end], "\t", lat[end-1][begin], "\t", lat[end-1][end], "\t", lats[begin] == lat[end-1][end], "\t", lats[end] == lat[end-1][begin], "\t", (lats[begin] == lat[end-1][end]) || (lats[end] == lat[end-1][begin]))
        end
    end

    df = DataFrame("lon" => vcat(lon...), "lat" => vcat(lat...), "group" => vcat(group...), "type" => vcat(type...), "name" => name)
    return df
end

function order_convert(dataframe)
    l = []
    for nom in unique(dataframe, :name).name
        dataframe2 = dataframe[dataframe.name.==nom, :]
        push!(l, convert2laton(dataframe2, order(dataframe2)))
    end
    return vcat(l...)
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

    return df[df.highway.=="motorway", :], df[df.highway.=="motorway_link", :]
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
        println(idx)
        a = Int[]
        temp = idx[1]
        push!(a, temp)
        for i in eachindex(idx)
            # temp = g4[idx[temp]]
            if i == 1
                length(g2[group_no]) != 1 ? (temp = g3[idx[i]][1]) : break
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
    println("\n\n", ordered)
    return ordered
end

begin
    OBJECTIF = "首都"
    df_motorway, df_motorway_link = make_2df(df_master, OBJECTIF, "start")
    df = order_convert(df_motorway)
    ~isempty(df_motorway_link) && (df = vcat(df, order_convert(df_motorway_link)))

    fig = px.line_mapbox(
        lat=df.lat,
        lon=df.lon,
        color=df.name,
        line_group=df.group,
        # mapbox_style="carto-darkmatter",
        mapbox_style="open-street-map",
        template="ggplot2",
        zoom=7,
        width=1280,
        height=720,
        title="<b>$OBJECTIF"
    )
    fig.update_layout(margin=Dict(:b => 0, :l => 0, :r => 150, :t => 60), title_font_size=24)
    fig.write_html("sample/test_jupy.html")
end


# unique(df, :name).name

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

