using DataFrames
using CSV
using DataFramesMeta
using Dates

data = CSV.read("data/top30data.csv")
size(data)

for i in names(data)[11:19]
    data[i] = convert(Array{Union{Missing, Int64},1},data[i])
end
for i in names(data)[21:29]
    data[i] = convert(Array{Union{Missing, Int64},1},data[i])
end

delete!(data,[:TAXI_OUT,:TAXI_IN,:AIR_TIME])
describe(data)

subsetdata = data[:,[:FL_DATE,:OP_UNIQUE_CARRIER,:TAIL_NUM,:OP_CARRIER_FL_NUM,:ORIGIN,:DEST,:DEP_DELAY,:ARR_DELAY,:CANCELLED,:DIVERTED]];
subsetdata[:DELAY] = subsetdata[:DEP_DELAY] .+ subsetdata[:ARR_DELAY];
delete!(subsetdata,[:DEP_DELAY,:TAIL_NUM,:ARR_DELAY]);

subsetdata = @linq subsetdata |>
                    where(:CANCELLED .== 0, :DIVERTED .== 0);
#describe(subsetdata)
delete!(subsetdata,[:CANCELLED,:DIVERTED]);

airlinelookup = CSV.read("data/lookuptables/L_UNIQUE_CARRIERS.csv_");
head(airlinelookup)

rename!(airlinelookup, :Code => :OP_UNIQUE_CARRIER);
subsetdata = join(subsetdata, airlinelookup, on = :OP_UNIQUE_CARRIER, kind = :left);
delete!(subsetdata,:OP_UNIQUE_CARRIER)
rename!(subsetdata,[:Description=>:Airline,:FL_DATE=>:Date,:OP_CARRIER_FL_NUM=>:Flight,:ORIGIN=>:Origin,:DEST=>:Destination,:DELAY=>:Delay])
head(subsetdata)

using PlotlyJS

airlines = unique(subsetdata[:,:Airline])
describe(subsetdata)

subsetdata = @linq subsetdata |>
                    where(:Date .< Dates.Date(2017,9,16));
size(subsetdata)

function visualize()
    trace = scattergl(
        mode="markers",
        x=subsetdata[:Date],
        y=subsetdata[:Delay],
        text=subsetdata[:Airline],
        marker=attr(size=1, sizemode="area"),
        transforms=[
            attr(type="filter", target=subsetdata[:Origin], operation="=", value="BOS"),
            attr(type="groupby", groups=subsetdata[:Airline])
        ]
    )
    plot([trace], Layout(yaxis_type="log"))
end
visualize()
