## map-1.ipnbとほぼ同じ内容をJulia言語で実装

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
    for k in eachindex(mycolors)
        append!(dcolorscale, [[nvals[k], mycolors[k]], [nvals[k+1], mycolors[k]]])
    end

    return dcolorscale
end

url = "https://www.geospatial.jp/ckan/dataset/5afd388d-1e6e-4505-91bc-064391a3157f/resource/bb037b85-9c5e-47ee-9ff0-f5b71bf756b1/download/13tokyo500m.geojson"#"./13tokyo500m.geojson"
#df = GeoDataFrames.read("13tokyo500m.geojson")
df = GeoDataFrames.read(url)
const n_clusters = 6
df.cluster = string.((0:size(df)[1]-1) .% n_clusters)
c = ["#ff0000", "#ffa700", "#afff00", "#08ff00", "#00ff9f", "#00b7ff", "#0010ff", "#9700ff", "#ff00bf", "#ff0000"]
dcolorscale = discrete_colorscale(Vector(0:n_clusters), c[1:n_clusters])

#refer to https://discourse.julialang.org/t/valid-geojson-object-for-choroplethmapbox-trace/72592
#jsondata = JSON.parsefile("13tokyo500m.geojson")

fig = Plot(choroplethmapbox(df, geojson=url,
        featureidkey="properties.code",
        locations=df.code,
        z=df.cluster,
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

