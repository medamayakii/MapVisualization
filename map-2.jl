using PlotlyJS
using GeoDataFrames
using JSON

function discrete_colorscale(boundary_vals, mycolors)
    #boundary_vals - vector of values bounding intervals/ranges of interest
    #colors - list of rgb or hex colorcodes for values in [bvals[k], bvals[k+1]],1<=k < length(boundary_vals)
    #returns the plotly  discrete colorscale
    if length(boundary_vals) != length(mycolors) + 1
        error("length of boundary values should be equal to  length(mycolors)+1")
    end
    bvals = sort(boundary_vals)
    nvals = [(v - bvals[1]) / (bvals[end] - bvals[1]) for v in bvals]  #normalized values

    dcolorscale = [] #discrete colorscale
    for k in 1:eachindex(mycolors)
        append!(dcolorscale, [[nvals[k], mycolors[k]], [nvals[k+1], mycolors[k]]])
    end

    return dcolorscale
end

df = GeoDataFrames.read("conbini_tokyo.csv")
const n_clusters = 10
df = df[!, 2:end]

# PlotlyJS(julia)では多分discreteがないのでコンビニの名前を数字に変換
value_map = Dict(i for i in zip(sort(collect(Set(df.idxmax))), Vector(1:n_clusters)))
df.no = [value_map[item] for item in df[:, end]]


hsv = ["#ff0000", "#ffa700", "#afff00", "#08ff00", "#00ff9f", "#00b7ff", "#0010ff", "#9700ff", "#ff00bf", "#ff0000"]
cplotly = ["#636EFA", "#EF553B", "#00CC96", "#AB63FA", "#FFA15A", "#19D3F3", "#FF6692", "#B6E880", "#FF97FF", "#FECB52"]
dcolorscale = discrete_colorscale(Vector(0:n_clusters), cplotly[1:n_clusters])

#refer to https://discourse.julialang.org/t/valid-geojson-object-for-choroplethmapbox-trace/72592
#jsondata = JSON.parsefile("13tokyo1km.geojson")
url = "https://www.geospatial.jp/ckan/dataset/ee0203ee-d526-419c-b894-950b03a1ecd0/resource/9f93ab0c-a157-4408-b492-41c1e036eaac/download/13tokyo1km.geojson"


fig = Plot(choroplethmapbox(df, geojson=url,
        #geojson = jsondata,
        featureidkey="properties.code",
        locations=df.mesh_cd,
        z=df.no,
        text=df.idxmax,
        colorscale=dcolorscale,
        colorbar=attr(title="cluster"),
        height=600,
        width=1000,
        marker=attr(opacity=0.5),
        margin=attr(t=10, b=10, l=20, r=20),
    ),
    Layout(mapbox=attr(center=attr(lat=35.7, lon=139.45),
        zoom=9.1,
        style="open-street-map",
    )))
